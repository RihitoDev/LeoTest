// controllers/progress.controller.js

import pool from "../db/connection.js";

// Función auxiliar para validar y convertir a entero
const validateAndParseInt = (value, fieldName) => {
    const intValue = parseInt(value);
    if (isNaN(intValue)) {
        throw new Error(`El campo '${fieldName}' debe ser un número entero válido.`);
    }
    return intValue;
};

// =================================================================
// 1. OBTENER LIBROS EN LA BIBLIOTECA DEL USUARIO (GET)
// =================================================================
export const getUserProgress = async (req, res) => {
    const { userId } = req.params; 

    try {
        const userIdInt = validateAndParseInt(userId, 'userId');

        const query = `
            SELECT 
                p.id_progreso,
                p.id_libro,
                p.paginas_leidas,
                p.capitulos_completados,
                p.fecha_inicio,
                p.fecha_fin,
                p.estado,
                l.titulo,
                l.portada,
                l.total_paginas
            FROM progreso p
            JOIN libro l ON p.id_libro = l.id_libro
            WHERE p.id_usuario = $1;
        `;
        
        const result = await pool.query(query, [userIdInt]);
        
        res.status(200).json({ 
            exito: true,
            progreso: result.rows
        });

    } catch (error) {
        // Manejar error de validación de ID
        if (error.message.includes('debe ser un número entero válido')) {
            return res.status(400).json({ mensaje: error.message });
        }
        // 🚨 CRASH PREVENTION: Captura de errores de DB/Servidor
        console.error("Error al obtener progreso:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al obtener progreso." });
    }
};

// =================================================================
// 2. AÑADIR UN LIBRO A LA BIBLIOTECA (POST)
// =================================================================
export const addBookToProgress = async (req, res) => {
    // userId y id_libro son obligatorios para esta operación
    const { userId, id_libro, total_paginas } = req.body; 

    try {
        // Validación de existencia
        if (!userId || id_libro === undefined || total_paginas === undefined) {
            return res.status(400).json({ mensaje: "Datos de libro (userId, id_libro, total_paginas) incompletos." });
        }
        
        // Validación y conversión de tipo
        const userIdInt = validateAndParseInt(userId, 'userId');
        const idLibroInt = validateAndParseInt(id_libro, 'id_libro');
        // total_paginas no es necesario en el INSERT, pero lo validamos
        validateAndParseInt(total_paginas, 'total_paginas');

        // 1. Verificar si el libro ya está en progreso
        const checkQuery = "SELECT id_progreso FROM progreso WHERE id_usuario = $1 AND id_libro = $2";
        const checkResult = await pool.query(checkQuery, [userIdInt, idLibroInt]);

        if (checkResult.rows.length > 0) {
            return res.status(409).json({ mensaje: "El libro ya está en la biblioteca personal." });
        }

        // 2. Insertar el nuevo progreso
        const insertQuery = `
            INSERT INTO progreso (id_usuario, id_libro, estado, paginas_leidas, capitulos_completados, fecha_inicio, fecha_fin)
            VALUES ($1, $2, 'Iniciado', 0, 0, NOW(), '9999-12-31')
            RETURNING id_progreso;
        `;
        
        const result = await pool.query(insertQuery, [userIdInt, idLibroInt]);
        
        res.status(201).json({ 
            exito: true,
            mensaje: "Libro añadido a la biblioteca.",
            id_progreso: result.rows[0].id_progreso
        });

    } catch (error) {
        if (error.message.includes('debe ser un número entero válido')) {
            return res.status(400).json({ mensaje: error.message });
        }
        // 🚨 CRASH PREVENTION: Maneja errores de BD (ej. llave foránea)
        console.error("Error al añadir libro:", error.message || error);
        res.status(500).json({ mensaje: "Error interno del servidor al añadir libro." });
    }
};

// =================================================================
// 3. ACTUALIZAR EL PROGRESO DE UN LIBRO (PUT)
// =================================================================
export const updateProgress = async (req, res) => {
    const { userId, id_libro } = req.params; 
    const { paginas_leidas, capitulos_completados, estado } = req.body;

    try {
        // Validación de existencia de datos obligatorios
        if (paginas_leidas === undefined || capitulos_completados === undefined || !estado) {
            return res.status(400).json({ mensaje: "Datos de progreso incompletos (paginas_leidas, capitulos_completados, estado)." });
        }

        // Validación y conversión de tipo
        const userIdInt = validateAndParseInt(userId, 'userId');
        const idLibroInt = validateAndParseInt(id_libro, 'id_libro');
        const paginasLeidasInt = validateAndParseInt(paginas_leidas, 'paginas_leidas');
        const capitulosCompletadosInt = validateAndParseInt(capitulos_completados, 'capitulos_completados');
        
        const updateQuery = `
            UPDATE progreso 
            SET 
                paginas_leidas = $3, 
                capitulos_completados = $4,
                estado = $5,
                -- 🚨 CORRECCIÓN: Usar CAST para forzar el tipo de dato DATE/TIMESTAMP
                fecha_fin = CASE 
                                WHEN $5 = 'Completado' THEN NOW() 
                                ELSE '9999-12-31'::timestamp 
                            END
            WHERE id_usuario = $1 AND id_libro = $2
            RETURNING id_progreso;
        `;
        
        const result = await pool.query(updateQuery, [userIdInt, idLibroInt, paginasLeidasInt, capitulosCompletadosInt, estado]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ mensaje: "Progreso no encontrado para actualizar." });
        }

        res.status(200).json({ 
            exito: true,
            mensaje: "Progreso actualizado."
        });

    } catch (error) {
        if (error.message.includes('debe ser un número entero válido')) {
            return res.status(400).json({ mensaje: error.message });
        }
        // 🚨 CRASH PREVENTION: Maneja errores de DB/Servidor
        console.error("Error al actualizar progreso:", error.message || error);
        res.status(500).json({ mensaje: "Error interno del servidor al actualizar progreso." });
    }
};