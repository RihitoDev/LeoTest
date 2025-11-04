import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String? userId; 
  final String? role;
  final String? errorMessage;

  AuthResult({required this.success, this.userId, this.role, this.errorMessage});
}

class AuthService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/auth";

  // --- GESTIÓN DE ESTADO DE SESIÓN ---
  static String? _currentUserId; 
  static String? _currentUserRole; 

  static String getCurrentUserId() {
    if (_currentUserId == null) {
        throw Exception("Error: Intento de acceso a recurso privado sin ID de usuario.");
    }
    return _currentUserId!;
  }
  
  static String? getCurrentUserRole() => _currentUserRole;

  static void logout() {
    _currentUserId = null;
    _currentUserRole = null;
    print("✅ Sesión cerrada y estado limpio.");
  }
  // ------------------------------------

  // (MÉTODO LOGIN SIN CAMBIOS)
  static Future<AuthResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/login"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre_usuario': username,
          'contraseña': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['exito'] == true) {
        
        final String fetchedUserId = data['id_usuario'].toString(); 
        final String role = data['rol'] as String;
        
        _currentUserId = fetchedUserId;
        _currentUserRole = role;

        return AuthResult(
          success: true,
          userId: fetchedUserId,
          role: role,
        );
      } else {
        logout();
        return AuthResult(
          success: false,
          errorMessage: data['mensaje'] ?? 'Error de autenticación',
        );
      }
    } catch (e) {
      print('Error de conexión en login: $e');
      logout();
      return AuthResult(
        success: false,
        errorMessage: 'Error de red o servidor no disponible.',
      );
    }
  }

  // ✅ --- INICIO DE NUEVO MÉTODO ---
  static Future<AuthResult> register({
    required String fullName,
    required String username,
    required String password,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/register"), // Nuevo endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre_completo': fullName,
          'nombre_usuario': username,
          'contraseña': password,
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['exito'] == true) {
        return AuthResult(
          success: true,
          errorMessage: data['mensaje'] ?? 'Registro exitoso.',
        );
      } else {
        // Error como usuario ya existente (409) o error de validación (400)
        return AuthResult(
          success: false,
          errorMessage: data['mensaje'] ?? 'Error al registrar usuario.',
        );
      }
    } catch (e) {
      print('Error de conexión en registro: $e');
      return AuthResult(
        success: false,
        errorMessage: 'Error de red o servidor no disponible.',
      );
    }
  }
  // ✅ --- FIN DE NUEVO MÉTODO ---
}