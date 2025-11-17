// leotest-backend/src/controllers/libros.controller.js

import pool from "../db/connection.js";
import { supabase } from "../db/supabaseClient.js"; 
import multer from 'multer';
import { triggerBookProcessing } from "./ia.controller.js"; // Importa el disparador de IA

// ----------------------------------------------------
// 1. MIDDLEWARE DE SUBIDA DE ARCHIVOS (MULTER)
// ----------------------------------------------------

const storage = multer.memoryStorage();

export const uploadLibroMiddleware = multer({ storage: storage }).fields([
    { name: 'archivo', maxCount: 1 }, // El archivo PDF/ePub del libro
    { name: 'portada', maxCount: 1 }  // El archivo de imagen (portada)
]); 

// ----------------------------------------------------
// 2. LÓGICA DE SUBIDA DEL LIBRO Y PROCESAMIENTO ASÍNCRONO
// ----------------------------------------------------

export const subirLibro = async (req, res) => {
    // Campos de texto del formulario (req.body)
    const { 
        titulo, autor, descripcion, id_categoria, id_nivel_educativo, 
        total_paginas, total_capitulos 
    } = req.body;
    
    // Archivos subidos (req.files)
    const archivos = req.files; 
    
    const BUCKET_NAME = 'leoTest'; 
    
    const libroFile = archivos?.archivo ? archivos.archivo[0] : null;
    const portadaFile = archivos?.portada ? archivos.portada[0] : null;

    if (!libroFile || !portadaFile) {
        return res.status(400).json({ error: "Debe proporcionar tanto el archivo del libro como la portada." });
    }

    let bookPublicUrl = null;
    let coverPublicUrl = null;
    const safeTitle = titulo.trim().toLowerCase().replace(/[^a-z0-9]/g, '_');
    
    let bookPath = null;
    let coverPath = null;

    try {
        // --- A. SUBIDA DEL ARCHIVO DEL LIBRO Y PORTADA (Supabase Storage) ---
        const bookExtension = libroFile.originalname.split('.').pop();
        bookPath = `libros/${safeTitle}-${Date.now()}.${bookExtension}`; 

        let { error: bookUploadError } = await supabase.storage
            .from(BUCKET_NAME) 
            .upload(bookPath, libroFile.buffer, { 
                contentType: libroFile.mimetype,
                upsert: false 
            });

        if (bookUploadError) {
            console.error("Error de Supabase Storage (Libro):", bookUploadError);
            throw new Error(`Error al subir el libro: ${bookUploadError.message}`);
        }
        bookPublicUrl = supabase.storage.from(BUCKET_NAME).getPublicUrl(bookPath).data.publicUrl;


        const coverExtension = portadaFile.originalname.split('.').pop();
        coverPath = `portadas/${safeTitle}-${Date.now()}.${coverExtension}`; 

        let { error: coverUploadError } = await supabase.storage
            .from(BUCKET_NAME) 
            .upload(coverPath, portadaFile.buffer, { 
                contentType: portadaFile.mimetype,
                upsert: false 
            });

        if (coverUploadError) {
            await supabase.storage.from(BUCKET_NAME).remove([bookPath]);
            throw new Error(`Error al subir la portada: ${coverUploadError.message}`);
        }
        coverPublicUrl = supabase.storage.from(BUCKET_NAME).getPublicUrl(coverPath).data.publicUrl;


        // --- B. INSERTAR DATOS DEL LIBRO EN POSTGRES ---
        const query = `
            INSERT INTO libro 
            (titulo, autor, descripcion, id_categoria, id_nivel_educativo, ruta_archivo, portada, total_paginas, total_capitulos, fecha_registro)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
            RETURNING id_libro; 
        `;
        const values = [
            titulo, autor, descripcion, id_categoria, id_nivel_educativo,
            bookPublicUrl, coverPublicUrl, total_paginas || 0, total_capitulos || 0
        ];

        const dbResult = await pool.query(query, values);
        const idLibroGenerado = dbResult.rows[0].id_libro; 

        // ✅ DISPARAR EL PROCESAMIENTO ASÍNCRONO DEL LIBRO DE IA
        // Se llama sin 'await' para no bloquear la respuesta HTTP
        triggerBookProcessing(
            idLibroGenerado, 
            bookPublicUrl, 
            total_capitulos || 1
        );

        res.status(201).json({ 
            exito: true, 
            mensaje: "Libro subido, procesamiento de IA iniciado.",
            id_libro: idLibroGenerado
        });

    } catch (error) {
        console.error("Error general en subirLibro:", error.message);
        
        const filesToRemove = [];
        if (bookPath && !bookPublicUrl) filesToRemove.push(bookPath);
        if (coverPath && !coverPublicUrl) filesToRemove.push(coverPath);
        
        if (filesToRemove.length > 0) {
             await supabase.storage.from(BUCKET_NAME).remove(filesToRemove);
             console.log(`Archivos limpiados en Supabase: ${filesToRemove.join(', ')}`);
        }
        
        res.status(500).json({ 
            error: "Error al subir el libro", 
            details: error.message 
        });
    }
};


