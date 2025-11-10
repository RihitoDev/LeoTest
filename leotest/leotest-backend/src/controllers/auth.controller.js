// leotest-backend/src/controllers/auth.controller.js

import pool from "../db/connection.js";
import { assignDailyMissions, assignUniqueMissions } from "./mission.controller.js";


// Función auxiliar para registrar usuario, perfil y asignar rol
const _registerUserAndDependencies = async (nombreUsuario, passwordHash, email, edad, nivelEducativoId, client) => {
    // 1. Insertar en tabla usuario
    const userInsertQuery = `
        INSERT INTO usuario (nombre_usuario, contraseña, fecha_creacion_usuario)
        VALUES ($1, $2, NOW()::date)
        RETURNING id_usuario;
    `;
    const userResult = await client.query(userInsertQuery, [nombreUsuario, passwordHash]);
    const userId = userResult.rows[0].id_usuario;

    // 2. Asignar ROL por defecto (Buscamos 'Lector' o 'Usuario')
    const roleQuery = `SELECT id_rol FROM rol WHERE nombre_rol ILIKE 'lector' OR nombre_rol ILIKE 'usuario'`;
    const roleResult = await client.query(roleQuery);
    const defaultRoleId = roleResult.rows[0]?.id_rol || 2; 

    const userRoleInsertQuery = `
        INSERT INTO usuario_rol (id_usuario, id_rol)
        VALUES ($1, $2);
    `;
    await client.query(userRoleInsertQuery, [userId, defaultRoleId]);

    // 3. Insertar en tabla perfil
    const profileInsertQuery = `
        INSERT INTO perfil (id_usuario, nombre_perfil, edad, fecha_creacion_perfil, fecha_ultima_sesion, id_nivel_educativo)
        VALUES ($1, $2, $3, NOW()::date, NOW()::date, $4)
        RETURNING id_perfil;
    `;
    await client.query(profileInsertQuery, [userId, nombreUsuario, edad || 25, nivelEducativoId || 1]);
    
    // 4. Crear registro de estadísticas vacío
    const statsInsertQuery = `
        INSERT INTO estadistica (id_usuario, libros_leidos)
        VALUES ($1, 0);
    `;
    await client.query(statsInsertQuery, [userId]);

    return { userId, role: 'usuario' };
}


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
        
        // DISPARAR ASIGNACIÓN DE MISIONES ASÍNCRONA:
        const userIdString = user.id_usuario.toString();
        
        assignDailyMissions(userIdString); 
        assignUniqueMissions(userIdString, 'Mensuales');
        assignUniqueMissions(userIdString, 'Generales');
        
        console.log(`Disparando chequeo de misiones para usuario ${user.id_usuario}`);

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


export const registrarUsuario = async (req, res) => {
    const { nombre_completo, nombre_usuario, contraseña, email } = req.body;

    if (!nombre_completo || !nombre_usuario || !contraseña || !email) {
        return res.status(400).json({ mensaje: "Todos los campos (nombre, usuario, contraseña, email) son requeridos." });
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN'); 

        const userCheck = await client.query('SELECT id_usuario FROM usuario WHERE nombre_usuario = $1', [nombre_usuario]);
        if (userCheck.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ mensaje: "El nombre de usuario ya está en uso." });
        }
        
        const edadDefault = 25; 
        const nivelEducativoDefaultId = 1; 

        const { userId, role } = await _registerUserAndDependencies(
            nombre_usuario, 
            contraseña, 
            email, 
            edadDefault, 
            nivelEducativoDefaultId, 
            client
        );
        
        assignUniqueMissions(userId.toString(), 'Generales'); 
        assignUniqueMissions(userId.toString(), 'Mensuales');
        
        await client.query('COMMIT'); 

        res.status(201).json({
            exito: true,
            mensaje: "Usuario registrado con éxito. Puede iniciar sesión.",
            id_usuario: userId,
            rol: role
        });

    } catch (error) {
        await client.query('ROLLBACK'); 
        console.error("Error en registrarUsuario:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al registrar." });
    } finally {
        client.release();
    }
};