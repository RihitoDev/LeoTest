// lib/services/profile_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class UserProfileData {
  final int? idPerfil;
  final String nombreUsuario;
  final String nombrePerfil;
  final String email;
  final int edad;
  final String nivelEducativo;
  final int rachaDias;
  final int librosLeidos;
  final double? porcentajeAciertos;
  final String? imagenPerfil; // URL
  UserProfileData({
    this.idPerfil,
    required this.nombreUsuario,
    required this.nombrePerfil,
    required this.email,
    required this.edad,
    required this.nivelEducativo,
    required this.rachaDias,
    required this.librosLeidos,
    this.porcentajeAciertos,
    this.imagenPerfil,
  });
}

class NivelEducativo {
  final int id;
  final String nombre;
  NivelEducativo({required this.id, required this.nombre});
}

class ProfileService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/profile";
  static String get _currentUserId => AuthService.getCurrentUserId();
  static const String SIMULATED_EMAIL = "usuario@leotest.com";

  /// Obtiene perfil por idUsuario (para saber si existe y traer id_perfil)
  static Future<UserProfileData?> fetchProfileForUser(String userId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/user/$userId"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['existe'] == true) {
          final p = body['perfil'];
          double? porcentaje = (p['porcentaje_aciertos'] is String)
              ? double.tryParse(p['porcentaje_aciertos'])
              : (p['porcentaje_aciertos'] as num?)?.toDouble();
          return UserProfileData(
            idPerfil: p['id_perfil'] as int?,
            nombreUsuario:
                p['nombre_perfil'] ?? p['nombre_usuario'] ?? "Usuario",
            nombrePerfil: p['nombre_perfil'] ?? "Usuario",
            email: SIMULATED_EMAIL,
            edad: p['edad'] ?? 0,
            nivelEducativo: p['nombre_nivel_educativo'] ?? "",
            rachaDias: p['racha_dias'] ?? 0,
            librosLeidos: p['libros_leidos'] ?? 0,
            porcentajeAciertos: porcentaje,
            imagenPerfil: p['imagen_perfil'],
          );
        } else {
          return null;
        }
      } else if (response.statusCode == 204) {
        return null;
      } else {
        print("ProfileService.fetchProfileForUser HTTP ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("ProfileService.fetchProfileForUser error: $e");
      return null;
    }
  }

  /// Crea perfil (retorna id_perfil si ok)
  static Future<int?> createProfile({
    required int idUsuario,
    required String nombrePerfil,
    int? edad,
    int? idNivelEducativo,
    String? imagenPerfilUrl,
  }) async {
    final body = {
      "id_usuario": idUsuario,
      "nombre_perfil": nombrePerfil,
      "edad": edad,
      "id_nivel_educativo": idNivelEducativo,
      "imagen_perfil": imagenPerfilUrl,
    };
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id_perfil'] as int?;
      } else {
        print("createProfile failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("createProfile error: $e");
      return null;
    }
  }

  /// Obtiene niveles educativos (para dropdown/checkbox)
  static Future<List<NivelEducativo>> fetchNivelesEducativos() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/niveles"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['niveles'] as List)
            .map(
              (e) => NivelEducativo(
                id: e['id_nivel_educativo'],
                nombre: e['nombre_nivel_educativo'],
              ),
            )
            .toList();
        return list;
      } else {
        return [];
      }
    } catch (e) {
      print("fetchNivelesEducativos error: $e");
      return [];
    }
  }

  // 🔥 AHORA: fetchProfileData admite idPerfil y mantiene compatibilidad
  static Future<UserProfileData> fetchProfileData([int? idPerfil]) async {
    // Si llega ID desde la vista → usar ese endpoint directo
    if (idPerfil != null) {
      try {
        final response = await http.get(Uri.parse("$_baseUrl/$idPerfil"));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          return UserProfileData(
            idPerfil: data['id_perfil'],
            nombreUsuario: data['nombre_perfil'],
            nombrePerfil: data['nombre_perfil'],
            email: SIMULATED_EMAIL,
            edad: data['edad'] ?? 0,
            nivelEducativo: data['nombre_nivel_educativo'] ?? "",
            rachaDias: data['racha_dias'] ?? 0,
            librosLeidos: data['libros_leidos'] ?? 0,
            porcentajeAciertos: (data['porcentaje_aciertos'] as num?)
                ?.toDouble(),
            imagenPerfil: data['imagen_perfil'],
          );
        }
      } catch (e) {
        print("fetchProfileData error (idPerfil): $e");
      }
    }

    // Fallback → como antes
    final userId = _currentUserId;
    final profile = await fetchProfileForUser(userId);
    if (profile != null) return profile;

    return UserProfileData(
      idPerfil: null,
      nombreUsuario: "Invitado",
      nombrePerfil: "Usuario Desconocido",
      email: "error@leotest.com",
      edad: 0,
      nivelEducativo: "Básico",
      rachaDias: 0,
      librosLeidos: 0,
      porcentajeAciertos: 0.0,
      imagenPerfil: null,
    );
  }
}
