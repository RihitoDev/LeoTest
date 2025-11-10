// leotest-backend/src/controllers/profile.controller.js

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
// 1. OBTENER DATOS COMPLETOS DEL PERFIL Y ESTADÍSTICAS (HU-11.2)
// =================================================================
export const getProfileData = async (req, res) => {
    const { userId } = req.params;
    let client; // Declaring client outside try block

    try {
        const userIdInt = validateAndParseInt(userId, 'userId');
        client = await pool.connect(); // Get client from pool

        // 1. Obtener id_perfil
        const perfilIdInt = await getPerfilId(userIdInt, client);

        // 2. Consulta principal (Datos de Usuario, Perfil y Estadísticas Estáticas)
        const profileQuery = `
            SELECT 
                u.nombre_usuario,
                p.nombre_perfil,
                p.edad,
                p.fecha_creacion_perfil,
                ne.nombre_nivel_educativo AS nivel_educativo,
                e.velocidad_lectura,
                e.libros_leidos,
                e.total_test_completados,
                e.porcentaje_aciertos
            FROM usuario u
            JOIN perfil p ON u.id_usuario = p.id_usuario
            LEFT JOIN nivel_educativo ne ON p.id_nivel_educativo = ne.id_nivel_educativo
            LEFT JOIN estadistica e ON u.id_usuario = e.id_usuario
            WHERE u.id_usuario = $1;
        `;
        
        const profileResult = await client.query(profileQuery, [userIdInt]);
        
        if (profileResult.rows.length === 0) {
            return res.status(404).json({ mensaje: "Perfil de usuario no encontrado." });
        }

        const profile = profileResult.rows[0];
        
        // 3. Cálculo de Racha (Usa id_perfil para la tabla 'evaluacion')
        const rachaQuery = `
            WITH fechas_unicas AS (
                SELECT DISTINCT (fecha_actualizacion::date) AS dia 
                FROM evaluacion
                WHERE id_perfil = $1  -- <<-- USO CORRECTO DE id_perfil
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
        
        // Ejecutar rachaQuery usando id_perfil
        const rachaResult = await client.query(rachaQuery, [perfilIdInt]);
        const racha = rachaResult.rows[0]?.racha_dias || 0;
        
        // 4. Devolver resultado combinado
        res.status(200).json({
            exito: true,
            datos_perfil: {
                ...profile,
                racha_dias: parseInt(racha),
            }
        });

    } catch (error) {
        console.error("Error al obtener datos del perfil:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al obtener datos del perfil." });
    } finally {
        if (client) client.release(); // Always release the client
    }
};