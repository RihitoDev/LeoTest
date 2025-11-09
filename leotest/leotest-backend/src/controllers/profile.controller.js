import pool from "../db/connection.js";

export const getProfilesByUser = async (req, res) => {
  const { id_usuario } = req.params;
  try {
    const result = await pool.query(
      `SELECT p.id_perfil, p.nombre_perfil, p.edad, ne.nombre_nivel_educativo AS nivel_educativo, p.imagen_perfil
       FROM perfil p
       LEFT JOIN nivel_educativo ne ON p.id_nivel_educativo = ne.id_nivel_educativo
       WHERE p.id_usuario = $1`,
      [id_usuario]
    );

    return res.status(200).json({ perfiles: result.rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: "Error al obtener perfiles" });
  }
};

export const createProfile = async (req, res) => {
  const { id_usuario, nombre_perfil, edad, id_nivel_educativo, imagen_perfil } = req.body;

  try {
    await pool.query(
      `INSERT INTO perfil (id_usuario, nombre_perfil, edad, id_nivel_educativo, imagen_perfil, fecha_creacion_perfil, fecha_ultima_sesion)
       VALUES ($1,$2,$3,$4,$5, CURRENT_DATE, CURRENT_DATE)`,
      [id_usuario, nombre_perfil, edad, id_nivel_educativo, imagen_perfil]
    );

    res.status(201).json({ mensaje: "Perfil creado correctamente" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: "Error al crear perfil" });
  }
};
