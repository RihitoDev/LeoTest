# leotest-ia-service/main.py

from fastapi import FastAPI, HTTPException, BackgroundTasks
import uvicorn
import os
import logging
from dotenv import load_dotenv 
from pathlib import Path 

# Configuración de Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# 🚨 CARGA ROBUSTA DE VARIABLES DE ENTORNO:
dotenv_path = Path(__file__).resolve().parent / '.env'
load_dotenv(dotenv_path=dotenv_path) 

# Leemos las variables después de cargarlas
INTERNAL_NODE_API_URL = os.environ.get("INTERNAL_NODE_API_URL")

# Importaciones del worker y la inicialización
from ia_worker import BookProcessingInput, process_full_book, initialize_gemini_client 

# 🚨 Inicializar el cliente Gemini globalmente antes de que Uvicorn arranque
GEMINI_CLIENT = initialize_gemini_client() 

# Configuración de FastAPI
app = FastAPI(title="LeoTest IA Microservice", version="1.0")

# ----------------------------------------------------------------
# Endpoint Asíncrono (Disparado por Node.js)
# ----------------------------------------------------------------
@app.post("/api/ia/worker_process", summary="Inicia el procesamiento asíncrono de un libro completo.")
async def start_book_processing(input_data: BookProcessingInput, background_tasks: BackgroundTasks):
    
    # 1. Verificación Crítica: Si el cliente Gemini falló al iniciar, devolvemos 503
    if GEMINI_CLIENT is None:
        logging.error("Error 503: El cliente Gemini no pudo ser inicializado. (Clave faltante/inválida).")
        raise HTTPException(status_code=503, detail="Servicio de IA no disponible.")
        
    # 2. Verificación de la URL interna de Node.js
    if not INTERNAL_NODE_API_URL:
        logging.error("Error 500: INTERNAL_NODE_API_URL no configurada.")
        raise HTTPException(status_code=500, detail="Error: INTERNAL_NODE_API_URL no configurada.")
        
    # 3. Se añade la función process_full_book al pool de workers de fondo 
    background_tasks.add_task(
        process_full_book, 
        input_data
    )
    
    return {
        "message": "Procesamiento de IA iniciado en segundo plano.",
        "id_libro": input_data.id_libro
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)