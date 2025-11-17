# leotest-ia-service/ia_worker.py

from pydantic import BaseModel
from typing import List, Optional, Dict
import requests
import time
import json
import os 
import logging
from google import genai
from google.genai import types
import io 
import pdfplumber 

# Configuración de Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# URL INTERNA de Node.js para guardar los resultados
INTERNAL_NODE_API_URL = os.environ.get("INTERNAL_NODE_API_URL", "http://localhost:3000/api") 
INTERNAL_SAVE_QUESTIONS_URL = f"{INTERNAL_NODE_API_URL}/ia/save_generated"
INTERNAL_CHAPTER_API_URL = f"{INTERNAL_NODE_API_URL}/libros/internal/chapter"

# --- Inicialización del Cliente Gemini ---
GEMINI_MODEL = 'gemini-2.5-flash'
GEMINI_CLIENT = None 

# --- Modelos de Datos ---

class Option(BaseModel):
    texto_opcion: str
    opcion_correcta: bool

class Pregunta(BaseModel):
    id_capitulo: int 
    nivel_comprension: str  
    enunciado: str
    tipo: str  
    opciones: List[Option]
    
class BookProcessingInput(BaseModel):
    id_libro: int
    ruta_archivo: str 
    total_capitulos: int

# --- Lógica de Inicialización (Llamada desde main.py) ---
def initialize_gemini_client():
    """Inicializa el cliente de Gemini y lo almacena globalmente."""
    global GEMINI_CLIENT
    try:
        # La SDK busca la clave en os.environ['GEMINI_API_KEY']
        GEMINI_CLIENT = genai.Client()
        return GEMINI_CLIENT
    except Exception as e:
        logging.error(f"❌ Fallo al inicializar el cliente Gemini: {e}")
        return None

# --- Lógica Auxiliar de Extracción Dinámica ---

def extract_text_from_pdf_url(pdf_url: str) -> str:
    """
    Descarga el PDF de la URL y extrae todo el texto plano.
    """
    logging.info(f"Iniciando descarga y extracción del PDF desde: {pdf_url}")
    try:
        pdf_response = requests.get(pdf_url)
        pdf_response.raise_for_status() 
        
        pdf_file = io.BytesIO(pdf_response.content)
        
        full_text = ""
        with pdfplumber.open(pdf_file) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if text:
                    full_text += text + "\n\n"
        
        if not full_text.strip():
            raise ValueError("El PDF no contiene texto extraíble.")
            
        logging.info("✅ Extracción de texto del PDF completada.")
        return full_text
        
    except requests.exceptions.RequestException as e:
        logging.error(f"Error de red/HTTP al descargar PDF: {e}")
        raise
    except Exception as e:
        logging.error(f"Error durante la extracción de texto con pdfplumber: {e}")
        raise


def divide_text_into_chapters(full_text: str, num_chapters: int) -> Dict[int, str]:
    """
    Divide el texto plano en el número de capítulos especificado (división por longitud).
    """
    text_length = len(full_text)
    
    if num_chapters <= 0 or text_length == 0:
        return {}
    
    chunk_size = text_length // num_chapters
    chapters_content = {}
    
    for i in range(num_chapters):
        start = i * chunk_size
        end = (i + 1) * chunk_size if i < num_chapters - 1 else text_length
        
        # Asignamos el índice i+1 al número de capítulo
        chapters_content[i + 1] = full_text[start:end].strip()

    return chapters_content


# --- Lógica Funcional de Generación de Preguntas Específicas ---

def generate_questions_from_text(text_fragment: str, id_capitulo: int) -> List[Pregunta]:
    """ Genera preguntas específicas del texto utilizando Gemini. """
    
    if GEMINI_CLIENT is None:
        return []

    # 1. Definición del Esquema JSON
    json_schema = types.Schema(
        type=types.Type.ARRAY,
        items=types.Schema(
            type=types.Type.OBJECT,
            properties={
                "id_capitulo": types.Schema(type=types.Type.INTEGER, description=f"ID del capítulo: {id_capitulo}"),
                "nivel_comprension": types.Schema(type=types.Type.STRING, enum=["literal", "inferencial", "critico"]),
                "enunciado": types.Schema(type=types.Type.STRING),
                "tipo": types.Schema(type=types.Type.STRING, enum=["opcion_multiple"]),
                "opciones": types.Schema(
                    type=types.Type.ARRAY,
                    items=types.Schema(
                        type=types.Type.OBJECT,
                        properties={
                            "texto_opcion": types.Schema(type=types.Type.STRING),
                            "opcion_correcta": types.Schema(type=types.Type.BOOLEAN),
                        },
                        required=["texto_opcion", "opcion_correcta"],
                    )
                )
            },
            required=["id_capitulo", "nivel_comprension", "enunciado", "tipo", "opciones"],
        )
    )

    # 2. Instrucción detallada para el LLM
    prompt = f"""
    Genera exactamente 3 preguntas de opción múltiple basadas ÚNICAMENTE en el TEXTO proporcionado:
    1. Una pregunta LITERAL (hechos directos).
    2. Una pregunta INFERENCIAL (deducción).
    3. Una pregunta CRÍTICA (juicio/opinión sobre el tema).
    Asegúrate de que la respuesta correcta esté marcada con 'opcion_correcta: true' y proporciona dos distractores lógicos.
    El campo 'id_capitulo' debe ser siempre {id_capitulo}.
    
    TEXTO DEL CAPÍTULO A EVALUAR:
    ---
    {text_fragment}
    ---
    """
    
    try:
        response = GEMINI_CLIENT.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=json_schema,
                temperature=0.6 
            ),
        )

        questions_data = json.loads(response.text)
        
        valid_questions: List[Pregunta] = []
        for q_dict in questions_data:
            valid_questions.append(Pregunta.parse_obj(q_dict)) 
                
        return valid_questions

    except Exception as e:
        logging.error(f"Error en la llamada a la API de Gemini: {e}")
        return []


