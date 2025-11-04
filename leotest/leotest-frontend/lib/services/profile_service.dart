// lib/services/profile_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'stats_service.dart';

class UserProfileData {
  final String nombreUsuario; // Nombre de usuario (login)
  final String nombrePerfil; // Nombre completo o display name
  final String email; // No se obtiene del perfil/usuario, es estático para esta simulación
  final int edad;
  final String nivelEducativo;
  
  // Estadísticas que vienen del JOIN
  final int rachaDias;
  final int librosLeidos;
  final double? porcentajeAciertos;

  UserProfileData({
    required this.nombreUsuario,
    required this.nombrePerfil,
    required this.email,
    required this.edad,
    required this.nivelEducativo,
    required this.rachaDias,
    required this.librosLeidos,
    this.porcentajeAciertos,
  });
}

class ProfileService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/profile";
  static String get _currentUserId => AuthService.getCurrentUserId();
  
  // Asumimos que el email es estático o se maneja por separado ya que no está en la BD
  static const String SIMULATED_EMAIL = "usuario@leotest.com";

  /// Obtiene todos los datos del perfil y sus estadísticas (HU-11.2)
  static Future<UserProfileData> fetchProfileData() async {
    final userId = _currentUserId;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['datos_perfil'];

        // Manejamos la conversión de números decimales que pueden venir como String o num
        final double? aciertos = (profile['porcentaje_aciertos'] is String)
            ? double.tryParse(profile['porcentaje_aciertos'])
            : (profile['porcentaje_aciertos'] as num?)?.toDouble();
        
        final int libros = (profile['libros_leidos'] as int?) ?? 0;

        return UserProfileData(
            nombreUsuario: profile['nombre_usuario'] as String,
            nombrePerfil: profile['nombre_perfil'] as String,
            email: SIMULATED_EMAIL, // Usamos el estático/simulado
            edad: profile['edad'] as int,
            nivelEducativo: profile['nivel_educativo'] as String,
            rachaDias: profile['racha_dias'] as int,
            librosLeidos: libros,
            porcentajeAciertos: aciertos,
        );
      }
      
      print('Error al obtener datos de perfil: HTTP ${response.statusCode}');
      // Devuelve datos base si falla la conexión o el servidor
      return _getFallbackProfile();

    } catch (e) {
      print('Error de conexión en ProfileService: $e');
      return _getFallbackProfile();
    }
  }
  
  // Retorna datos mínimos en caso de fallo
  static UserProfileData _getFallbackProfile() {
      return UserProfileData(
          nombreUsuario: "Invitado",
          nombrePerfil: "Usuario Desconocido",
          email: "error@leotest.com",
          edad: 0,
          nivelEducativo: "Básico",
          rachaDias: 0,
          librosLeidos: 0,
          porcentajeAciertos: 0.0
      );
  }
}