import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String? role;
  final String? errorMessage;

  AuthResult({required this.success, this.role, this.errorMessage});
}

class AuthService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/auth";

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
        return AuthResult(
          success: true,
          role: data['rol'] as String,
        );
      } else {
        return AuthResult(
          success: false,
          errorMessage: data['mensaje'] ?? 'Error de autenticación',
        );
      }
    } catch (e) {
      print('Error de conexión en login: $e');
      return AuthResult(
        success: false,
        errorMessage: 'Error de red o servidor no disponible.',
      );
    }
  }
}