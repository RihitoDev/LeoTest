import express from "express";
import { obtenerFavoritos, agregarFavorito, quitarFavorito } from "../controllers/favoritos.controller.js";

const router = express.Router();

router.get("/:id_perfil", obtenerFavoritos);
router.post("/", agregarFavorito);
router.delete("/", quitarFavorito);

export default router;
