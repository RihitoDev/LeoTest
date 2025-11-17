// leotest-backend/src/routes/ia.routes.js

import express from "express";
import { saveGeneratedQuestions } from "../controllers/ia.controller.js"; 

const router = express.Router();

// RUTA INTERNA: Usada por el Worker de Python para guardar los resultados finales
router.post("/save_generated", saveGeneratedQuestions);

export default router;