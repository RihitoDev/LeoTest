# leotest-ia-service/ia_worker.py
from pydantic import BaseModel
from typing import List, Dict
import requests
import time
import json
import os
import logging
import google.generativeai as genai
import io
import pdfplumber
import re

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

INTERNAL_NODE_API_URL = os.environ.get("INTERNAL_NODE_API_URL", "http://localhost:3000/api")
INTERNAL_SAVE_QUESTIONS_URL = f"{INTERNAL_NODE_API_URL}/ia/save_generated"
INTERNAL_CHAPTER_API_URL = f"{INTERNAL_NODE_API_URL}/libros/internal/chapter"
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
GEMINI_CLIENT = None


# -----------------------------
# MODELOS
# -----------------------------
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


# -----------------------------
# GEMINI CLIENT
# -----------------------------
def initialize_gemini_client():
    global GEMINI_CLIENT
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        logging.error("No se encontró GEMINI_API_KEY en variables de entorno")
        return None

    try:
        genai.configure(api_key=api_key)
        # Crear modelo correctamente
        GEMINI_CLIENT = genai.GenerativeModel(GEMINI_MODEL)
        logging.info("✅ Cliente Gemini inicializado correctamente")
        return GEMINI_CLIENT

    except Exception as e:
        logging.error(f"❌ Fallo al inicializar el cliente Gemini: {e}")
        return None


# -----------------------------
# PDF PROCESSING
# -----------------------------
def extract_text_from_pdf_url(pdf_url: str) -> str:
    logging.info(f"Iniciando descarga y extracción del PDF desde: {pdf_url}")
    resp = requests.get(pdf_url, timeout=60)
    resp.raise_for_status()
    pdf_file = io.BytesIO(resp.content)

    full_text = ""
    with pdfplumber.open(pdf_file) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                full_text += text + "\n\n"

    if not full_text.strip():
        raise ValueError("El PDF no contiene texto extraíble.")

    logging.info("✅ Extracción de texto completada.")
    return full_text


# -----------------------------
# CHAPTER SPLIT
# -----------------------------
def simple_split_by_length(full_text: str, num_chapters: int) -> Dict[int, str]:
    text_length = len(full_text)
    if num_chapters <= 0 or text_length == 0:
        return {}

    chunk_size = text_length // num_chapters
    chapters_content = {}

    for i in range(num_chapters):
        start = i * chunk_size
        end = (i + 1) * chunk_size if i < num_chapters - 1 else text_length
        chapters_content[i + 1] = full_text[start:end].strip()

    return chapters_content


def divide_text_into_chapters(full_text: str, num_chapters: int) -> Dict[int, str]:
    # 1. Eliminar sección de ÍNDICE antes de procesar
    full_text = re.sub(r"ÍNDICE(.+?)(I\.\s+)", r"\2", full_text, flags=re.DOTALL | re.IGNORECASE)

    # 2. Patrón más robusto para detectar capítulos REALES
    chapter_pattern = r"(?:^|\n)(?:Cap[ií]tulo\s+\d+|CAP[IÍ]TULO\s+\d+|Cap\.?\s*\d+|[IVXLCDM]+\s*\.\s+[A-ZÁÉÍÓÚÑ].+)"
    
    matches = list(re.finditer(chapter_pattern, full_text, re.MULTILINE))

    if not matches:
        return simple_split_by_length(full_text, num_chapters)

    chapters = {}
    for i in range(len(matches)):
        start = matches[i].start()
        end = matches[i + 1].start() if i < len(matches) - 1 else len(full_text)
        chapters[i + 1] = full_text[start:end].strip()

    return chapters



# -----------------------------
# JSON PARSER HELP
# -----------------------------
def _extract_json_from_text(maybe_text: str):
    try:
        return json.loads(maybe_text)
    except Exception:
        pass

    array_match = re.search(r"(\[.*\])", maybe_text, re.DOTALL)
    if array_match:
        try:
            return json.loads(array_match.group(1))
        except Exception:
            pass

    obj_match = re.search(r"(\{.*\})", maybe_text, re.DOTALL)
    if obj_match:
        try:
            return json.loads(obj_match.group(1))
        except Exception:
            pass

    return None


