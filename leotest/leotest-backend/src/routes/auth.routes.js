// leotest-backend/src/routes/auth.routes.js
import express from "express";
import {
  loginUsuario,
  registrarUsuario,
  changePassword,
  updateUsername,
  deleteUser,
  getUsernameById
} from "../controllers/auth.controller.js";

const router = express.Router();

router.post("/login", loginUsuario);
router.post("/register", registrarUsuario);

router.post("/change_password", changePassword);
router.post("/update_username", updateUsername);
router.delete("/delete_user/:userId", deleteUser);
router.get("/user/:userId", getUsernameById);

export default router;
