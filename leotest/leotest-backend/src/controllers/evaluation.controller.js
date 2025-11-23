// src/controllers/evaluation.controller.js
import pool from "../db/connection.js";
import fetch from "node-fetch";

const IA_WORKER_URL = process.env.IA_WORKER_URL || "http://localhost:8000/api/ia";

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
    // 1) Verificar si ya existen preguntas para este capítulo
    const existQ = await client.query(
      `SELECT COUNT(*)::int AS cnt FROM pregunta WHERE id_capitulo = $1`,
      [idCapitulo]
    );
    if (existQ.rows[0].cnt > 0) {
      return res.json({ message: "Preguntas ya generadas.", generated: false });
    }

    // 2) Obtener contenido_texto desde capitulo_embedding
    const capEmb = await client.query(
      `SELECT contenido_texto FROM capitulo_embedding WHERE id_capitulo = $1`,
      [idCapitulo]
    );

    if (capEmb.rows.length === 0 || !capEmb.rows[0].contenido_texto) {
      return res.status(404).json({ mensaje: "Contenido del capítulo no disponible." });
    }

    const contenido = capEmb.rows[0].contenido_texto;

    // 3) Llamar microservicio IA: POST /api/ia/generate_chapter
    const payload = {
      id_capitulo: Number(idCapitulo),
      contenido_texto: contenido
    };

    const iaResp = await fetch(`${IA_WORKER_URL}/generate_chapter`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      // timeout no nativo en node-fetch v2; puedes usar AbortController si requieres
    });

    if (!iaResp.ok) {
      const txt = await iaResp.text();
      console.error("IA Worker error:", iaResp.status, txt);
      return res.status(500).json({ mensaje: "Error desde el worker IA." });
    }

    const iaBody = await iaResp.json();
    const preguntas = iaBody.preguntas; // esperamos array

    if (!Array.isArray(preguntas) || preguntas.length === 0) {
      return res.status(500).json({ mensaje: "Worker IA no devolvió preguntas válidas." });
    }

    // 4) Guardar preguntas y opciones en transacción
    await client.query("BEGIN");
    const saved = [];
    for (const q of preguntas) {
      // Validaciones mínimas
      if (!q.id_capitulo || !q.enunciado || !Array.isArray(q.opciones)) {
        console.warn("Pregunta inválida del worker, saltando:", q);
        continue;
      }
      const preguntaQuery = `
        INSERT INTO pregunta (id_capitulo, nivel_comprension, enunciado)
        VALUES ($1, $2, $3) RETURNING id_pregunta;
      `;
      const pq = await client.query(preguntaQuery, [
        q.id_capitulo,
        q.nivel_comprension || null,
        q.enunciado,
      ]);
      const idPregunta = pq.rows[0].id_pregunta;

      for (const opt of q.opciones) {
        if (typeof opt.texto_opcion === "undefined" || typeof opt.opcion_correcta === "undefined") {
          console.warn("Opción inválida para pregunta", idPregunta, opt);
          continue;
        }
        const opcionQ = `
          INSERT INTO opcion_multiple (id_pregunta, texto_opcion, opcion_correcta)
          VALUES ($1, $2, $3);
        `;
        await client.query(opcionQ, [idPregunta, opt.texto_opcion, opt.opcion_correcta]);
      }
      saved.push({ id_pregunta: idPregunta, enunciado: q.enunciado });
    }
    await client.query("COMMIT");

    return res.status(200).json({ message: "Preguntas generadas y guardadas.", generated: true, preguntas: saved });
  } catch (error) {
    await client.query("ROLLBACK").catch(()=>{});
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


// Envío de evaluación: guarda evaluacion + respuestas (respuesta_usuario)
export const submitEvaluation = async (req, res) => {
  const { idLibro, idPerfil } = req.params;
  const { respuestas } = req.body; // array { id_pregunta, id_opcion_multiple }

  if (!Array.isArray(respuestas) || respuestas.length === 0) {
    return res.status(400).json({ mensaje: "Respuestas inválidas." });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // 1) Crear registro en evaluacion
    // Para simplificar: puntaje_total y numero_intentos se calculan y se actualizan según tu lógica de negocio
    const insertEvalQ = `
      INSERT INTO evaluacion (id_libro, id_perfil, puntaje_total, numero_intentos, tiempo_promedio_respuesta, total_test, test_completados, fecha_actualizacion)
      VALUES ($1, $2, 0, 1, '00:00:00'::interval, $3, 1, now())
      RETURNING id_evaluacion;
    `;
    const totalPregs = respuestas.length;
    const evalRes = await client.query(insertEvalQ, [idLibro, idPerfil, totalPregs]);
    const idEvaluacion = evalRes.rows[0].id_evaluacion;

    // 2) Guardar cada respuesta y contar correctas
    let correctas = 0;
    for (const r of respuestas) {
      const idPregunta = r.id_pregunta;
      const idOpcion = r.id_opcion_multiple || null;

      let esCorrecta = false;
      if (idOpcion) {
        const optQ = await client.query(
          `SELECT opcion_correcta FROM opcion_multiple WHERE id_opcion_multiple = $1 AND id_pregunta = $2`,
          [idOpcion, idPregunta]
        );
        if (optQ.rows.length > 0 && optQ.rows[0].opcion_correcta === true) {
          esCorrecta = true;
          correctas++;
        }
      }

      await client.query(
        `INSERT INTO respuesta_usuario (id_evaluacion, id_pregunta, id_opcion_multiple, respuesta_texto, respuesta_correcta, tiempo_respuesta)
         VALUES ($1, $2, $3, $4, $5, '00:00:00'::interval)`,
        [idEvaluacion, idPregunta, idOpcion, null, esCorrecta]
      );
    }

    // 3) Actualizar puntaje_total en evaluacion (opcional)
    const porcentaje = totalPregs > 0 ? (correctas * 100) / totalPregs : 0;
    await client.query(
      `UPDATE evaluacion SET puntaje_total = $1, fecha_actualizacion = now() WHERE id_evaluacion = $2`,
      [Math.round(porcentaje), idEvaluacion]
    );

    await client.query("COMMIT");

    return res.json({ mensaje: "Evaluación registrada.", total: totalPregs, correctas, porcentaje });
  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    console.error("Error submit evaluation:", error);
    return res.status(500).json({ mensaje: "Error interno." });
  } finally {
    client.release();
  }
};
