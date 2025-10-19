import express from "express";
import { buscarLibros, subirLibro, uploadLibroMiddleware, obtenerCategorias, obtenerNiveles } from "../controllers/libros.controller.js";

const router = express.Router();

router.get("/", buscarLibros); // opcional, lista todos los libros
router.get("/buscar", buscarLibros); // <-- esta línea es necesaria
router.post("/subir", uploadLibroMiddleware, subirLibro);
router.get("/categorias", obtenerCategorias);
router.get("/niveles", obtenerNiveles);

export default router;
