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
  final int? totalTestCompletados;
  final double? porcentajeAciertos;

  GeneralStats({
    required this.rachaDias,
    this.velocidadLectura,
    this.librosLeidos,
    this.totalTestCompletados,
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
        final stats = data['estadisticas'] as Map<String, dynamic>;

        return GeneralStats(
          rachaDias: stats['racha_dias'] as int? ?? 0,
          librosLeidos: stats['libros_leidos'] as int? ?? 0,
          totalTestCompletados: stats['total_test_completados'] as int? ?? 0,
          velocidadLectura: (stats['velocidad_lectura'] as num?)?.toDouble(),
          porcentajeAciertos: (stats['porcentaje_aciertos'] as num?)?.toDouble(),
        );
      }
      print('Error al obtener stats generales: ${response.statusCode}');
      return GeneralStats(rachaDias: 0);
    } catch (e) {
      print('Error de conexión al obtener stats generales: $e');
      return GeneralStats(rachaDias: 0);
    }
  }
}