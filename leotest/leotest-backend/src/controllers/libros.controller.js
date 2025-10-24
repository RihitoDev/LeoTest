// leotest-backend/src/controllers/libros.controller.js

import pool from "../db/connection.js";
import { supabase } from "../db/supabaseClient.js"; // Importa el cliente de Supabase
import multer from 'multer';

// ----------------------------------------------------
// 1. MIDDLEWARE DE SUBIDA DE ARCHIVOS (MULTER)
// ----------------------------------------------------

// Configuración de Multer para ALMACENAMIENTO EN MEMORIA
const storage = multer.memoryStorage();

// MIDDLEWARE: Acepta dos campos de archivo: 'archivo' (libro) y 'portada' (imagen)
export const uploadLibroMiddleware = multer({ storage: storage }).fields([
    { name: 'archivo', maxCount: 1 }, // El archivo PDF/ePub del libro
    { name: 'portada', maxCount: 1 }  // El archivo de imagen (portada)
]); 

// ----------------------------------------------------
// 2. LÓGICA DE SUBIDA DEL LIBRO Y PORTADA
// ----------------------------------------------------

export const subirLibro = async (req, res) => {
    // Campos de texto del formulario (req.body)
    const { 
        titulo, autor, descripcion, id_categoria, id_nivel_educativo, 
        total_paginas, total_capitulos 
    } = req.body;
    
    // Archivos subidos (req.files)
    const archivos = req.files; 
    
    // BUCKET CONFIGURADO: Usamos el bucket 'leoTest'
    const BUCKET_NAME = 'leoTest'; 
    
    // Verificación de archivos
    const libroFile = archivos?.archivo ? archivos.archivo[0] : null;
    const portadaFile = archivos?.portada ? archivos.portada[0] : null;

    if (!libroFile || !portadaFile) {
        return res.status(400).json({ error: "Debe proporcionar tanto el archivo del libro como la portada." });
    }

    // Inicialización de rutas y URLs
    let bookPublicUrl = null;
    let coverPublicUrl = null;
    const safeTitle = titulo.trim().toLowerCase().replace(/[^a-z0-9]/g, '_');
    
    // Rutas para limpieza en caso de error
    let bookPath = null;
    let coverPath = null;

    try {
        // --- A. SUBIDA DEL ARCHIVO DEL LIBRO ---
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


        // --- B. SUBIDA DEL ARCHIVO DE LA PORTADA ---
        const coverExtension = portadaFile.originalname.split('.').pop();
        coverPath = `portadas/${safeTitle}-${Date.now()}.${coverExtension}`; 

        let { error: coverUploadError } = await supabase.storage
            .from(BUCKET_NAME) 
            .upload(coverPath, portadaFile.buffer, { 
                contentType: portadaFile.mimetype,
                upsert: false 
            });

        if (coverUploadError) {
            // Limpieza del libro subido si falla la portada
            await supabase.storage.from(BUCKET_NAME).remove([bookPath]);
            throw new Error(`Error al subir la portada: ${coverUploadError.message}`);
        }
        
        coverPublicUrl = supabase.storage.from(BUCKET_NAME).getPublicUrl(coverPath).data.publicUrl;


        // --- C. INSERTAR DATOS DEL LIBRO EN POSTGRES (CORREGIDO) ---
        const query = `
            INSERT INTO libro 
            (titulo, autor, descripcion, id_categoria, id_nivel_educativo, ruta_archivo, portada, total_paginas, total_capitulos, fecha_registro)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
            RETURNING *;
        `;
        // El array 'values' solo tiene 9 elementos, ya que NOW() reemplaza al décimo placeholder.
        const values = [
            titulo,                 // $1
            autor,                  // $2
            descripcion,            // $3
            id_categoria,           // $4
            id_nivel_educativo,     // $5
            bookPublicUrl,          // $6 (Columna: ruta_archivo)
            coverPublicUrl,         // $7 (Columna: portada)
            total_paginas || 0,     // $8
            total_capitulos || 0    // $9
        ];

        await pool.query(query, values);

        res.status(201).json({ 
            exito: true, 
            mensaje: "Libro y portada subidos con éxito", 
        });

    } catch (error) {
        console.error("Error general en subirLibro:", error.message);
        
        // Limpieza de archivos si algo falló
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
// 3. OTRAS FUNCIONES CRUD Y BÚSQUEDA
// ----------------------------------------------------

export const buscarLibros = async (req, res) => {
    try {
        let { titulo, autor, id_categoria, id_nivel } = req.query;

        titulo = titulo ? titulo.trim() : null;
        autor = autor ? autor.trim() : null;

        let query = `
            SELECT 
                l.id_libro, 
                l.titulo, 
                l.descripcion, 
                l.autor, 
                l.portada,      
                l.ruta_archivo, 
                l.total_paginas, 
                l.total_capitulos, 
                c.nombre_categoria AS categoria,
                n.nombre_nivel_educativo AS nivel
            FROM libro l
            JOIN categoria c ON l.id_categoria = c.id_categoria
            JOIN nivel_educativo n ON l.id_nivel_educativo = n.id_nivel_educativo
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
        
        if (id_nivel) {
            params.push(parseInt(id_nivel));
            query += ` AND l.id_nivel_educativo = $${params.length}`;
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