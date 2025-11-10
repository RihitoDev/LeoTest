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
 * Función auxiliar para obtener métricas totales del usuario necesarias para el progreso de misiones.
 * @param {number} userIdInt
 * @param {object} client - Cliente de pool de PostgreSQL
 * @returns {object} Métricas actuales del usuario.
 */
async function getMissionMetrics(userIdInt, client) {
    // Nota: Total de tests completados se asume que se actualiza en el controlador de Evaluación.
    const statsResult = await client.query(
        "SELECT total_test_completados FROM estadistica WHERE id_usuario = $1",
        [userIdInt]
    );
    
    // Obtener la página más alta leída por el usuario (para misiones de "Páginas Leídas")
    const progressResult = await client.query(
        "SELECT COALESCE(MAX(paginas_leidas), 0) as max_paginas FROM progreso WHERE id_usuario = $1",
        [userIdInt]
    );
    
    return {
        testsCompletados: statsResult.rows[0]?.total_test_completados ?? 0,
        maxPaginasLeidas: progressResult.rows[0]?.max_paginas ?? 0,
    };
}


// =================================================================
// 1. ASIGNACIÓN DE MISIONES (HU-10)
// =================================================================

/**
 * Asigna misiones diarias a un usuario si aún no las tiene asignadas hoy.
 */
export const assignDailyMissions = async (userId) => {
    const client = await pool.connect();
    try {
        const userIdInt = validateAndParseInt(userId, 'userId');

        const dailyMissionIdsQuery = `
            SELECT id_mision
            FROM mision
            WHERE LOWER(frecuencia) = 'diarias';
        `;
        const missionIdsResult = await client.query(dailyMissionIdsQuery);
        const dailyMissionIds = missionIdsResult.rows.map(row => row.id_mision);

        if (dailyMissionIds.length === 0) {
            console.log(`No hay misiones diarias configuradas para asignar al usuario ${userId}.`);
            return;
        }

        const checkAssignedQuery = `
            SELECT id_mision
            FROM usuario_mision
            WHERE id_usuario = $1
            AND id_mision = ANY($2::int[]) 
            AND fecha_asignacion_mision::date = NOW()::date;
        `;
        const checkResult = await client.query(checkAssignedQuery, [userIdInt, dailyMissionIds]);
        const alreadyAssignedIds = checkResult.rows.map(row => row.id_mision);
        
        const missionsToAssign = dailyMissionIds.filter(id => !alreadyAssignedIds.includes(id));
        
        if (missionsToAssign.length > 0) {
            const insertQuery = `
                INSERT INTO usuario_mision (id_usuario, id_mision, progreso_mision, mision_completa, fecha_asignacion_mision)
                SELECT $1, id, 0.0, FALSE, NOW()
                FROM UNNEST($2::int[]) AS id;
            `;
            await client.query(insertQuery, [userIdInt, missionsToAssign]);
            console.log(`✅ Asignadas ${missionsToAssign.length} misiones diarias al usuario ${userId}.`);
        } else {
            console.log(`Usuario ${userId} ya tiene asignadas las misiones diarias de hoy.`);
        }

    } catch (error) {
        console.error(`Error en la asignación diaria para el usuario ${userId}:`, error);
    } finally {
        client.release();
    }
};

/**
 * Asigna misiones que solo deben asignarse una vez (Generales) o una vez al mes (Mensuales).
 */
