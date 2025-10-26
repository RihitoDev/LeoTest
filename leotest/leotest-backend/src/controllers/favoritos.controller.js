import pool from '../db/connection.js';

// Obtener favoritos de un perfil
export const obtenerFavoritos = async (req, res) => {
  const { id_perfil } = req.params;
  try {
    const { rows } = await pool.query(
      'SELECT id_libro FROM favoritos WHERE id_perfil = $1',
      [id_perfil]
    );
    const favoritos = rows.map(row => row.id_libro);
    res.json(favoritos);
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al obtener favoritos' });
  }
};

// Agregar favorito
export const agregarFavorito = async (req, res) => {
  const { id_perfil, id_libro } = req.body;
  try {
    await pool.query(
      'INSERT INTO favoritos (id_perfil, id_libro, fecha_favorito) VALUES ($1, $2, now())',
      [id_perfil, id_libro]
    );
    res.json({ mensaje: 'Favorito agregado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al agregar favorito' });
  }
};

// Quitar favorito
export const quitarFavorito = async (req, res) => {
  const { id_perfil, id_libro } = req.body;
  try {
    await pool.query(
      'DELETE FROM favoritos WHERE id_perfil = $1 AND id_libro = $2',
      [id_perfil, id_libro]
    );
    res.json({ mensaje: 'Favorito eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ mensaje: 'Error al eliminar favorito' });
  }
};
