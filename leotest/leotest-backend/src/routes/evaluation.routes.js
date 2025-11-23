// src/routes/evaluation.routes.js
import express from "express";
import {
  getChaptersByBook,
  generarPreguntasPorCapitulo,
  fetchPreguntasPorCapitulo,
  submitEvaluation,
  getEvaluacionesPorPerfil, 
} from "../controllers/evaluation.controller.js";

const router = express.Router();

router.get("/libro/:idLibro/capitulos", getChaptersByBook);
router.post("/capitulo/:idCapitulo/generar", generarPreguntasPorCapitulo);
router.get("/capitulo/:idCapitulo/preguntas", fetchPreguntasPorCapitulo);
router.post("/libro/:idLibro/perfil/:idPerfil/enviar", submitEvaluation);
router.get("/perfil/:idPerfil", getEvaluacionesPorPerfil);

export default router;
