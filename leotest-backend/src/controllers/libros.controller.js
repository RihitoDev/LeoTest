import pool from "../db/connection.js";
import { supabase } from "../db/supabaseClient.js";
import multer from "multer";
import fs from "fs";

// Configurar multer para archivos temporales
const upload = multer({ dest: "uploads/" });
export const uploadLibroMiddleware = upload.single("archivo");

export const buscarLibros = async (req, res) => {
  try {
    const { titulo, autor, id_categoria } = req.query;

    let query = `
      SELECT 
        l.id_libro, 
        l.titulo, 
        l.descripcion, 
        l.autor, 
        l.portada, 
        l.total_paginas, 
        l.total_capitulos, 
        c.nombre_categoria AS categoria
      FROM libro l
      JOIN categoria c ON l.id_categoria = c.id_categoria
      WHERE 1=1
    `;

    const params = [];

    if (titulo) {
      params.push(`%${titulo}%`);
      query += ` AND l.titulo ILIKE $${params.length}`;
    }
    if (autor) {
      params.push(`%${autor}%`);
      query += ` AND l.autor ILIKE $${params.length}`;
    }
    if (id_categoria) {
      params.push(parseInt(id_categoria));
      query += ` AND l.id_categoria = $${params.length}`;
    }

    const result = await pool.query(query, params);

    res.status(200).json({
      exito: true,
      total: result.rows.length,
      resultados: result.rows,
    });
  } catch (error) {
    console.error("Error en buscarLibros:", error);
    res.status(500).json({ exito: false, mensaje: "Error en la búsqueda" });
  }
};


// Subir libro a Supabase y guardar en PostgreSQL
export const subirLibro = async (req, res) => {
  try {
    let { titulo, autor, descripcion, id_categoria, id_nivel_educativo } = req.body;
    const archivo = req.file;

    if (!archivo) {
      return res.status(400).json({ error: "No se envió ningún archivo" });
    }

    // Valores por defecto
    titulo = titulo || archivo.originalname.replace(/\.pdf$/i, "");
    autor = autor || "Desconocido";
    descripcion = descripcion || "Sin descripción";
    id_categoria = parseInt(id_categoria) || 1;
    id_nivel_educativo = parseInt(id_nivel_educativo) || 1;

    // Subir a Supabase Storage
    const fileBuffer = fs.readFileSync(archivo.path);
    const fileName = `libros/${Date.now()}_${archivo.originalname}`;

    const { data, error } = await supabase.storage
      .from("libros")
      .upload(fileName, fileBuffer, { contentType: archivo.mimetype });

    fs.unlinkSync(archivo.path);

    if (error) throw error;

    const { data: publicData } = supabase.storage.from("libros").getPublicUrl(fileName);
    const ruta_archivo = publicData.publicUrl;

    // Guardar en PostgreSQL
    const insertQuery = `
      INSERT INTO libro
        (titulo, autor, descripcion, id_categoria, id_nivel_educativo, ruta_archivo, fecha_registro)
      VALUES ($1, $2, $3, $4, $5, $6, NOW())
      RETURNING *;
    `;
    const values = [titulo, autor, descripcion, id_categoria, id_nivel_educativo, ruta_archivo];

    const result = await pool.query(insertQuery, values);

    res.status(201).json({
      mensaje: "Libro subido correctamente",
      libro: result.rows[0],
    });
  } catch (error) {
    console.error("Error al subir libro:", error);
    res.status(500).json({ error: "Error al subir el libro" });
  }
};

// Obtener categorías
export const obtenerCategorias = async (req, res) => {
  try {
    const result = await pool.query("SELECT id_categoria, nombre_categoria FROM categoria ORDER BY nombre_categoria");
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Obtener niveles educativos
export const obtenerNiveles = async (req, res) => {
  try {
    const result = await pool.query("SELECT id_nivel_educativo, nombre_nivel_educativo FROM nivel_educativo ORDER BY nombre_nivel_educativo");
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
