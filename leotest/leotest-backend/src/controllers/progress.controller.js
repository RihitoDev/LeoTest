// leotest-backend/src/controllers/progress.controller.js
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
// 1. OBTENER LIBROS EN LA BIBLIOTECA DEL PERFIL (GET)
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
                l.total_paginas,
                l.autor,
                l.descripcion,
                l.ruta_archivo AS url_pdf,
                c.nombre_categoria AS categoria
            FROM progreso p
            JOIN libro l ON p.id_libro = l.id_libro
            LEFT JOIN categoria c ON l.id_categoria = c.id_categoria
            WHERE p.id_perfil = $1;
        `;

        const result = await pool.query(query, [userIdInt]);

        res.status(200).json({
            exito: true,
            progreso: result.rows
        });

    } catch (error) {
        if (error.message.includes('debe ser un número entero válido')) {
            return res.status(400).json({ mensaje: error.message });
        }
        console.error("Error al obtener progreso:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al obtener progreso." });
    }
};

// =================================================================
// 2. AÑADIR UN LIBRO A LA BIBLIOTECA (POST)
// =================================================================
export const addBookToProgress = async (req, res) => {
    const { userId, id_libro, total_paginas } = req.body;

    try {
        if (!userId || id_libro === undefined || total_paginas === undefined) {
            return res.status(400).json({ mensaje: "Datos de libro (userId, id_libro, total_paginas) incompletos." });
        }

        const userIdInt = validateAndParseInt(userId, 'userId');
        const idLibroInt = validateAndParseInt(id_libro, 'id_libro');
        validateAndParseInt(total_paginas, 'total_paginas');

        const checkQuery = `
            SELECT id_progreso 
            FROM progreso 
            WHERE id_perfil = $1 AND id_libro = $2
        `;
        const checkResult = await pool.query(checkQuery, [userIdInt, idLibroInt]);

        if (checkResult.rows.length > 0) {
            return res.status(409).json({ mensaje: "El libro ya está en la biblioteca personal." });
        }

        const insertQuery = `
            INSERT INTO progreso (id_perfil, id_libro, estado, paginas_leidas, capitulos_completados, fecha_inicio, fecha_fin)
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
        console.error("Error al añadir libro:", error.message || error);
        res.status(500).json({ mensaje: "Error interno del servidor al añadir libro." });
    }
};

// =================================================================
// 3. ACTUALIZAR EL PROGRESO DE UN LIBRO (PUT) - CORREGIDO
// =================================================================
export const updateProgress = async (req, res) => {
    const { userId, id_libro } = req.params;
    const { paginas_leidas, capitulos_completados, estado } = req.body;

    try {
        // Validar datos recibidos
        if (paginas_leidas === undefined || capitulos_completados === undefined || !estado) {
            return res.status(400).json({ mensaje: "Datos de progreso incompletos." });
        }

        const userIdInt = parseInt(userId);
        const idLibroInt = parseInt(id_libro);
        const paginasLeidasInt = parseInt(paginas_leidas);
        const capitulosCompletadosInt = parseInt(capitulos_completados);

        if (isNaN(userIdInt) || isNaN(idLibroInt) || isNaN(paginasLeidasInt) || isNaN(capitulosCompletadosInt)) {
            return res.status(400).json({ mensaje: "Los campos deben ser números enteros." });
        }

        const estadoCompletado = 'Completado';

        const updateQuery = `
            UPDATE progreso
            SET
                paginas_leidas = $3,
                capitulos_completados = $4,
                estado = $5,
                fecha_fin = CASE WHEN $5::varchar = $6::varchar THEN NOW() ELSE '9999-12-31' END
            WHERE id_perfil = $1 AND id_libro = $2
            RETURNING *;
        `;

        const result = await pool.query(updateQuery, [
            userIdInt,
            idLibroInt,
            paginasLeidasInt,
            capitulosCompletadosInt,
            estado,
            estadoCompletado
        ]);

        if (result.rows.length === 0) {
            return res.status(404).json({ mensaje: "Progreso no encontrado para actualizar." });
        }

        res.status(200).json({ exito: true, mensaje: "Progreso actualizado.", progreso: result.rows[0] });

    } catch (error) {
        console.error("Error al actualizar progreso:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al actualizar progreso." });
    }
};


// =================================================================
// 4. ELIMINAR UN LIBRO (DELETE)
// =================================================================
export const deleteProgress = async (req, res) => {
    const { userId, id_libro } = req.params;

    try {
        const userIdInt = validateAndParseInt(userId, 'userId');
        const idLibroInt = validateAndParseInt(id_libro, 'id_libro');

        const deleteQuery = `
            DELETE FROM progreso
            WHERE id_perfil = $1 AND id_libro = $2
            RETURNING id_progreso;
        `;

        const result = await pool.query(deleteQuery, [userIdInt, idLibroInt]);

        if (result.rowCount === 0) {
            return res.status(404).json({ mensaje: "Libro no encontrado en la biblioteca para eliminar." });
        }

        res.status(200).json({
            exito: true,
            mensaje: "Libro eliminado de la biblioteca con éxito."
        });

    } catch (error) {
        if (error.message.includes('debe ser un número entero válido')) {
            return res.status(400).json({ mensaje: error.message });
        }
        console.error("Error al eliminar libro de progreso:", error.message || error);
        res.status(500).json({ mensaje: "Error interno del servidor al eliminar libro." });
    }
};
