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
  static String? _currentUserId; // Guarda la ID de la sesión
  static String? _currentUserRole; // Guarda el rol de la sesión

  // Método usado por MyBooksService
  static String getCurrentUserId() {
    if (_currentUserId == null) {
        throw Exception("Error: Intento de acceso a recurso privado sin ID de usuario.");
    }
    return _currentUserId!;
  }
  
  static String? getCurrentUserRole() => _currentUserRole;

  // 🚨 NUEVA FUNCIÓN: Limpia la sesión
  static void logout() {
    _currentUserId = null;
    _currentUserRole = null;
    print("✅ Sesión cerrada y estado limpio.");
    // NOTA: Si usaras JWTs o tokens de sesión, la limpieza del token iría aquí.
  }
  // ------------------------------------

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
        
        // Asegúrate de que tu backend use 'id_usuario'
        final String fetchedUserId = data['id_usuario'].toString(); 
        final String role = data['rol'] as String;
        
        // Guardar el estado de la sesión
        _currentUserId = fetchedUserId;
        _currentUserRole = role;

        return AuthResult(
          success: true,
          userId: fetchedUserId,
          role: role,
        );
      } else {
        logout(); // Limpiar el estado en caso de fallo
        return AuthResult(
          success: false,
          errorMessage: data['mensaje'] ?? 'Error de autenticación',
        );
      }
    } catch (e) {
      print('Error de conexión en login: $e');
      logout(); // Limpiar el estado en caso de error de conexión
      return AuthResult(
        success: false,
        errorMessage: 'Error de red o servidor no disponible.',
      );
    }
  }
}