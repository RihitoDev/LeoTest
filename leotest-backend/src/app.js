import express from "express";
import cors from "cors";
import dotenv from "dotenv"; // Para leer .env
import librosRoutes from "./routes/libros.routes.js";

dotenv.config(); // Carga las variables de entorno

const app = express();
const PORT = process.env.PORT || 3000;

// 🔹 Habilitar CORS para permitir peticiones desde Flutter
app.use(cors());

// 🔹 Middlewares
app.use(express.json());

// 🔹 Rutas
app.use("/api/libros", librosRoutes);

// 🔹 Iniciar servidor en todas las interfaces de red
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor corriendo en http://0.0.0.0:${PORT}`);
  console.log(`Puedes acceder desde tu celular con http://192.168.1.2:${PORT}`);
});
