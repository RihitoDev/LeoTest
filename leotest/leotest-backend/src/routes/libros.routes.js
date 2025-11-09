// leotest-backend/src/routes/libros.routes.js
import express from "express";
import { 
    buscarLibros, 
    subirLibro, 
    uploadLibroMiddleware, 
    obtenerCategorias, 
    obtenerNiveles,
    crearCategoria 
} from "../controllers/libros.controller.js";
import { procesarCapitulos } from "../controllers/procesarCapitulos.controller.js";

const router = express.Router();

router.get("/", buscarLibros); 
router.get("/buscar", buscarLibros); 
router.post("/subir", uploadLibroMiddleware, subirLibro); 
router.get("/categorias", obtenerCategorias);
router.post("/categorias", crearCategoria); 
router.get("/niveles", obtenerNiveles);
router.post("/:id_libro/procesar-capitulos", procesarCapitulos);


export default router;