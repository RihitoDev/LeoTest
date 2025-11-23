// leotest-backend/src/controllers/auth.controller.js

import pool from "../db/connection.js";
import { assignDailyMissions, assignUniqueMissions } from "./mission.controller.js";

// ===========================================
// AUX: Registrar usuario + rol + estadística
// ===========================================
const _registerUserAndDependencies = async (nombreUsuario, passwordHash, client) => {
    const userInsertQuery = `
        INSERT INTO usuario (nombre_usuario, contraseña, fecha_creacion_usuario)
        VALUES ($1, $2, NOW()::date)
        RETURNING id_usuario;
    `;
    const userResult = await client.query(userInsertQuery, [nombreUsuario, passwordHash]);
    const userId = userResult.rows[0].id_usuario;

    // Rol por defecto
    const roleQuery = `
        SELECT id_rol 
        FROM rol 
        WHERE nombre_rol ILIKE 'lector' OR nombre_rol ILIKE 'usuario';
    `;
    const roleResult = await client.query(roleQuery);
    const defaultRoleId = roleResult.rows[0]?.id_rol || 2;

    await client.query(
        `INSERT INTO usuario_rol (id_usuario, id_rol) VALUES ($1, $2)`,
        [userId, defaultRoleId]
    );

    // Estadística básica
    await client.query(
        `INSERT INTO estadistica (id_usuario, libros_leidos) VALUES ($1, 0)`,
        [userId]
    );

    return { userId, role: "usuario" };
};


// ==========================
// LOGIN
// ==========================
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

        const userIdStr = user.id_usuario.toString();

        // Asignación de misiones
        assignDailyMissions(userIdStr);
        assignUniqueMissions(userIdStr, "Mensuales");
        assignUniqueMissions(userIdStr, "Generales");

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


// ==========================
// REGISTRO
// ==========================
export const registrarUsuario = async (req, res) => {
    const { nombre_usuario, contraseña } = req.body;

    if (!nombre_usuario || !contraseña) {
        return res.status(400).json({ mensaje: "Usuario y contraseña son requeridos." });
    }

    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const userCheck = await client.query(
            `SELECT id_usuario FROM usuario WHERE nombre_usuario = $1`,
            [nombre_usuario]
        );

        if (userCheck.rows.length > 0) {
            await client.query("ROLLBACK");
            return res.status(409).json({ mensaje: "El nombre de usuario ya está en uso." });
        }

        const { userId, role } = await _registerUserAndDependencies(
            nombre_usuario,
            contraseña,
            client
        );

        assignUniqueMissions(userId.toString(), "Generales");
        assignUniqueMissions(userId.toString(), "Mensuales");

        await client.query("COMMIT");

        res.status(201).json({
            exito: true,
            mensaje: "Usuario registrado con éxito.",
            id_usuario: userId,
            rol: role
        });

    } catch (error) {
        await client.query("ROLLBACK");
        console.error("Error en registrarUsuario:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al registrar." });
    } finally {
        client.release();
    }
};


// ==========================
// CHANGE PASSWORD
// ==========================
export const changePassword = async (req, res) => {
    const { userId, currentPassword, newPassword } = req.body;

    if (!userId || !currentPassword || !newPassword) {
        return res.status(400).json({ mensaje: "Datos incompletos" });
    }

    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        const q = `SELECT contraseña FROM usuario WHERE id_usuario = $1`;
        const r = await client.query(q, [userId]);
        if (r.rows.length === 0) {
            await client.query("ROLLBACK");
            return res.status(404).json({ mensaje: "Usuario no encontrado" });
        }

        if (r.rows[0].contraseña !== currentPassword) {
            await client.query("ROLLBACK");
            return res.status(401).json({ mensaje: "Contraseña actual incorrecta" });
        }

        await client.query(
            `UPDATE usuario SET contraseña = $1 WHERE id_usuario = $2`,
            [newPassword, userId]
        );

        await client.query("COMMIT");
        res.status(200).json({ exito: true, mensaje: "Contraseña actualizada" });

    } catch (error) {
        await client.query("ROLLBACK");
        console.error("changePassword error:", error);
        res.status(500).json({ mensaje: "Error interno" });
    } finally {
        client.release();
    }
};


// ==========================
// UPDATE USERNAME
// ==========================
export const updateUsername = async (req, res) => {
    const { userId, newUsername } = req.body;

    if (!userId || !newUsername)
        return res.status(400).json({ mensaje: "Datos incompletos" });

    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const check = await client.query(
            `SELECT id_usuario FROM usuario WHERE nombre_usuario = $1`,
            [newUsername]
        );

        if (check.rows.length > 0) {
            await client.query("ROLLBACK");
            return res.status(409).json({ mensaje: "Nombre de usuario en uso" });
        }

        await client.query(
            `UPDATE usuario SET nombre_usuario = $1 WHERE id_usuario = $2`,
            [newUsername, userId]
        );

        await client.query("COMMIT");
        res.status(200).json({ exito: true, mensaje: "Nombre de usuario actualizado" });

    } catch (error) {
        await client.query("ROLLBACK");
        console.error("updateUsername error:", error);
        res.status(500).json({ mensaje: "Error interno" });
    } finally {
        client.release();
    }
};


// ==========================
// DELETE USER
// ==========================
export const deleteUser = async (req, res) => {
    const userId = parseInt(req.params.userId, 10);

    if (!userId)
        return res.status(400).json({ mensaje: "userId requerido" });

    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        await client.query(`DELETE FROM perfil WHERE id_usuario = $1`, [userId]);
        await client.query(`DELETE FROM estadistica WHERE id_usuario = $1`, [userId]);
        await client.query(`DELETE FROM usuario_rol WHERE id_usuario = $1`, [userId]);
        await client.query(`DELETE FROM usuario WHERE id_usuario = $1`, [userId]);

        await client.query("COMMIT");
        res.status(200).json({ exito: true, mensaje: "Usuario eliminado" });

    } catch (error) {
        await client.query("ROLLBACK");
        console.error("deleteUser error:", error);
        res.status(500).json({ mensaje: "Error interno" });
    } finally {
        client.release();
    }
};

// ==========================
// OBTENER NOMBRE DE USUARIO POR ID
// ==========================
export const getUsernameById = async (req, res) => {
    const userId = parseInt(req.params.userId, 10);

    if (!userId) {
        return res.status(400).json({ mensaje: "userId requerido" });
    }

    try {
        const result = await pool.query(
            `SELECT nombre_usuario FROM usuario WHERE id_usuario = $1`,
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ mensaje: "Usuario no encontrado" });
        }

        res.status(200).json({
            exito: true,
            nombre_usuario: result.rows[0].nombre_usuario
        });

    } catch (error) {
        console.error("getUsernameById error:", error);
        res.status(500).json({ mensaje: "Error interno del servidor" });
    }
};

