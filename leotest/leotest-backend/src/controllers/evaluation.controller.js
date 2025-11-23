// src/controllers/evaluation.controller.js
import pool from "../db/connection.js";
import fetch from "node-fetch";
import { updateAllMissionProgress } from "./mission.controller.js";

const IA_WORKER_URL = process.env.IA_WORKER_URL || "http://localhost:8000/api/ia";

// Obtener capítulos por libro
export const getChaptersByBook = async (req, res) => {
  const { idLibro } = req.params;
  const client = await pool.connect();
  try {
    const query = `
      SELECT c.id_capitulo, c.numero_capitulo, c.titulo_capitulo
      FROM capitulo c
      WHERE c.id_libro = $1
      ORDER BY c.numero_capitulo;
    `;
    const result = await client.query(query, [idLibro]);
    res.json({ capitulos: result.rows });
  } catch (error) {
    console.error("Error al obtener capítulos:", error);
    res.status(500).json({ mensaje: "Error interno." });
  } finally {
    client.release();
  }
};

// Generar preguntas para un capítulo (si no existen)
export const generarPreguntasPorCapitulo = async (req, res) => {
  const { idCapitulo } = req.params;
  const client = await pool.connect();
  try {
    const existQ = await client.query(
      `SELECT COUNT(*)::int AS cnt FROM pregunta WHERE id_capitulo = $1`,
      [idCapitulo]
    );
    if (existQ.rows[0].cnt > 0) {
      return res.json({ message: "Preguntas ya generadas.", generated: false });
    }

    const capEmb = await client.query(
      `SELECT contenido_texto FROM capitulo_embedding WHERE id_capitulo = $1`,
      [idCapitulo]
    );
    if (capEmb.rows.length === 0 || !capEmb.rows[0].contenido_texto) {
      return res.status(404).json({ mensaje: "Contenido del capítulo no disponible." });
    }

    const contenido = capEmb.rows[0].contenido_texto;

    const payload = { id_capitulo: Number(idCapitulo), contenido_texto: contenido };
    const iaResp = await fetch(`${IA_WORKER_URL}/generate_chapter`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!iaResp.ok) {
      const txt = await iaResp.text();
      console.error("IA Worker error:", iaResp.status, txt);
      return res.status(500).json({ mensaje: "Error desde el worker IA." });
    }

    const iaBody = await iaResp.json();
    const preguntas = iaBody.preguntas;
    if (!Array.isArray(preguntas) || preguntas.length === 0) {
      return res.status(500).json({ mensaje: "Worker IA no devolvió preguntas válidas." });
    }

    await client.query("BEGIN");
    const saved = [];

    for (const q of preguntas) {
      let tipoPregunta = 1;
      if (q.tipo === "falso_verdadero") tipoPregunta = 2;

      const pq = await client.query(
        `INSERT INTO pregunta (id_capitulo, nivel_comprension, enunciado, id_tipo_pregunta)
         VALUES ($1, $2, $3, $4) RETURNING id_pregunta`,
        [q.id_capitulo, q.nivel_comprension || null, q.enunciado, tipoPregunta]
      );
      const idPregunta = pq.rows[0].id_pregunta;

      if (tipoPregunta === 1) {
        for (const opt of q.opciones) {
          await client.query(
            `INSERT INTO opcion_multiple (id_pregunta, texto_opcion, opcion_correcta)
             VALUES ($1, $2, $3)`,
            [idPregunta, opt.texto_opcion, opt.opcion_correcta]
          );
        }
      } else if (tipoPregunta === 2) {
        await client.query(
          `INSERT INTO opcion_multiple (id_pregunta, texto_opcion, opcion_correcta)
           VALUES ($1, $2, $3), ($1, $4, $5)`,
          [
            idPregunta,
            "Verdadero", q.opciones[0].opcion_correcta === true,
            "Falso", q.opciones[0].opcion_correcta === false
          ]
        );
      }

      saved.push({ id_pregunta: idPregunta, enunciado: q.enunciado });
    }

    await client.query("COMMIT");
    return res.status(200).json({ message: "Preguntas generadas y guardadas.", generated: true, preguntas: saved });

  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    console.error("Error generando preguntas por capítulo:", error);
    return res.status(500).json({ mensaje: "Error interno generando preguntas." });
  } finally {
    client.release();
  }
};

