import pool from "../db/connection.js";
import fetch from 'node-fetch';

// URL del Microservicio de IA (Python/FastAPI).
const IA_WORKER_URL = process.env.IA_WORKER_URL || 'http://localhost:8000/api/ia/worker_process';

// Función auxiliar para guardar las preguntas en PostgreSQL
async function _saveQuestionsToDB(idLibro, questions, client) {
    const savedQuestions = [];

    for (const q of questions) {
        // Validaciones mínimas
        if (!q || !q.id_capitulo || !q.nivel_comprension || !q.enunciado || !q.opciones) {
            console.error("Pregunta inválida recibida, saltando:", q);
            continue;
        }

        // 1. Insertar en tabla 'pregunta'
        const preguntaQuery = `
            INSERT INTO pregunta (id_capitulo, nivel_comprension, enunciado)
            VALUES ($1, $2, $3)
            RETURNING id_pregunta;
        `;
        const preguntaResult = await client.query(preguntaQuery, [
            q.id_capitulo,
            q.nivel_comprension,
            q.enunciado,
        ]);
        const idPregunta = preguntaResult.rows[0].id_pregunta;

        // 2. Insertar en tabla 'opcion_multiple'
        for (const opt of q.opciones) {
            // Validación mínima de la opción
            if (!opt || typeof opt.texto_opcion === 'undefined' || typeof opt.opcion_correcta === 'undefined') {
                console.warn("Opción inválida para pregunta", idPregunta, opt);
                continue;
            }

            const opcionQuery = `
                INSERT INTO opcion_multiple (id_pregunta, texto_opcion, opcion_correcta)
                VALUES ($1, $2, $3);
            `;
            await client.query(opcionQuery, [
                idPregunta,
                opt.texto_opcion,
                opt.opcion_correcta,
            ]);
        }

        savedQuestions.push({ id_pregunta: idPregunta, enunciado: q.enunciado });
    }
    return savedQuestions;
}

// =================================================================
// 1. DISPARAR EL WORKER DE PROCESAMIENTO (Llamado por libros.controller.js)
// =================================================================
export const triggerBookProcessing = async (idLibro, rutaArchivo, totalCapitulos) => {
    try {
        const payload = {
            id_libro: idLibro,
            ruta_archivo: rutaArchivo,
            total_capitulos: totalCapitulos,
        };

        // Llama al Microservicio de IA (Python) para iniciar el proceso asíncrono
        const iaResponse = await fetch(IA_WORKER_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });

        if (!iaResponse.ok) {
            const errorText = await iaResponse.text();
            console.error(`🚨 Error al disparar Worker IA (${iaResponse.status}): ${errorText}`);
        } else {
            console.log(`✅ Worker de IA disparado exitosamente para libro ID ${idLibro}`);
        }

    } catch (error) {
        console.error("Error de red al disparar Worker IA:", error);
    }
};

// =================================================================
// 2. GUARDAR RESULTADOS DEL WORKER (Endpoint Interno)
// =================================================================
export const saveGeneratedQuestions = async (req, res) => {
    const { id_libro, preguntas } = req.body;

    if (!id_libro || !preguntas || !Array.isArray(preguntas) || preguntas.length === 0) {
        return res.status(400).json({ mensaje: "Datos de preguntas incompletos." });
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        // Persistir las preguntas en PostgreSQL
        const savedQuestions = await _saveQuestionsToDB(id_libro, preguntas, client);

        await client.query('COMMIT');

        res.status(201).json({
            exito: true,
            mensaje: "Preguntas generadas y guardadas exitosamente.",
            total_preguntas: savedQuestions.length
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Error al guardar preguntas generadas (Worker Result):", error);
        res.status(500).json({ mensaje: "Error interno al guardar resultados de IA." });
    } finally {
        client.release();
    }
};
