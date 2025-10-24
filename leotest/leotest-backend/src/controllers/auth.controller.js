import pool from "../db/connection.js";


export const loginUsuario = async (req, res) => {
    const { nombre_usuario, contraseña } = req.body;

    if (!nombre_usuario || !contraseña) {
        return res.status(400).json({ mensaje: "Usuario y contraseña son requeridos" });
    }

    try {
        const query = `
            SELECT 
                u.id_usuario, 
                u.nombre_usuario, 
                u.contraseña,
                r.nombre_rol
            FROM usuario u
            JOIN usuario_rol ur ON u.id_usuario = ur.id_usuario
            JOIN rol r ON ur.id_rol = r.id_rol
            WHERE u.nombre_usuario = $1;
        `;
        
        const result = await pool.query(query, [nombre_usuario]);
        
        if (result.rows.length === 0) {
            return res.status(401).json({ mensaje: "Usuario o contraseña incorrectos" });
        }

        const user = result.rows[0];

        if (user.contraseña !== contraseña) {
            return res.status(401).json({ mensaje: "Usuario o contraseña incorrectos" });
        }

        // Éxito: Devolver datos clave, incluyendo el rol
        res.status(200).json({
            exito: true,
            id_usuario: user.id_usuario,
            nombre_usuario: user.nombre_usuario,
            rol: user.nombre_rol 
        });

    } catch (error) {
        console.error("Error en loginUsuario:", error);
        res.status(500).json({ mensaje: "Error interno del servidor" });
    }
};