// Obtener preguntas por capítulo (con opciones)
export const fetchPreguntasPorCapitulo = async (req, res) => {
  const { idCapitulo } = req.params;
  const client = await pool.connect();
  try {
    const q = `
      SELECT p.id_pregunta, p.nivel_comprension, p.enunciado,
        COALESCE(json_agg(json_build_object(
          'id_opcion_multiple', o.id_opcion_multiple,
          'texto_opcion', o.texto_opcion,
          'opcion_correcta', o.opcion_correcta
        ) ORDER BY o.id_opcion_multiple) FILTER (WHERE o.id_opcion_multiple IS NOT NULL), '[]') AS opciones
      FROM pregunta p
      LEFT JOIN opcion_multiple o ON o.id_pregunta = p.id_pregunta
      WHERE p.id_capitulo = $1
      GROUP BY p.id_pregunta, p.nivel_comprension, p.enunciado
      ORDER BY p.id_pregunta;
    `;
    const result = await client.query(q, [idCapitulo]);
    const preguntas = result.rows.map((r) => ({
      id_pregunta: r.id_pregunta,
      nivel_comprension: r.nivel_comprension,
      enunciado: r.enunciado,
      opciones: r.opciones || [],
    }));
    res.json({ preguntas });
  } catch (error) {
    console.error("Error fetching preguntas:", error);
    res.status(500).json({ mensaje: "Error interno." });
  } finally {
    client.release();
  }
};

