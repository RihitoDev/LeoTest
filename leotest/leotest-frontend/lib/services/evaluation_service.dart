// lib/services/evaluation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EvaluationService {
  // 🔹 Cambia esta URL base por la de tu API real
  static const String baseUrl = "http://localhost:3000/api";

  /// Obtiene los capítulos de un libro
  static Future<Map<String, dynamic>> fetchChapters(int idLibro) async {
    final url = Uri.parse('$baseUrl/evaluacion/libro/$idLibro/capitulos');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        return {"success": true, "data": jsonDecode(resp.body)};
      } else {
        return {"success": false, "message": resp.body};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Genera preguntas para un capítulo (si aún no existen)
  static Future<Map<String, dynamic>> generarPreguntas(int idCapitulo) async {
    final url = Uri.parse('$baseUrl/evaluacion/capitulo/$idCapitulo/generar');
    try {
      final resp = await http.post(url);
      if (resp.statusCode == 200) {
        return {"success": true, "data": jsonDecode(resp.body)};
      } else {
        return {"success": false, "message": resp.body};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Obtiene las preguntas de un capítulo
  static Future<Map<String, dynamic>> fetchPreguntas(int idCapitulo) async {
    final url = Uri.parse('$baseUrl/evaluacion/capitulo/$idCapitulo/preguntas');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        return {"success": true, "data": jsonDecode(resp.body)};
      } else {
        return {"success": false, "message": resp.body};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Envía las respuestas de la evaluación
  static Future<Map<String, dynamic>> submitEvaluation({
    required int idLibro,
    required int idPerfil,
    required List<Map<String, dynamic>> respuestas,
    required int minutosLeidos,
  }) async {
    final url = Uri.parse(
      '$baseUrl/evaluacion/libro/$idLibro/perfil/$idPerfil/enviar',
    );
    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "respuestas": respuestas,
          "minutosLeidos": minutosLeidos, // 🔹 agregado
        }),
      );
      if (resp.statusCode == 200) {
        return {"success": true, "data": jsonDecode(resp.body)};
      } else {
        return {"success": false, "message": resp.body};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Obtiene todas las evaluaciones hechas por un perfil
  static Future<Map<String, dynamic>> fetchEvaluacionesPerfil(
    int idPerfil,
  ) async {
    final url = Uri.parse('$baseUrl/evaluacion/perfil/$idPerfil');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        return {"success": true, "data": jsonDecode(resp.body)};
      } else {
        return {"success": false, "message": resp.body};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
