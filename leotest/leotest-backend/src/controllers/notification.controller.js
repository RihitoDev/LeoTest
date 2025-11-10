// leotest-backend/src/controllers/notification.controller.js

import pool from "../db/connection.js";

const validateAndParseInt = (value, fieldName) => {
    const intValue = parseInt(value);
    if (isNaN(intValue)) {
        throw new Error(`El campo '${fieldName}' debe ser un número entero válido.`);
    }
    return intValue;
};

// NOTA: BASE DE DATOS INTERNA DE SIMULACIÓN
// En producción, esto interactuaría con una tabla 'notificacion' en PostgreSQL.
let notificationsDB = [
    { id: 1, id_usuario: 2, mensaje: "¡Tienes 3 misiones diarias nuevas!", fecha: "2025-11-09", tipo: "mision", estado: "no leída" },
    { id: 2, id_usuario: 2, mensaje: "El libro 'Astes ducorbre' está en tu lista de deseos.", fecha: "2025-11-07", tipo: "recordatorio", estado: "leída" },
    { id: 3, id_usuario: 2, mensaje: "Nuevo libro en la categoría Ciencia Ficción.", fecha: "2025-11-08", tipo: "nuevo libro", estado: "no leída" },
];


// =================================================================
// 1. OBTENER NOTIFICACIONES ACTIVAS POR USUARIO (HU-1.3)
// =================================================================
export const getNotifications = async (req, res) => {
    const { userId } = req.params;
    const userIdInt = validateAndParseInt(userId, 'userId');

    try {
        // En un sistema real, harías:
        // const query = "SELECT id, mensaje, fecha, tipo, estado FROM notificacion WHERE id_usuario = $1 ORDER BY fecha DESC";
        // const result = await pool.query(query, [userIdInt]);
        
        // Filtrar la simulación por el ID de usuario
        const userNotifications = notificationsDB.filter(n => n.id_usuario === userIdInt);
        
        const unreadCount = userNotifications.filter(n => n.estado === 'no leída').length;

        res.status(200).json({
            exito: true,
            notificaciones_no_leidas: unreadCount,
            notificaciones: userNotifications.sort((a, b) => new Date(b.fecha) - new Date(a.fecha))
        });
        
    } catch (error) {
        console.error("Error al obtener notificaciones:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al obtener notificaciones." });
    }
};

// =================================================================
// 2. MARCAR NOTIFICACIÓN COMO LEÍDA (HU-1.4)
// =================================================================
export const markAsRead = async (req, res) => {
    const { id_notificacion } = req.params;
    const idNotificacionInt = validateAndParseInt(id_notificacion, 'id_notificacion');
    
    try {
        // En un sistema real, harías:
        /*
        const updateQuery = `
            UPDATE notificacion
            SET estado = 'leída', fecha_leida = NOW()
            WHERE id_notificacion = $1 AND estado = 'no leída'
            RETURNING id;
        `;
        const result = await pool.query(updateQuery, [idNotificacionInt]);
        */

        // Lógica de simulación de actualización
        const notification = notificationsDB.find(n => n.id === idNotificacionInt);
        
        if (!notification) {
            return res.status(404).json({ mensaje: "Notificación no encontrada." });
        }
        
        if (notification.estado === 'no leída') {
            notification.estado = 'leída';
            
            // Re-ejecutar el endpoint (opcional, solo para debug si es necesario)
            // console.log(`Notificación ${id_notificacion} marcada como leída (simulado).`);
            
            return res.status(200).json({
                exito: true,
                mensaje: `Notificación ${id_notificacion} marcada como leída.`
            });
        }
        
        return res.status(200).json({
             exito: true,
             mensaje: `Notificación ${id_notificacion} ya estaba leída.`
        });
        
    } catch (error) {
        console.error("Error al marcar como leída:", error);
        res.status(500).json({ mensaje: "Error interno del servidor al marcar como leída." });
    }
};