# -----------------------------
# GEMINI QUESTION GENERATION
# -----------------------------
def _extract_json_from_text(maybe_text: str):
    """
    Extrae el primer array JSON de un texto (respuestas del modelo).
    """
    try:
        return json.loads(maybe_text)
    except Exception:
        pass

    array_match = re.search(r"(\[.*\])", maybe_text, re.DOTALL)
    if array_match:
        try:
            return json.loads(array_match.group(1))
        except Exception as e:
            logging.error(f"Error parseando array JSON: {e}")

    obj_match = re.search(r"(\{.*\})", maybe_text, re.DOTALL)
    if obj_match:
        try:
            return json.loads(obj_match.group(1))
        except Exception as e:
            logging.error(f"Error parseando objeto JSON: {e}")

    logging.error("No se pudo extraer JSON de la respuesta de Gemini")
    return None


def generate_questions_from_text(text_fragment: str, id_capitulo: int) -> List[Pregunta]:
    if GEMINI_CLIENT is None:
        logging.error("Gemini client no inicializado.")
        return []

    if not text_fragment.strip():
        logging.warning(f"Capítulo {id_capitulo} vacío.")
        return []

    prompt = f"""
    RESPONDE SOLO CON UN ARRAY JSON (sin texto adicional).
    Cada elemento debe tener:
    - id_capitulo (integer)
    - nivel_comprension (literal|inferencial|critico)
    - enunciado (string)
    - tipo (opcion_multiple|falso_verdadero)
    - opciones: [{{texto_opcion, opcion_correcta}}]

    Genera exactamente 3 preguntas basadas SOLO en el texto:

    1) Literal: tipo aleatorio (opcion_multiple o falso_verdadero), mínimo 2 opciones
    2) Inferencial: opcion_multiple, mínimo 3 opciones
    3) Crítico: opcion_multiple, mínimo 3 opciones

    id_capitulo = {id_capitulo}

    TEXTO:
    {text_fragment}

    IMPORTANTE:
    - Devuelve solo JSON.
    - Para falso_verdadero, las opciones deben ser "Verdadero" y "Falso".
    """

    try:
        response = GEMINI_CLIENT.generate_content(
            prompt,
            generation_config={"temperature": 0.4},
        )

        # ----------------------------------------------------------
        # 🔥 MANEJO DE BLOQUEO DE GEMINI
        # ----------------------------------------------------------
        if not response.candidates:
            reason = (
                response.prompt_feedback.block_reason
                if response.prompt_feedback else "desconocida"
            )
            logging.error(f"❌ Gemini bloqueó el contenido del capítulo. Razón: {reason}")
            return []   # Nunca intentamos leer response.text

        # Si no está bloqueado, es seguro usar response.text
        raw = response.text or ""

    except Exception as e:
        logging.error(f"Error al llamar Gemini: {e}")
        return []

    logging.info(f"Respuesta cruda Gemini (len {len(raw)}): {raw[:2000]}")

    # ----------------------------------------------------------
    # Extraer el JSON
    # ----------------------------------------------------------
    parsed = _extract_json_from_text(raw)
    if parsed is None:
        logging.error("No JSON extraído de Gemini.")
        return []

    # Puede venir como lista o con clave "questions"
    questions_list = parsed if isinstance(parsed, list) else parsed.get("questions", [])
    valid_questions = []

    # ----------------------------------------------------------
    # Validar y convertir preguntas
    # ----------------------------------------------------------
    for q in questions_list:
        try:
            q["id_capitulo"] = int(id_capitulo)

            # Validar existencia de opciones
            if "opciones" not in q or not isinstance(q["opciones"], list):
                logging.warning("Pregunta sin opciones válidas, se omite.")
                continue

            # Normalizar preguntas de Falso-Verdadero
            if q.get("tipo") == "falso_verdadero":
                q["opciones"] = [
                    {
                        "texto_opcion": "Verdadero",
                        "opcion_correcta": q["opciones"][0].get("opcion_correcta", True)
                    },
                    {
                        "texto_opcion": "Falso",
                        "opcion_correcta": not q["opciones"][0].get("opcion_correcta", True)
                    },
                ]

            # Requerimiento mínimo de opciones
            min_opts = 2 if q.get("nivel_comprension") == "literal" else 3

            if len(q["opciones"]) < min_opts:
                logging.warning(
                    f"Pregunta con menos de {min_opts} opciones, se omite: {q.get('enunciado')}"
                )
                continue

            # Validación con Pydantic
            p = Pregunta.parse_obj({
                "id_capitulo": q["id_capitulo"],
                "nivel_comprension": q.get("nivel_comprension", "literal"),
                "enunciado": q["enunciado"],
                "tipo": q.get("tipo", "opcion_multiple"),
                "opciones": q["opciones"],
            })

            valid_questions.append(p)

        except Exception as e:
            logging.error(f"Error validando pregunta: {e}. Datos: {q}")

    logging.info(f"Generadas válidas para cap {id_capitulo}: {len(valid_questions)}")
    return valid_questions


