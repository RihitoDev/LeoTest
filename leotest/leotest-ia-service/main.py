# leotest-ia-service/main.py
from fastapi import FastAPI, HTTPException, BackgroundTasks
import uvicorn
import os
import logging
from dotenv import load_dotenv
from pathlib import Path
from pydantic import BaseModel

dotenv_path = Path(__file__).resolve().parent / '.env'
load_dotenv(dotenv_path=dotenv_path)

from ia_worker import BookProcessingInput, process_full_book, initialize_gemini_client, generate_for_chapter

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

GEMINI_CLIENT = initialize_gemini_client()
INTERNAL_NODE_API_URL = os.environ.get("INTERNAL_NODE_API_URL", "http://localhost:3000/api")

app = FastAPI(title="LeoTest IA Microservice", version="1.0")

class ChapterInput(BaseModel):
    id_capitulo: int
    contenido_texto: str

@app.post("/api/ia/worker_process")
async def worker_process(input_data: BookProcessingInput, background_tasks: BackgroundTasks):
    if GEMINI_CLIENT is None:
        raise HTTPException(status_code=503, detail="IA no disponible.")
    if not INTERNAL_NODE_API_URL:
        raise HTTPException(status_code=500, detail="INTERNAL_NODE_API_URL no configurada.")
    background_tasks.add_task(process_full_book, input_data)
    return {"message":"Procesamiento iniciado", "id_libro": input_data.id_libro}

@app.post("/api/ia/generate_chapter")
async def api_generate_chapter(payload: ChapterInput):
    if GEMINI_CLIENT is None:
        raise HTTPException(status_code=503, detail="IA no disponible.")
    try:
        preguntas = generate_for_chapter(payload.id_capitulo, payload.contenido_texto)
        return {"preguntas": preguntas}
    except Exception as e:
        logging.exception("Error generando preguntas")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
