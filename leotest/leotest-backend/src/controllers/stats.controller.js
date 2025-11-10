// leotest-backend/src/controllers/stats.controller.js

import pool from "../db/connection.js";

const validateAndParseInt = (value, fieldName) => {
    const intValue = parseInt(value);
    if (isNaN(intValue)) {
        throw new Error(`El campo '${fieldName}' debe ser un número entero válido.`);
    }
    return intValue;
};

// Función auxiliar para obtener el ID de Perfil a partir del ID de Usuario
async function getPerfilId(userIdInt, client) {
    const perfilResult = await client.query(
        "SELECT id_perfil FROM perfil WHERE id_usuario = $1",
        [userIdInt]
    );
    if (perfilResult.rows.length === 0) {
        throw new Error(`Perfil no encontrado para el usuario ${userIdInt}`);
    }
    return perfilResult.rows[0].id_perfil;
}


// =================================================================
// 1. OBTENER RACHA DE LECTURA (HU-3.2, HU-3.3)
// =================================================================
export const getCurrentStreak = async (req, res) => {
    const { userId } = req.params;
    let client;

    try {
        const userIdInt = validateAndParseInt(userId, 'userId');
        client = await pool.connect();
        
        // 🚨 PASO DE CORRECCIÓN: Obtener id_perfil para usar en la tabla 'evaluacion'
        const perfilIdInt = await getPerfilId(userIdInt, client);

        const rachaQuery = `
            WITH fechas_unicas AS (
                -- ✅ Corregido: Usar id_perfil
                SELECT DISTINCT (fecha_actualizacion::date) AS dia 
                FROM evaluacion
                WHERE id_perfil = $1 
            ),
            dias_consecutivos AS (
                SELECT
                    dia,
                    dia - (ROW_NUMBER() OVER (ORDER BY dia DESC) || ' day')::interval AS grupo_racha
                FROM fechas_unicas
                ORDER BY dia DESC
            ),
            racha_actual AS (
                SELECT 
                    COUNT(dia) AS racha_dias
                FROM dias_consecutivos
                WHERE grupo_racha = (
                    SELECT grupo_racha FROM dias_consecutivos ORDER BY dia DESC LIMIT 1
                )
            )
            SELECT COALESCE(r.racha_dias, 0) AS racha_actual
            FROM racha_actual r;
        `;
        
        // ✅ Corregido: Pasar id_perfil al query
        const result = await client.query(rachaQuery, [perfilIdInt]);
        const racha = result.rows[0]?.racha_actual || 0;

        res.status(200).json({
            exito: true,
            racha_actual: parseInt(racha)
        });

    } catch (error) {
        console.error("Error al obtener racha:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al calcular la racha." });
    } finally {
        if (client) client.release();
    }
};

// =================================================================
// 2. OBTENER ESTADÍSTICAS GENERALES (HU-3.4)
// =================================================================
export const getGeneralStats = async (req, res) => {
    const { userId } = req.params;
    let client;

    try {
        const userIdInt = validateAndParseInt(userId, 'userId');
        client = await pool.connect();

        // 🚨 PASO DE CORRECCIÓN: Obtener id_perfil
        const perfilIdInt = await getPerfilId(userIdInt, client);

        // --- 1. Obtener Métricas Estáticas ---
        const statsQuery = `
            SELECT 
                velocidad_lectura,
                libros_leidos,
                total_test_completados,
                porcentaje_aciertos
            FROM estadistica
            WHERE id_usuario = $1;
        `;
        const statsResult = await client.query(statsQuery, [userIdInt]);
        const stats = statsResult.rows[0] || {};
        
        // --- 2. Calcular Racha Dinámica (CORREGIDO) ---
        const rachaQuery = `
            WITH fechas_unicas AS (
                -- ✅ Corregido: Usar id_perfil
                SELECT DISTINCT (fecha_actualizacion::date) AS dia 
                FROM evaluacion
                WHERE id_perfil = $1
            ),
            dias_consecutivos AS (
                SELECT
                    dia,
                    dia - (ROW_NUMBER() OVER (ORDER BY dia DESC) || ' day')::interval AS grupo_racha
                FROM fechas_unicas
                ORDER BY dia DESC
            ),
            racha_actual AS (
                SELECT 
                    COUNT(dia) AS racha_dias
                FROM dias_consecutivos
                WHERE grupo_racha = (
                    SELECT grupo_racha FROM dias_consecutivos ORDER BY dia DESC LIMIT 1
                )
            )
            SELECT COALESCE(r.racha_dias, 0) AS racha_dias
            FROM racha_actual r;
        `;
        
        // ✅ Corregido: Pasar id_perfil al query
        const rachaResult = await client.query(rachaQuery, [perfilIdInt]);
        const racha = rachaResult.rows[0]?.racha_dias || 0;

        res.status(200).json({
            exito: true,
            estadisticas: {
                ...stats,
                racha_dias: parseInt(racha)
            }
        });

    } catch (error) {
        console.error("Error al obtener estadísticas generales:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al obtener estadísticas." });
    } finally {
        if (client) client.release();
    }
};