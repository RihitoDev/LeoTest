// leotest-backend/src/app.js

import express from "express";
import cors from "cors";
import dotenv from "dotenv";

// 2. Importaciones de rutas de tu proyecto
import librosRoutes from "./routes/libros.routes.js";
import authRoutes from "./routes/auth.routes.js"; 
import progressRoutes from './routes/progress.routes.js'; 
import favoritosRoutes from './routes/favoritos.routes.js';
import statsRoutes from './routes/stats.routes.js';        // ✅ Importado
import missionRoutes from './routes/mission.routes.js';    // ✅ Importado
import notificationRoutes from './routes/notification.routes.js'; // ✅ Importado
import profileRoutes from './routes/profile.routes.js';      // ✅ Importado

// Asumimos que también tenemos la ruta de IA (ya que es parte de tu arquitectura)
import iaRoutes from './routes/ia.routes.js';              // ✅ Importado


// 3. Configurar dotenv
dotenv.config();

// 4. DECLARACIÓN DE APP Y PUERTO
const app = express(); 
const PORT = process.env.PORT || 3000;


// 5. MIDDLEWARE
app.use(cors());
app.use(express.json());

// 6. MONTAJE DE RUTAS
app.use('/api/progress', progressRoutes);
app.use("/api/libros", librosRoutes);
app.use("/api/auth", authRoutes); 
app.use('/api/favoritos', favoritosRoutes);

// ✅ Montaje de Rutas del Sprint 3:
app.use('/api/stats', statsRoutes);
app.use('/api/missions', missionRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/profile', profileRoutes);

// Ruta de IA (Para futura integración/controlador de libros)
app.use('/api/ia', iaRoutes); 


// 7. INICIO DEL SERVIDOR
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Servidor corriendo en puerto ${PORT}`);
});