export const assignUniqueMissions = async (userId, frequency) => {
    const client = await pool.connect();
    try {
        const userIdInt = validateAndParseInt(userId, 'userId');
        const lowerFrequency = frequency.toLowerCase();

        const missionIdsQuery = `
            SELECT id_mision
            FROM mision
            WHERE LOWER(frecuencia) = $1;
        `;
        const missionIdsResult = await client.query(missionIdsQuery, [lowerFrequency]);
        const targetMissionIds = missionIdsResult.rows.map(row => row.id_mision);

        if (targetMissionIds.length === 0) {
            console.log(`No hay misiones de tipo ${frequency} configuradas.`);
            return;
        }

        let checkAssignedQuery;
        
        if (lowerFrequency === 'mensuales') {
            // Lógica Mensual: Asignada si existe una entrada ESTE MES
            checkAssignedQuery = `
                SELECT id_mision
                FROM usuario_mision
                WHERE id_usuario = $1
                AND id_mision = ANY($2::int[]) 
                AND EXTRACT(YEAR FROM fecha_asignacion_mision) = EXTRACT(YEAR FROM NOW())
                AND EXTRACT(MONTH FROM fecha_asignacion_mision) = EXTRACT(MONTH FROM NOW());
            `;
        } else if (lowerFrequency === 'generales') {
            // Lógica General: Asignada si existe CUALQUIER entrada (completada o no)
            checkAssignedQuery = `
                SELECT id_mision
                FROM usuario_mision
                WHERE id_usuario = $1
                AND id_mision = ANY($2::int[]); 
            `;
        } else {
            return; 
        }

        const checkResult = await client.query(checkAssignedQuery, [userIdInt, targetMissionIds]);
        const alreadyAssignedIds = checkResult.rows.map(row => row.id_mision);
        
        const missionsToAssign = targetMissionIds.filter(id => !alreadyAssignedIds.includes(id));
        
        if (missionsToAssign.length > 0) {
            const insertQuery = `
                INSERT INTO usuario_mision (id_usuario, id_mision, progreso_mision, mision_completa, fecha_asignacion_mision)
                SELECT $1, id, 0.0, FALSE, NOW()
                FROM UNNEST($2::int[]) AS id;
            `;
            await client.query(insertQuery, [userIdInt, missionsToAssign]);
            console.log(`✅ Asignadas ${missionsToAssign.length} misiones de tipo ${frequency} al usuario ${userId}.`);
        } else {
            console.log(`Usuario ${userId} ya tiene asignadas las misiones de tipo ${frequency} para el período actual.`);
        }

    } catch (error) {
        console.error(`Error en la asignación de ${frequency} para el usuario ${userId}:`, error);
    } finally {
        client.release();
    }
};

// =================================================================
// 2. ACTUALIZACIÓN DE PROGRESO (HU-10.3)
// =================================================================

/**
 * Escucha un evento de progreso (ej. leer página) y actualiza el progreso_mision para todas
 * las misiones abiertas.
 */
export const updateAllMissionProgress = async (userId) => {
    const userIdInt = validateAndParseInt(userId, 'userId');
    const client = await pool.connect();
    
    try {
        // 1. Obtener todas las misiones activas (no completadas) y sus objetivos
        const activeMissionsQuery = `
            SELECT
                um.id_usuario_mision,
                om.tipo_objetivo,
                om.cantidad_objetivo
            FROM usuario_mision um
            JOIN mision m ON um.id_mision = m.id_mision
            JOIN objetivo_mision om ON m.id_mision = om.id_mision
            WHERE um.id_usuario = $1 AND um.mision_completa = FALSE;
        `;
        const { rows: activeMissions } = await client.query(activeMissionsQuery, [userIdInt]);

        if (activeMissions.length === 0) {
            return;
        }

        // 2. Determinar las métricas actuales del usuario
        const metrics = await getMissionMetrics(userIdInt, client);

        // 3. Iterar y actualizar el progreso de cada misión
        for (const mission of activeMissions) {
            let newProgressValue = 0;
            let metricName = mission.tipo_objetivo;
            
            // Lógica de mapeo de métricas:
            if (metricName === 'Paginas Leídas') {
                newProgressValue = metrics.maxPaginasLeidas;
            } else if (metricName === 'Tests Completados') {
                newProgressValue = metrics.testsCompletados;
            }
            // (Aquí se añadiría la lógica para 'Tiempo de Lectura' o 'Racha Lograda' si se usa)

            // 4. Actualizar el progreso en la tabla usuario_mision
            // (Usamos un JOIN implícito para obtener el objetivo)
            const updateProgressQuery = `
                UPDATE usuario_mision um
                SET progreso_mision = LEAST($1, om.cantidad_objetivo), 
                    mision_completa = CASE WHEN $1 >= om.cantidad_objetivo THEN TRUE ELSE FALSE END,
                    fecha_completado_mision = CASE WHEN $1 >= om.cantidad_objetivo THEN NOW() ELSE NULL END
                FROM mision m
                JOIN objetivo_mision om ON m.id_mision = om.id_mision
                WHERE um.id_mision = m.id_mision
                  AND um.id_usuario_mision = $2;
            `;
            await client.query(updateProgressQuery, [newProgressValue, mission.id_usuario_mision]);
        }

    } catch (error) {
        console.error("Error al actualizar progreso de misiones:", error);
    } finally {
        client.release();
    }
};

