// leotest-backend/src/routes/profile.routes.js
import express from "express";
import { getProfileByUserId, createProfile, getNivelesEducativos } from "../controllers/profile.controller.js";

const router = express.Router();

router.get("/user/:userId", getProfileByUserId);
router.post("/", createProfile);
router.get("/niveles", getNivelesEducativos);

export default router;
