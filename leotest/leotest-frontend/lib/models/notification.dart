// lib/models/notification.dart

class AppNotification {
  final int id;
  final String mensaje;
  final String fecha;
  final String tipo; // 'mision', 'recordatorio', 'nuevo libro'
  final String estado; // 'leída', 'no leída'

  AppNotification({
    required this.id,
    required this.mensaje,
    required this.fecha,
    required this.tipo,
    required this.estado,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      mensaje: json['mensaje'] as String,
      fecha: json['fecha'] as String,
      tipo: json['tipo'] as String,
      estado: json['estado'] as String,
    );
  }
}