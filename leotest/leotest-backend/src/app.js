import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import librosRoutes from "./routes/libros.routes.js";
import authRoutes from "./routes/auth.routes.js"; 
import progressRoutes from './routes/progress.routes.js'; 



dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;


app.use(cors());
app.use(express.json());

app.use('/api/progress', progressRoutes);
app.use("/api/libros", librosRoutes);
app.use("/api/auth", authRoutes); 


app.listen(PORT, '0.0.0.0', () => {
    // ...
});