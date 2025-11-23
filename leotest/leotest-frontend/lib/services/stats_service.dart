// lib/services/stats_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// Modelo simplificado para la racha y stats generales
class GeneralStats {
  final int rachaDias;
  final double? velocidadLectura;
  final int? librosLeidos;
  final int? totalLibros;
  final int? totalTestCompletados;
  final int? totalTests;
  final double? porcentajeAciertos;

  GeneralStats({
    required this.rachaDias,
    this.velocidadLectura,
    this.librosLeidos,
    this.totalLibros,
    this.totalTestCompletados,
    this.totalTests,
    this.porcentajeAciertos,
  });
}

class StatsService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/stats";
  static String get _currentUserId => AuthService.getCurrentUserId();

  /// Obtiene solo la racha actual del usuario (HU-3.2, 3.3)
  static Future<int> fetchCurrentStreak() async {
    final userId = _currentUserId;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/racha/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['racha_actual'] as int? ?? 0;
      }
      print('Error al obtener racha: ${response.statusCode}');
      return 0;
    } catch (e) {
      print('Error de conexión al obtener racha: $e');
      return 0;
    }
  }

  /// Obtiene todas las estadísticas generales del usuario (HU-3.4)
  static Future<GeneralStats> fetchGeneralStats() async {
    final userId = _currentUserId;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/general/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GeneralStats(
          rachaDias: data['racha_dias'] as int? ?? 0,
          librosLeidos: data['libros_leidos'] as int? ?? 0,
          totalLibros: data['total_libros'] as int? ?? 0,
          totalTestCompletados: data['total_test_completados'] as int? ?? 0,
          totalTests: data['total_tests'] as int? ?? 0,
          velocidadLectura:
              double.tryParse(data['velocidad_lectura'].toString()) ?? 0,
          porcentajeAciertos:
              double.tryParse(data['porcentaje_aciertos'].toString()) ?? 0,
        );
      }
      print('Error al obtener stats generales: ${response.statusCode}');
      return GeneralStats(rachaDias: 0);
    } catch (e) {
      print('Error de conexión al obtener stats generales: $e');
      return GeneralStats(rachaDias: 0);
    }
  }

  /// Actualiza las estadísticas del usuario en el backend
  static Future<void> updateStats({
    required int userId,
    required int velocidadLectura,
    required int porcentajeAciertos,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update'), // <-- quitar $userId de la URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId, // <-- enviar userId en el body
          'velocidadLectura': velocidadLectura,
          'porcentajeAciertos': porcentajeAciertos,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Estadísticas actualizadas en backend");
      } else {
        print(
          "❌ Error al actualizar estadísticas: ${response.statusCode} | ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Error de conexión al actualizar estadísticas: $e");
    }
  }
}