// Envío de evaluación: guarda evaluación + respuestas
export const submitEvaluation = async (req, res) => {
  const { idLibro, idPerfil } = req.params;
  const { respuestas, minutosLeidos } = req.body;

  if (!Array.isArray(respuestas) || respuestas.length === 0) {
    return res.status(400).json({ mensaje: "Respuestas inválidas." });
  }

  const client = await pool.connect();

  try {
    console.log("✅ Iniciando submitEvaluation");
    await client.query("BEGIN");

    // Ver total de tests
    const totalTestRes = await client.query(
      `SELECT COUNT(*)::int AS total_test FROM capitulo WHERE id_libro = $1`,
      [idLibro]
    );
    const totalTest = totalTestRes.rows[0].total_test || 0;
    console.log("Total tests en libro:", totalTest);

    // Revisar si ya hay evaluación
    let idEvaluacion;
    let numeroIntentos = 1;
    let currentTestCompletados = 0;

    const existingEvalRes = await client.query(
      `SELECT id_evaluacion, numero_intentos, test_completados 
       FROM evaluacion 
       WHERE id_libro = $1 AND id_perfil = $2`,
      [idLibro, idPerfil]
    );

    if (existingEvalRes.rows.length > 0) {
      const evalRow = existingEvalRes.rows[0];
      idEvaluacion = evalRow.id_evaluacion;
      numeroIntentos = evalRow.numero_intentos + 1;
      currentTestCompletados = evalRow.test_completados;
      console.log("Evaluación existente:", idEvaluacion, "Intento:", numeroIntentos);
    } else {
      const insertEvalRes = await client.query(
        `INSERT INTO evaluacion
         (id_libro, id_perfil, puntaje_total, numero_intentos, tiempo_promedio_respuesta, total_test, test_completados, fecha_actualizacion)
         VALUES ($1, $2, 0, 1, '00:00:00'::interval, $3, 0, now())
         RETURNING id_evaluacion`,
        [idLibro, idPerfil, totalTest]
      );
      idEvaluacion = insertEvalRes.rows[0].id_evaluacion;
      console.log("Nueva evaluación creada:", idEvaluacion);
    }

    // Preguntas ya completadas
    const completedCapsRes = await client.query(
      `SELECT DISTINCT p.id_capitulo
       FROM respuesta_usuario ru
       INNER JOIN pregunta p ON p.id_pregunta = ru.id_pregunta
       WHERE ru.id_evaluacion = $1`,
      [idEvaluacion]
    );
    const completedCapIds = completedCapsRes.rows.map(r => r.id_capitulo);
    console.log("Capítulos completados previamente:", completedCapIds);

    // Procesar respuestas recibidas
    for (const r of respuestas) {
      const idPregunta = r.id_pregunta;
      const idOpcion = r.id_opcion_multiple || null;

      // Obtener el capítulo de la pregunta
      const capRes = await client.query(
        `SELECT id_capitulo FROM pregunta WHERE id_pregunta = $1`,
        [idPregunta]
      );
      const idCapitulo = capRes.rows[0].id_capitulo;

      // Solo aumentar completados si es un capítulo nuevo
      if (!completedCapIds.includes(idCapitulo)) {
        currentTestCompletados += 1;
        completedCapIds.push(idCapitulo);
      }

      // Revisar si la opción elegida es correcta
      let esCorrecta = false;
      let optRes = null;
      if (idOpcion) {
        const optQuery = await client.query(
          `SELECT opcion_correcta FROM opcion_multiple WHERE id_opcion_multiple = $1 AND id_pregunta = $2`,
          [idOpcion, idPregunta]
        );
        optRes = optQuery.rows[0];
        esCorrecta = !!optRes?.opcion_correcta;

        console.log("Procesando pregunta", idPregunta, "con opcion", idOpcion);
        console.log({ idPregunta, idOpcion, esCorrecta, optRes });
      } else {
        console.log("Pregunta", idPregunta, "sin opción seleccionada");
      }

      // Guardar respuesta
      await client.query(
        `INSERT INTO respuesta_usuario
         (id_evaluacion, id_pregunta, id_opcion_multiple, respuesta_texto, respuesta_correcta, tiempo_respuesta)
         VALUES ($1, $2, $3, $4, $5, '00:00:00'::interval)
         ON CONFLICT (id_evaluacion, id_pregunta)
         DO UPDATE SET
           id_opcion_multiple = EXCLUDED.id_opcion_multiple,
           respuesta_correcta = EXCLUDED.respuesta_correcta`,
        [idEvaluacion, idPregunta, idOpcion, null, esCorrecta]
      );
    }

    // Actualizar evaluación
    await client.query(
      `UPDATE evaluacion
       SET numero_intentos = $1,
           test_completados = $2,
           total_test = $3,
           fecha_actualizacion = now()
       WHERE id_evaluacion = $4`,
      [numeroIntentos, currentTestCompletados, totalTest, idEvaluacion]
    );

    // Calcular puntaje
    const puntajeRes = await client.query(
      `SELECT COUNT(*) FILTER (WHERE respuesta_correcta) AS correctas,
              COUNT(*) AS total
       FROM respuesta_usuario
       WHERE id_evaluacion = $1`,
      [idEvaluacion]
    );
    const correctas = puntajeRes.rows[0].correctas || 0;
    const total = puntajeRes.rows[0].total || 1;
    const porcentaje = Math.round((correctas * 100) / total);

    await client.query(
      `UPDATE evaluacion SET puntaje_total = $1 WHERE id_evaluacion = $2`,
      [porcentaje, idEvaluacion]
    );

    console.log("Evaluación procesada. Correctas:", correctas, "Total:", total, "Porcentaje:", porcentaje);

// ------------------------------
// Obtener resultados detallados para frontend
// ------------------------------
console.log("🔹 Obteniendo resultados finales para frontend...");

const resultadosRes = await client.query(`
  SELECT 
    ru.id_pregunta,
    ru.id_opcion_multiple AS seleccion_usuario,
    ru.respuesta_correcta AS correcta,
    om.id_opcion_multiple AS opcion_correcta
  FROM respuesta_usuario ru
  LEFT JOIN LATERAL (
    SELECT id_opcion_multiple
    FROM opcion_multiple
    WHERE id_pregunta = ru.id_pregunta AND opcion_correcta = true
    ORDER BY id_opcion_multiple ASC
    LIMIT 1
  ) om ON true
  WHERE ru.id_evaluacion = $1
`, [idEvaluacion]);

const resultados = resultadosRes.rows.map(r => {
  console.log(
    `Pregunta ${r.id_pregunta} -> seleccion_usuario: ${r.seleccion_usuario}, opcion_correcta: ${r.opcion_correcta}, correcta: ${r.correcta}`
  );
  return {
    id_pregunta: r.id_pregunta,
    seleccion_usuario: r.seleccion_usuario,
    opcion_correcta: r.opcion_correcta,
    correcta: r.correcta === true
  };
});

console.log("✅ Resultados finales procesados:", resultados);


    await client.query("COMMIT");
    
    // 🔥 Actualizar misiones del usuario
    await updateAllMissionProgress(idPerfil);

    return res.json({
      mensaje: "Evaluación registrada.",
      total,
      correctas,
      porcentaje,
      numeroIntentos,
      test_completados: currentTestCompletados,
      total_test: totalTest,
      resultados
    });

  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    console.error("Error submit evaluation:", error);
    return res.status(500).json({ mensaje: "Error interno." });
  } finally {
    client.release();
  }
};



// Obtener evaluaciones por perfil
export const getEvaluacionesPorPerfil = async (req, res) => {
  const { idPerfil } = req.params;
  const client = await pool.connect();

  try {
    const query = `
      SELECT e.id_evaluacion, e.id_libro, e.puntaje_total, e.numero_intentos,
             e.total_test, e.test_completados, e.fecha_actualizacion,
             l.titulo AS titulo_libro
      FROM evaluacion e
      INNER JOIN libro l ON l.id_libro = e.id_libro
      WHERE e.id_perfil = $1
      ORDER BY e.fecha_actualizacion DESC;
    `;

    const result = await client.query(query, [idPerfil]);

    return res.json({
      evaluaciones: result.rows
    });

  } catch (error) {
    console.error("Error obteniendo evaluaciones por perfil:", error);
    return res.status(500).json({ mensaje: "Error interno." });
  } finally {
    client.release();
  }
};
