// leotest-backend/src/routes/mission.routes.js

import express from "express";
import { getActiveMissions, completeMission, workerAssignMissions } from "../controllers/mission.controller.js";

const router = express.Router();

// routes
router.get("/:profileId", getActiveMissions);
router.put("/complete/:id_usuario_mision", completeMission);

router.post('/assign', workerAssignMissions);


export default router;