// leotest-backend/src/routes/libros.routes.js

import express from "express";
import { 
    buscarLibros, 
    subirLibro, 
    uploadLibroMiddleware, 
    obtenerCategorias, 
    obtenerNiveles,
    crearCategoria,
    createChapterInternal 
} from "../controllers/libros.controller.js";

const router = express.Router();

router.get("/", buscarLibros); 
router.get("/buscar", buscarLibros); 
router.post("/subir", uploadLibroMiddleware, subirLibro); 
router.get("/categorias", obtenerCategorias);
router.post("/categorias", crearCategoria); 
router.get("/niveles", obtenerNiveles);
router.post("/internal/chapter", createChapterInternal);
export default router;