// leotest-backend/src/controllers/profile.controller.js
import pool from "../db/connection.js";

/**
 * GET /api/profile/user/:userId
 */
export const getProfileByUserId = async (req, res) => {
  const { userId } = req.params;
  try {
    const query = `
      SELECT 
        p.id_perfil, 
        p.id_usuario, 
        p.nombre_perfil, 
        p.edad, 
        p.fecha_creacion_perfil,
        p.fecha_ultima_sesion, 
        p.id_nivel_educativo, 
        p.imagen_perfil,
        ne.nombre_nivel_educativo,
        e.velocidad_lectura,
        e.porcentaje_aciertos
      FROM perfil p
      LEFT JOIN nivel_educativo ne 
        ON p.id_nivel_educativo = ne.id_nivel_educativo
      LEFT JOIN estadistica e 
        ON e.id_usuario = p.id_usuario
      WHERE p.id_usuario = $1
      LIMIT 1;
    `;
    
    const result = await pool.query(query, [userId]);

    if (result.rows.length === 0) {
      return res.status(204).json({ existe: false });
    }

    return res.status(200).json({ existe: true, perfil: result.rows[0] });
  } catch (error) {
    console.error("Error getProfileByUserId:", error);
    return res.status(500).json({ mensaje: "Error interno al obtener perfil." });
  }
};


/**
 * POST /api/profile
 */
export const createProfile = async (req, res) => {
  const { id_usuario, nombre_perfil, edad, id_nivel_educativo, imagen_perfil } = req.body;

  if (!id_usuario || !nombre_perfil) {
    return res.status(400).json({ mensaje: "id_usuario y nombre_perfil son requeridos." });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const insertQuery = `
      INSERT INTO perfil (
        id_usuario, nombre_perfil, edad, 
        fecha_creacion_perfil, fecha_ultima_sesion, 
        id_nivel_educativo, imagen_perfil
      )
      VALUES ($1, $2, $3, NOW()::date, NOW()::date, $4, $5)
      RETURNING id_perfil;
    `;

    const insertResult = await client.query(insertQuery, [
      id_usuario,
      nombre_perfil,
      edad || null,
      id_nivel_educativo || null,
      imagen_perfil || null,
    ]);

    // Inserta registro de estadística SIN columnas antiguas
    const statsUpsert = `
      INSERT INTO estadistica (id_usuario, velocidad_lectura, porcentaje_aciertos)
      VALUES ($1, 0, 0)
      ON CONFLICT (id_usuario) DO NOTHING;
    `;
    await client.query(statsUpsert, [id_usuario]);

    await client.query("COMMIT");

    return res.status(201).json({ 
      exito: true, 
      id_perfil: insertResult.rows[0].id_perfil 
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error createProfile:", error);
    return res.status(500).json({ mensaje: "Error interno al crear perfil." });
  } finally {
    client.release();
  }
};


/**
 * GET /api/profile/niveles
 */
export const getNivelesEducativos = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id_nivel_educativo, nombre_nivel_educativo 
       FROM nivel_educativo 
       ORDER BY id_nivel_educativo;`
    );

    return res.status(200).json({ niveles: result.rows });
  } catch (error) {
    console.error("Error getNivelesEducativos:", error);
    return res.status(500).json({ mensaje: "Error interno al obtener niveles." });
  }
};


/**
 * GET /api/profile/get-user-id/:profileId
 */
export const getUserIdFromProfile = async (req, res) => {
  const { profileId } = req.params;

  try {
    const result = await pool.query(
      `SELECT id_usuario FROM perfil WHERE id_perfil = $1 LIMIT 1;`,
      [profileId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ mensaje: "Perfil no encontrado." });
    }

    return res.status(200).json({ id_usuario: result.rows[0].id_usuario });
  } catch (error) {
    console.error("Error getUserIdFromProfile:", error);
    return res.status(500).json({ mensaje: "Error interno al obtener id_usuario." });
  }
};


/**
 * PUT /api/profile/update/:profileId
 */
export const updateProfile = async (req, res) => {
  const { profileId } = req.params;
  const { nombre_perfil, edad, id_nivel_educativo, imagen_perfil } = req.body;

  try {
    const query = `
      UPDATE perfil
      SET 
        nombre_perfil = $1, 
        edad = $2, 
        id_nivel_educativo = $3, 
        imagen_perfil = $4
      WHERE id_perfil = $5
      RETURNING *;
    `;

    const result = await pool.query(query, [
      nombre_perfil,
      edad,
      id_nivel_educativo,
      imagen_perfil,
      profileId
    ]);

    if (result.rowCount === 0) {
      return res.status(404).json({ mensaje: "Perfil no encontrado." });
    }

    return res.status(200).json({ exito: true, perfil: result.rows[0] });
  } catch (error) {
    console.error("Error updateProfile:", error);
    return res.status(500).json({ mensaje: "Error al actualizar perfil." });
  }
};


/**
 * DELETE /api/profile/delete/:profileId
 */
export const deleteProfile = async (req, res) => {
  const { profileId } = req.params;

  try {
    const result = await pool.query(
      "DELETE FROM perfil WHERE id_perfil = $1 RETURNING *;",
      [profileId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ mensaje: "Perfil no encontrado." });
    }

    return res.status(200).json({ exito: true });
  } catch (error) {
    console.error("Error deleteProfile:", error);
    return res.status(500).json({ mensaje: "Error al eliminar perfil." });
  }
};