# -----------------------------
# HELPERS
# -----------------------------
def generate_for_chapter(id_capitulo: int, contenido_texto: str):
    preguntas = generate_questions_from_text(contenido_texto, id_capitulo)
    return [p.dict() for p in preguntas]


# -----------------------------
# MAIN BOOK PROCESSOR
# -----------------------------
def process_full_book(input_data: BookProcessingInput):
    logging.info(f"Iniciando procesamiento libro {input_data.id_libro}")

    try:
        full_text = extract_text_from_pdf_url(input_data.ruta_archivo)
        chapters = divide_text_into_chapters(full_text, input_data.total_capitulos)

        if not chapters:
            logging.error("No chapters found.")
            return {"success": False, "error": "No content"}

        total_saved = 0

        for chapter_num, fragment in chapters.items():
            raw_header = fragment.split("\n", 1)[0].strip()

            # Detectar títulos estilo: "I. TÍTULO"
            match = re.match(r"^([IVXLCDM]+)\.\s+(.+)$", raw_header.strip(), re.IGNORECASE)

            if match:
                titulo_detectado = match.group(2)
                chapter_title = titulo_detectado
            else:
                chapter_title = f"Capítulo {chapter_num}"

            logging.info(f"Procesando capítulo: {chapter_title}")


            chapter_payload = {
                "id_libro": input_data.id_libro,
                "numero_capitulo": chapter_num,
                "titulo_capitulo": chapter_title,
                "contenido_texto": fragment
            }

            # Insertar capítulo en Node
            try:
                resp = requests.post(INTERNAL_CHAPTER_API_URL, json=chapter_payload, timeout=30)
            except Exception as e:
                logging.error(f"Error insert chapter: {e}")
                continue

            if resp.status_code != 201:
                logging.error(f"Chapter insert failed: {resp.status_code} {resp.text}")
                continue

            id_capitulo_pk = resp.json().get("id_capitulo")
            if not id_capitulo_pk:
                logging.error("Node no devolvió id_capitulo")
                continue

            # Generar preguntas
            preguntas = generate_questions_from_text(fragment, id_capitulo_pk)
            if not preguntas:
                logging.warning("No preguntas generadas para cap " + str(id_capitulo_pk))
                continue

            payload_save = {
                "id_libro": input_data.id_libro,
                "preguntas": [p.dict() for p in preguntas]
            }

            # Guardar preguntas
            try:
                save_resp = requests.post(INTERNAL_SAVE_QUESTIONS_URL, json=payload_save, timeout=30)
            except Exception as e:
                logging.error(f"Error al guardar preguntas: {e}")
                continue

            if save_resp.status_code == 201:
                total_saved += len(preguntas)
                logging.info(f"Preguntas cap {id_capitulo_pk} guardadas: {len(preguntas)}")
            else:
                logging.error(f"Error guardando preguntas {save_resp.status_code}: {save_resp.text}")

            time.sleep(0.5)

        logging.info(f"Total guardadas: {total_saved}")
        return {"success": True, "total_saved": total_saved}

    except Exception as e:
        logging.exception("Error fatal worker")
        return {"success": False, "error": str(e)}



# NOTA: Debes correr este worker a través de uvicorn main:app --reload --host 0.0.0.0 --port 8000