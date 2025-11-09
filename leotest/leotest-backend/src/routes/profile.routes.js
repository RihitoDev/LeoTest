import { Router } from "express";
import { getProfilesByUser, createProfile } from "../controllers/profile.controller.js";

const router = Router();

router.get("/user/:id_usuario", getProfilesByUser);
router.post("/", createProfile);

export default router;
