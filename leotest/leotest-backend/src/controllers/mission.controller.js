// leotest-backend/src/controllers/mission.controller.js
import pool from "../db/connection.js";

const validateAndParseInt = (value, fieldName) => {
  const intValue = parseInt(value);
  if (isNaN(intValue)) {
    throw new Error(`El campo '${fieldName}' debe ser un número entero válido.`);
  }
  return intValue;
};

// =================================================================
// Funciones Auxiliares de Estadísticas para el Progreso de Misiones
// =================================================================

/**
 * Función auxiliar para obtener métricas totales del perfil necesarias para el progreso de misiones.
 * @param {number} perfilIdInt
 * @param {object} client - Cliente de pool de PostgreSQL
 * @returns {object} Métricas actuales del perfil.
 */
async function getMissionMetrics(perfilIdInt, client) {
  // Obtener el total de tests completados del perfil
  const evalResult = await client.query(
    `SELECT test_completados 
     FROM evaluacion
     WHERE id_perfil = $1
     ORDER BY fecha_actualizacion DESC
     LIMIT 1`,
    [perfilIdInt]
  );

  const progressResult = await client.query(
    `SELECT COALESCE(MAX(paginas_leidas), 0) as max_paginas
     FROM progreso
     WHERE id_perfil = $1`,
    [perfilIdInt]
  );

  return {
    testsCompletados: evalResult.rows[0]?.test_completados ?? 0,
    maxPaginasLeidas: progressResult.rows[0]?.max_paginas ?? 0,
  };
}

// =================================================================
// 1. ASIGNACIÓN DE MISIONES
// =================================================================

export const assignDailyMissions = async (perfilId) => {
  const client = await pool.connect();
  try {
    const perfilIdInt = validateAndParseInt(perfilId, 'perfilId');

    const dailyMissionIdsQuery = `SELECT id_mision FROM mision WHERE LOWER(frecuencia) = 'diarias';`;
    const missionIdsResult = await client.query(dailyMissionIdsQuery);
    const dailyMissionIds = missionIdsResult.rows.map(row => row.id_mision);

    if (dailyMissionIds.length === 0) return;

    const checkAssignedQuery = `
      SELECT id_mision 
      FROM usuario_mision 
      WHERE id_perfil = $1 
        AND id_mision = ANY($2::int[]) 
        AND fecha_asignacion_mision::date = NOW()::date;
    `;
    const checkResult = await client.query(checkAssignedQuery, [perfilIdInt, dailyMissionIds]);
    const alreadyAssignedIds = checkResult.rows.map(row => row.id_mision);
    const missionsToAssign = dailyMissionIds.filter(id => !alreadyAssignedIds.includes(id));

    console.log(`Perfil ${perfilIdInt}: Misiones diarias a asignar ->`, missionsToAssign);
    console.log(`Perfil ${perfilIdInt}: Misiones diarias ya asignadas hoy ->`, alreadyAssignedIds);

    if (missionsToAssign.length > 0) {
      const insertQuery = `
        INSERT INTO usuario_mision (id_perfil, id_mision, progreso_mision, mision_completa, fecha_asignacion_mision)
        SELECT $1, id, 0.0, FALSE, NOW() 
        FROM UNNEST($2::int[]) AS id;
      `;
      await client.query(insertQuery, [perfilIdInt, missionsToAssign]);
    }
  } catch (error) {
    console.error(`Error en asignación diaria para el perfil ${perfilId}:`, error);
  } finally {
    client.release();
  }
};

export const assignUniqueMissions = async (perfilId, frequency) => {
  const client = await pool.connect();
  try {
    const perfilIdInt = validateAndParseInt(perfilId, 'perfilId');
    const lowerFrequency = frequency.toLowerCase();

    const missionIdsQuery = `SELECT id_mision FROM mision WHERE LOWER(frecuencia) = $1;`;
    const missionIdsResult = await client.query(missionIdsQuery, [lowerFrequency]);
    const targetMissionIds = missionIdsResult.rows.map(row => row.id_mision);

    if (targetMissionIds.length === 0) return;

    let checkAssignedQuery;
    if (lowerFrequency === 'mensuales') {
      checkAssignedQuery = `
        SELECT id_mision 
        FROM usuario_mision 
        WHERE id_perfil = $1 
          AND id_mision = ANY($2::int[])
          AND EXTRACT(YEAR FROM fecha_asignacion_mision) = EXTRACT(YEAR FROM NOW())
          AND EXTRACT(MONTH FROM fecha_asignacion_mision) = EXTRACT(MONTH FROM NOW());
      `;
    } else if (lowerFrequency === 'generales') {
      checkAssignedQuery = `
        SELECT id_mision 
        FROM usuario_mision 
        WHERE id_perfil = $1 
          AND id_mision = ANY($2::int[]);
      `;
    } else return;

    const checkResult = await client.query(checkAssignedQuery, [perfilIdInt, targetMissionIds]);
    const alreadyAssignedIds = checkResult.rows.map(row => row.id_mision);
    const missionsToAssign = targetMissionIds.filter(id => !alreadyAssignedIds.includes(id));

    console.log(`Perfil ${perfilIdInt}: Misiones ${frequency} a asignar ->`, missionsToAssign);
    console.log(`Perfil ${perfilIdInt}: Misiones ${frequency} ya asignadas ->`, alreadyAssignedIds);

    if (missionsToAssign.length > 0) {
      const insertQuery = `
        INSERT INTO usuario_mision (id_perfil, id_mision, progreso_mision, mision_completa, fecha_asignacion_mision)
        SELECT $1, id, 0.0, FALSE, NOW()
        FROM UNNEST($2::int[]) AS id;
      `;
      await client.query(insertQuery, [perfilIdInt, missionsToAssign]);
    }
  } catch (error) {
    console.error(`Error en asignación de ${frequency} para el perfil ${perfilId}:`, error);
  } finally {
    client.release();
  }
};

