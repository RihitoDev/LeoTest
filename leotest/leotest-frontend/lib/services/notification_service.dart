// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/notification.dart';

class NotificationService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/notifications";
  static String get _currentUserId => AuthService.getCurrentUserId();

  /// Obtiene todas las notificaciones del usuario (HU-1.3)
  static Future<List<AppNotification>> fetchNotifications() async {
    final userId = _currentUserId;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['notificaciones'] is List) {
          return (data['notificaciones'] as List)
              .map((json) => AppNotification.fromJson(json))
              .toList();
        }
      }
      print('Error al obtener notificaciones: HTTP ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error de conexión al obtener notificaciones: $e');
      return [];
    }
  }

  /// Marca una notificación específica como leída (HU-1.4)
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/read/$notificationId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      return false;
    }
  }
}