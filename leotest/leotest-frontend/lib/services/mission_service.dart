// lib/services/mission_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/mission.dart';

class MissionService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/missions";
  static String get _currentUserId => AuthService.getCurrentUserId();

  /// Obtiene la lista de misiones activas para el usuario (HU-10.2).
  static Future<List<Mission>> fetchActiveMissions() async {
    final userId = _currentUserId;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['exito'] == true && data['misiones'] is List) {
          return (data['misiones'] as List)
              .map((json) => Mission.fromJson(json))
              .toList();
        }
      }
      print('Error al obtener misiones: HTTP ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error de conexión al obtener misiones: $e');
      return [];
    }
  }

  /// Marca una misión como completada (HU-10.4).
  static Future<bool> completeMission(int idUsuarioMision) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/complete/$idUsuarioMision'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      }
      print('Error al completar misión: HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error de conexión al completar misión: $e');
      return false;
    }
  }
}