// =================================================================
// 2. ACTUALIZACIÓN DE PROGRESO
// =================================================================

export const updateAllMissionProgress = async (perfilId) => {
  const perfilIdInt = validateAndParseInt(perfilId, 'perfilId');
  const client = await pool.connect();
  try {
    const activeMissionsQuery = `
      SELECT id_usuario_mision, id_mision 
      FROM usuario_mision 
      WHERE id_perfil = $1 AND mision_completa = FALSE;
    `;
    const { rows: activeMissions } = await client.query(activeMissionsQuery, [perfilIdInt]);
    if (activeMissions.length === 0) return;

    const metrics = await getMissionMetrics(perfilIdInt, client);

    for (const mission of activeMissions) {
      const objetivoQuery = `
        SELECT tipo_objetivo, cantidad_objetivo 
        FROM objetivo_mision 
        WHERE id_mision = $1;
      `;
      const { rows: objetivos } = await client.query(objetivoQuery, [mission.id_mision]);

      let progresoMax = 0;
      for (const objetivo of objetivos) {
        let progresoActual = 0;
        if (objetivo.tipo_objetivo === 'Tests Completados') progresoActual = metrics.testsCompletados;
        else if (objetivo.tipo_objetivo === 'Paginas Leídas') progresoActual = metrics.maxPaginasLeidas;
        progresoMax = Math.max(progresoMax, Math.min(progresoActual, objetivo.cantidad_objetivo));
      }

      const misionCompleta = objetivos.every(obj => {
        let valor = 0;
        if (obj.tipo_objetivo === 'Tests Completados') valor = metrics.testsCompletados;
        else if (obj.tipo_objetivo === 'Paginas Leídas') valor = metrics.maxPaginasLeidas;
        return valor >= obj.cantidad_objetivo;
      });

      const updateQuery = `
        UPDATE usuario_mision 
        SET progreso_mision = $1, mision_completa = $2, 
            fecha_completado_mision = CASE WHEN $2 THEN NOW() ELSE fecha_completado_mision END
        WHERE id_usuario_mision = $3;
      `;
      await client.query(updateQuery, [progresoMax, misionCompleta, mission.id_usuario_mision]);
    }
  } catch (error) {
    console.error("Error al actualizar progreso de misiones:", error);
  } finally {
    client.release();
  }
};

// =================================================================
// 3. ENDPOINTS CRUD
// =================================================================

export const getActiveMissions = async (req, res) => {
  const { profileId } = req.params;

  try {
    const profileIdInt = validateAndParseInt(profileId, 'perfilId');

    const query = `
      SELECT um.id_usuario_mision, m.id_mision, m.nombre_mision, m.descripcion_mision,
             m.frecuencia, um.progreso_mision, um.mision_completa,
             om.tipo_objetivo, om.cantidad_objetivo
      FROM usuario_mision um
      JOIN mision m ON um.id_mision = m.id_mision
      JOIN objetivo_mision om ON m.id_mision = om.id_mision
      WHERE um.id_perfil = $1
      ORDER BY m.frecuencia, um.fecha_asignacion_mision DESC;
    `;

    const result = await pool.query(query, [profileIdInt]);
    res.status(200).json({ exito: true, misiones: result.rows });
  } catch (error) {
    console.error("Error al obtener misiones activas:", error);
    res.status(500).json({ mensaje: "Error interno del servidor al obtener misiones." });
  }
};


export const completeMission = async (req, res) => {
  const { id_usuario_mision } = req.params;
  try {
    const idMisionUsuarioInt = validateAndParseInt(id_usuario_mision, 'id_usuario_mision');
    const updateQuery = `
      UPDATE usuario_mision 
      SET mision_completa = TRUE, fecha_completado_mision = NOW()
      WHERE id_usuario_mision = $1 AND mision_completa = FALSE
      RETURNING id_usuario_mision;
    `;
    const result = await pool.query(updateQuery, [idMisionUsuarioInt]);
    if (result.rowCount === 0) {
      return res.status(404).json({ mensaje: "Misión no encontrada o ya completada." });
    }
    res.status(200).json({ exito: true, mensaje: "Misión marcada como completada." });
  } catch (error) {
    console.error("Error al completar misión:", error);
    res.status(500).json({ mensaje: "Error interno del servidor al completar misión." });
  }
};

export const workerAssignMissions = async (req, res) => {
  const { perfilId, isNewUser = false } = req.body;
  if (!perfilId) return res.status(400).json({ mensaje: "perfilId es requerido." });
  try {
    await assignDailyMissions(perfilId);
    await assignUniqueMissions(perfilId, 'Mensuales');
    if (isNewUser) await assignUniqueMissions(perfilId, 'Generales');
    res.status(200).json({ exito: true, mensaje: `Misiones asignadas al perfil ${perfilId}.` });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: "Error al asignar misiones." });
  }
};