// =================================================================
// 3. ENDPOINTS CRUD (HU-10.4)
// =================================================================

/**
 * Endpoint para obtener la lista de misiones activas (HU-10.2).
 */
export const getActiveMissions = async (req, res) => {
    const { userId } = req.params;

    try {
        const userIdInt = validateAndParseInt(userId, 'userId');

        const query = `
            SELECT
                um.id_usuario_mision,
                m.id_mision,
                m.nombre_mision,
                m.descripcion_mision,
                m.frecuencia,
                um.progreso_mision,
                um.mision_completa,
                om.tipo_objetivo,
                om.cantidad_objetivo
            FROM usuario_mision um
            JOIN mision m ON um.id_mision = m.id_mision
            JOIN objetivo_mision om ON m.id_mision = om.id_mision
            WHERE um.id_usuario = $1 
            -- Incluimos misiones mensuales/generales ya que son persistentes
            OR m.frecuencia ILIKE 'mensuales'
            OR m.frecuencia ILIKE 'generales' 
            ORDER BY m.frecuencia, um.fecha_asignacion_mision DESC;
        `;
        
        const result = await pool.query(query, [userIdInt]);

        res.status(200).json({
            exito: true,
            misiones: result.rows
        });

    } catch (error) {
        console.error("Error al obtener misiones activas:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al obtener misiones." });
    }
};

/**
 * Endpoint para marcar una misión como completada (disparado por el frontend).
 */
export const completeMission = async (req, res) => {
    const { id_usuario_mision } = req.params;
    
    try {
        const idMisionUsuarioInt = validateAndParseInt(id_usuario_mision, 'id_usuario_mision');

        const updateQuery = `
            UPDATE usuario_mision
            SET mision_completa = TRUE,
                fecha_completado_mision = NOW()
            WHERE id_usuario_mision = $1 AND mision_completa = FALSE
            RETURNING id_usuario_mision;
        `;

        const result = await pool.query(updateQuery, [idMisionUsuarioInt]);

        if (result.rowCount === 0) {
            return res.status(404).json({ mensaje: "Misión no encontrada o ya completada." });
        }

        // NOTA: La recompensa y la actualización de estadísticas (racha) se manejarían aquí.

        res.status(200).json({
            exito: true,
            mensaje: "Misión marcada como completada."
        });

    } catch (error) {
        console.error("Error al completar misión:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al completar misión." });
    }
};

/**
 * Endpoint de simulación de Worker para la asignación de misiones.
 */
export const workerAssignMissions = async (req, res) => {
    const { userId } = req.body;
    if (!userId) {
         return res.status(400).json({ mensaje: "userId es requerido para la simulación." });
    }
    
    try {
        await assignDailyMissions(userId);
        // También asignamos mensuales y generales si es la primera vez
        await assignUniqueMissions(userId, 'Mensuales');
        await assignUniqueMissions(userId, 'Generales');

        res.status(200).json({ exito: true, mensaje: `Intentando asignar misiones diarias a ${userId}.` });
    } catch (error) {
         res.status(500).json({ mensaje: "Error al simular la asignación." });
    }
}