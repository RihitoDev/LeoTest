import express from 'express';
import { loginUsuario, registrarUsuario } from '../controllers/auth.controller.js'; 

const router = express.Router();

router.post('/login', loginUsuario);
router.post('/register', registrarUsuario); 

export default router;