// ----------------------------------------------------
// 3. FUNCIONES DE CATÁLOGO Y BÚSQUEDA
// ----------------------------------------------------

export const buscarLibros = async (req, res) => {
  try {
    let { query, categoriaId } = req.query;

    query = query ? query.trim() : null;
    categoriaId = categoriaId ? parseInt(categoriaId) : null;

    let sql = `
      SELECT 
        l.id_libro, 
        l.titulo, 
        l.descripcion, 
        l.autor, 
        l.portada, 
        l.total_paginas, 
        l.total_capitulos, 
        l.ruta_archivo AS url_pdf,
        c.nombre_categoria AS categoria
      FROM libro l
      JOIN categoria c ON l.id_categoria = c.id_categoria
      WHERE 1=1
    `;

    const params = [];

    if (query) {
      const q = `%${query}%`;
      params.push(q, q, q);
      sql += ` AND (
        l.titulo ILIKE $${params.length - 2} 
        OR l.autor ILIKE $${params.length - 1} 
        OR c.nombre_categoria ILIKE $${params.length}
      )`;
    }

    if (categoriaId) {
      params.push(categoriaId);
      sql += ` AND c.id_categoria = $${params.length}`;
    }

    const result = await pool.query(sql, params);

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


export const obtenerCategorias = async (req, res) => {
    try {
        const result = await pool.query("SELECT id_categoria, nombre_categoria FROM categoria ORDER BY nombre_categoria");
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

export const crearCategoria = async (req, res) => {
    const { nombre } = req.body;
    if (!nombre || nombre.trim().length === 0) {
        return res.status(400).json({ mensaje: "El nombre de la categoría es requerido." });
    }
    const nombreCategoria = nombre.trim();

    try {
        const check = await pool.query("SELECT 1 FROM categoria WHERE nombre_categoria ILIKE $1", [nombreCategoria]);
        if (check.rows.length > 0) {
            return res.status(409).json({ mensaje: "La categoría ya existe." });
        }
        
        const result = await pool.query(
            "INSERT INTO categoria (nombre_categoria) VALUES ($1) RETURNING *",
            [nombreCategoria]
        );
        res.status(201).json({ mensaje: "Categoría creada con éxito", categoria: result.rows[0] });
    } catch (e) {
        console.error("Error al crear categoría:", e);
        res.status(500).json({ error: e.message });
    }
};

export const obtenerNiveles = async (req, res) => {
    try {
        const result = await pool.query("SELECT id_nivel_educativo, nombre_nivel_educativo FROM nivel_educativo ORDER BY nombre_nivel_educativo");
        res.json(result.rows);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};
export const createChapterInternal = async (req, res) => {
    const { id_libro, numero_capitulo, titulo_capitulo, contenido_texto } = req.body;

    if (!id_libro || !numero_capitulo || !titulo_capitulo || !contenido_texto) {
        return res.status(400).json({ mensaje: "Datos de capítulo incompletos." });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        
        // 1. Insertar en tabla 'capitulo'
        const chapterQuery = `
            INSERT INTO capitulo (id_libro, numero_capitulo, titulo_capitulo)
            VALUES ($1, $2, $3)
            RETURNING id_capitulo;
        `;
        const chapterResult = await client.query(chapterQuery, [id_libro, numero_capitulo, titulo_capitulo]);
        const idCapitulo = chapterResult.rows[0].id_capitulo;

        // 2. Insertar el texto extraído en la tabla 'capitulo_embedding'
        const embeddingQuery = `
            INSERT INTO capitulo_embedding (id_capitulo, contenido_texto)
            VALUES ($1, $2);
        `;
        // Nota: Omitimos la columna 'embedding' (USER-DEFINED) que requiere librerías vectoriales
        await client.query(embeddingQuery, [idCapitulo, contenido_texto]); 

        await client.query('COMMIT');

        res.status(201).json({ 
            exito: true, 
            id_capitulo: idCapitulo,
            mensaje: "Capítulo y contenido guardados con éxito."
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Error interno al crear capítulo:", error);
        res.status(500).json({ mensaje: "Error interno al guardar el capítulo." });
    } finally {
        client.release();
    }
};