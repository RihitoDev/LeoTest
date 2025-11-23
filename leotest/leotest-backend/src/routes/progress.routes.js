// leotest-backend/src/routes/progress.routes.js

import express from 'express';
import {
    getUserProgress,
    addBookToProgress,
    updateProgress,
    getReadingStreak,
    deleteProgress 
} from '../controllers/progress.controller.js';

const router = express.Router();

router.get('/:userId', getUserProgress);
router.post('/', addBookToProgress);
router.put('/:userId/:id_libro', updateProgress);

router.delete('/:userId/:id_libro', deleteProgress);
router.get("/racha/:idPerfil", getReadingStreak);


export default router;