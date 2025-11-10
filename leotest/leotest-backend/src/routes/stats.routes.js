// leotest-backend/src/routes/stats.routes.js

import express from "express";
import { getCurrentStreak, getGeneralStats } from "../controllers/stats.controller.js";

const router = express.Router();

// Obtiene solo la racha
router.get("/racha/:userId", getCurrentStreak);

// Obtiene todas las estadísticas generales
router.get("/general/:userId", getGeneralStats);

export default router;