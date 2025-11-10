// leotest-backend/src/routes/profile.routes.js

import express from "express";
import { getProfileData } from "../controllers/profile.controller.js";

const router = express.Router();

router.get("/:userId", getProfileData);

export default router;