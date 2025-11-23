// leotest-backend/src/routes/profile.routes.js
import express from "express";
import {
  getProfileByUserId,
  createProfile,
  getNivelesEducativos,
  updateProfile,
  deleteProfile
} from "../controllers/profile.controller.js";

const router = express.Router();

router.get("/user/:userId", getProfileByUserId);
router.post("/", createProfile);
router.get("/niveles", getNivelesEducativos);
router.put("/:profileId", updateProfile);       // actualizar por profileId
router.put("/user/:userId", updateProfile);     // actualizar por userId

router.delete("/delete/:profileId", deleteProfile);

export default router;
