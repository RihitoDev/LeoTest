// leotest-backend/src/routes/mission.routes.js

import express from "express";
import { getActiveMissions, completeMission, workerAssignMissions } from "../controllers/mission.controller.js";

const router = express.Router();

router.get("/:userId", getActiveMissions);
router.put("/complete/:id_usuario_mision", completeMission);

// Ruta para simulación de asignación por worker (propósito de prueba)
router.post("/worker/assign", workerAssignMissions); 

export default router;