def process_full_book(input_data: BookProcessingInput):
    """ 
    Worker funcional: Flujo asíncrono que maneja la persistencia y la generación de preguntas.
    """
    logging.info(f"Iniciando procesamiento de libro ID: {input_data.id_libro} con {input_data.total_capitulos} capítulos.")
    
    try:
        # 1. PASO DINÁMICO: DESCARGA Y EXTRACCIÓN DEL PDF
        full_text = extract_text_from_pdf_url(input_data.ruta_archivo)
        
        # 2. DIVIDIR EL TEXTO EN FRAGMENTOS DE CAPÍTULOS
        chapters_content = divide_text_into_chapters(full_text, input_data.total_capitulos)
        
        if not chapters_content:
             logging.error("No se pudo dividir el texto en capítulos válidos.")
             return {"success": False, "error": "No hay contenido para procesar."}

        all_questions_generated: List[Pregunta] = []
        
        # 3. BUCLE DE PROCESAMIENTO Y PERSISTENCIA POR CAPÍTULO
        for chapter_num, fragment in chapters_content.items():
            
            chapter_title = f"Capítulo {chapter_num}"
            
            # 3a. INSERTAR CAPÍTULO EN NODE.JS Y OBTENER EL ID_PK
            chapter_payload = {
                "id_libro": input_data.id_libro,
                "numero_capitulo": chapter_num,
                "titulo_capitulo": chapter_title,
                "contenido_texto": fragment # Contenido de texto para capitulo_embedding
            }

            chapter_response = requests.post(
                INTERNAL_CHAPTER_API_URL, 
                headers={"Content-Type": "application/json"},
                data=json.dumps(chapter_payload)
            )

            if chapter_response.status_code != 201:
                logging.error(f"Fallo al insertar Capítulo {chapter_num}. Status: {chapter_response.status_code}. Respuesta: {chapter_response.text}")
                return {"success": False, "error": f"Fallo al crear capítulo en Node.js."}
                
            id_capitulo_pk = chapter_response.json().get("id_capitulo")
            
            if id_capitulo_pk is None:
                logging.error("Node.js no devolvió ID de capítulo.")
                return {"success": False, "error": "Node.js no devolvió ID de capítulo."}

            # 3b. Generación de preguntas (usa el ID_PK real)
            questions = generate_questions_from_text(fragment, id_capitulo_pk) 
            all_questions_generated.extend(questions)
            
            time.sleep(0.5) 
            
        logging.info(f"Total de {len(all_questions_generated)} preguntas generadas en total.")
        
        # 4. GUARDAR RESULTADOS FINALES DE VUELTA EN NODE.JS
        
        save_response = requests.post(
            INTERNAL_SAVE_QUESTIONS_URL,
            headers={"Content-Type": "application/json"},
            data=json.dumps({
                "id_libro": input_data.id_libro,
                "preguntas": [q.dict() for q in all_questions_generated]
            })
        )
        
        if save_response.status_code == 201:
            logging.info(f"✅ Persistencia de preguntas exitosa.")
            return {"success": True}
        else:
            logging.error(f"❌ Error al guardar preguntas en Node.js ({save_response.status_code}): {save_response.text}")
            return {"success": False, "error": f"Fallo al persistir: {save_response.text}"}

    except Exception as e:
        logging.error(f"❌ Error fatal en el worker: {e}", exc_info=True)
        return {"success": False, "error": str(e)}

# NOTA: Debes correr este worker a través de uvicorn main:app --reload --host 0.0.0.0 --port 8000