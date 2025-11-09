import { Router } from "express";
import pool from "../db/connection.js";

const router = Router();

router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM nivel_educativo ORDER BY id_nivel_educativo ASC");
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: "Error al obtener niveles educativos" });
  }
});

export default router;
