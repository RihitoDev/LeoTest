// lib/services/profile_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:leotest/models/perfil.dart';

class ProfileService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/profile";
  static String get _currentUserId => AuthService.getCurrentUserId();

  static Future<List<Perfil>> fetchProfiles() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/user/$_currentUserId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List perfiles = data['perfiles'];
      return perfiles.map((p) => Perfil.fromJson(p)).toList();
    } else {
      throw Exception('Error al obtener perfiles');
    }
  }

  static Future<bool> createProfile({
    required String nombrePerfil,
    required int edad,
    required int idNivelEducativo,
    String? imagenPerfil,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id_usuario": _currentUserId,
        "nombre_perfil": nombrePerfil,
        "edad": edad,
        "id_nivel_educativo": idNivelEducativo,
        "imagen_perfil": imagenPerfil,
      }),
    );

    return response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> fetchNivelesEducativos() async {
    final response = await http.get(
      Uri.parse("${dotenv.env['API_BASE']}/api/nivel_educativo"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data
          .map(
            (nivel) => {
              'id': nivel['id_nivel_educativo'],
              'nombre': nivel['nombre_nivel_educativo'],
            },
          )
          .toList();
    } else {
      throw Exception('Error al cargar niveles educativos');
    }
  }
}
