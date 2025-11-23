// leotest-backend/src/controllers/stats.controller.js
import pool from "../db/connection.js";

const validateAndParseInt = (value, fieldName) => {
    const intValue = parseInt(value);
    if (isNaN(intValue)) {
        throw new Error(`El campo '${fieldName}' debe ser un número entero válido.`);
    }
    return intValue;
};

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
// 1. OBTENER RACHA DESDE lecturas_diarias
// =================================================================
export const getCurrentStreak = async (req, res) => {
  const { userId } = req.params;
  let client;

  try {
    const userIdInt = validateAndParseInt(userId, 'userId');
    client = await pool.connect();

    const perfilIdInt = await getPerfilId(userIdInt, client);

    const rachaQuery = `
      WITH fechas AS (
        SELECT DISTINCT fecha_lectura::date AS dia
        FROM lecturas_diarias
        WHERE id_perfil = $1
      ),
      consecutivos AS (
        SELECT dia,
               dia - (ROW_NUMBER() OVER (ORDER BY dia DESC) || ' day')::interval AS grupo
        FROM fechas
      )
      SELECT COALESCE(MAX(counts), 0) AS racha_actual FROM (
        SELECT COUNT(*) AS counts
        FROM consecutivos
        GROUP BY grupo
      ) AS sub;
    `;

    const result = await client.query(rachaQuery, [perfilIdInt]);
    const racha = result.rows[0]?.racha_actual ?? 0;

    res.status(200).json({ exito: true, racha_actual: parseInt(racha) });
  } catch (e) {
    console.error("Error obteniendo racha:", e);
    res.status(500).json({ error: "Error interno" });
  } finally {
    if (client) client.release();
  }
};

// =================================================================
// 2. ESTADÍSTICAS GENERALES (DATOS REALES)
// =================================================================
export const getGeneralStats = async (req, res) => {
    const { userId } = req.params;
    let client;

    try {
        const userIdInt = validateAndParseInt(userId, 'userId');
        client = await pool.connect();

        // Obtener id_perfil real
        const perfilIdInt = await getPerfilId(userIdInt, client);

        // -------------------------------------------------
        // 1) Velocidad y aciertos (tabla estadistica)
        // -------------------------------------------------
        const statsQuery = `
            SELECT 
                velocidad_lectura,
                porcentaje_aciertos
            FROM estadistica
            WHERE id_usuario = $1
            LIMIT 1;
        `;
        const statsResult = await client.query(statsQuery, [userIdInt]);
        const stats = statsResult.rows[0] || { velocidad_lectura: 0, porcentaje_aciertos: 0 };

        // -------------------------------------------------
        // 2) Libros leídos reales (CORREGIDO: progreso)
        // -------------------------------------------------
        const librosQuery = `
            SELECT COUNT(*) AS libros_leidos
            FROM progreso
            WHERE id_perfil = $1 AND estado = 'Completado';
        `;
        const librosResult = await client.query(librosQuery, [perfilIdInt]);
        const librosLeidos = parseInt(librosResult.rows[0].libros_leidos) || 0;

        // -------------------------------------------------
        // 3) Tests completados reales
        // -------------------------------------------------
        const testsQuery = `
            SELECT COUNT(*) AS test_completados
            FROM evaluacion
            WHERE id_perfil = $1;
        `;
        const testsResult = await client.query(testsQuery, [perfilIdInt]);
        const testCompletados = parseInt(testsResult.rows[0].test_completados) || 0;

        // -------------------------------------------------
        // 4) Racha real desde lecturas_diarias
        // -------------------------------------------------
        const rachaQuery = `
            WITH fechas AS (
                SELECT DISTINCT fecha_lectura::date AS dia
                FROM lecturas_diarias
                WHERE id_perfil = $1
            ),
            consecutivos AS (
                SELECT dia,
                       dia - (ROW_NUMBER() OVER (ORDER BY dia DESC) || ' day')::interval AS grupo
                FROM fechas
            )
            SELECT COALESCE(MAX(counts), 0) AS racha_dias FROM (
                SELECT COUNT(*) AS counts
                FROM consecutivos
                GROUP BY grupo
            ) AS sub;
        `;
        const rachaResult = await client.query(rachaQuery, [perfilIdInt]);
        const rachaDias = parseInt(rachaResult.rows[0]?.racha_dias || 0);
        // -------------------------------------------------
        // 5) Máximos reales
        // -------------------------------------------------
        const totalLibrosQuery = `
        SELECT COUNT(*) AS total_libros
        FROM progreso
        WHERE id_perfil = $1;
        `;
        const totalLibrosResult = await client.query(totalLibrosQuery, [perfilIdInt]);
        const totalLibros = parseInt(totalLibrosResult.rows[0]?.total_libros || 0);

        const totalTestsQuery = `
            SELECT COALESCE(SUM(total_test), 0) AS total_tests
            FROM evaluacion
            WHERE id_perfil = $1;
        `;
        const totalTestsResult = await client.query(totalTestsQuery, [perfilIdInt]);
        const totalTests = parseInt(totalTestsResult.rows[0]?.total_tests || 0);


        // -------------------------------------------------
        // RESPUESTA FINAL → EXACTA para StatsView
        // -------------------------------------------------
        res.status(200).json({
            velocidad_lectura: stats.velocidad_lectura || 0,
            porcentaje_aciertos: stats.porcentaje_aciertos || 0,
            libros_leidos: librosLeidos,
            total_libros: totalLibros,
            total_test_completados: testCompletados,
            total_tests: totalTests,
            racha_dias: rachaDias
        });


    } catch (error) {
        console.error("Error al obtener estadísticas generales:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al obtener estadísticas." });
    } finally {
        if (client) client.release();
    }
};
