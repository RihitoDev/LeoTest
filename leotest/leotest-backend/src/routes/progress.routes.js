// routes/progress.routes.js

import express from 'express';
import { 
    getUserProgress, 
    addBookToProgress, 
    updateProgress 
} from '../controllers/progress.controller.js';

const router = express.Router();

// Nota: En un sistema real, el /:userId se obtendría del token
router.get('/:userId', getUserProgress); 
router.post('/', addBookToProgress);
router.put('/:userId/:id_libro', updateProgress);

export default router;