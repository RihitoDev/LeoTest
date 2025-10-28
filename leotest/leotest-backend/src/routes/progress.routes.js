// leotest-backend/src/routes/progress.routes.js

import express from 'express';
import {
    getUserProgress,
    addBookToProgress,
    updateProgress,
    deleteProgress // ✅ 1. IMPORTAR NUEVO CONTROLADOR
} from '../controllers/progress.controller.js';

const router = express.Router();

// Nota: En un sistema real, el /:userId se obtendría del token
router.get('/:userId', getUserProgress);
router.post('/', addBookToProgress);
router.put('/:userId/:id_libro', updateProgress);
// ✅ 2. AÑADIR NUEVA RUTA DELETE
router.delete('/:userId/:id_libro', deleteProgress);

export default router;