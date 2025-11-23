import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String? userId;
  final String? role;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.userId,
    this.role,
    this.errorMessage,
  });
}

class AuthService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/auth";

  // --- ESTADO DE SESIÓN ---
  static String? _currentUserId;
  static String? _currentUserRole;
  static String? _currentUsername;
  static String? getCurrentUsername() => _currentUsername;

  static String getCurrentUserId() {
    if (_currentUserId == null) {
      throw Exception("Intento de acceder sin haber iniciado sesión.");
    }
    return _currentUserId!;
  }

  static String? getCurrentUserRole() => _currentUserRole;

  static void logout() {
    _currentUserId = null;
    _currentUserRole = null;
    print("🔻 Sesión cerrada.");
  }

  // ---------------------------------------------------------------------------
  // --------------------------- MÉTODO LOGIN ----------------------------------
  // ---------------------------------------------------------------------------
  static Future<AuthResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/login"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nombre_usuario': username, 'contraseña': password}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['exito'] == true) {
        final String fetchedUserId = data['id_usuario'].toString();
        final String role = data['rol'] as String;
        final String username = data['nombre_usuario'];

        _currentUserId = fetchedUserId;
        _currentUserRole = role;
        _currentUsername = username;

        return AuthResult(success: true, userId: fetchedUserId, role: role);
      } else {
        logout();
        return AuthResult(
          success: false,
          errorMessage: data['mensaje'] ?? 'Credenciales incorrectas',
        );
      }
    } catch (e) {
      print('❌ Error en login: $e');
      logout();
      return AuthResult(
        success: false,
        errorMessage: 'Servidor no disponible.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ---------------------- MÉTODO REGISTRO COMPLETO ---------------------------
  // ---------------------------------------------------------------------------
  static Future<AuthResult> register({
    required String username,
    required String password,
    required String fullName,
  }) async {
    try {
      final responseUser = await http.post(
        Uri.parse("$_baseUrl/register"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre_completo': fullName,
          'nombre_usuario': username,
          'contraseña': password,
        }),
      );

      final dataUser = json.decode(responseUser.body);

      if (responseUser.statusCode != 201 || dataUser['exito'] != true) {
        return AuthResult(
          success: false,
          errorMessage: dataUser['mensaje'] ?? "Error al registrar usuario.",
        );
      }

      final int userId = dataUser['id_usuario'];

      return AuthResult(
        success: true,
        userId: userId.toString(),
        role: "usuario",
      );
    } catch (e) {
      print("❌ Error en registro: $e");
      return AuthResult(
        success: false,
        errorMessage: "Error de red o servidor.",
      );
    }
  }
  // ---------------------------------------------------------------------------
  // ----------------------- CAMBIAR CONTRASEÑA -------------------------------
  // ---------------------------------------------------------------------------

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userId = getCurrentUserId();
      final response = await http.post(
        Uri.parse("$_baseUrl/change_password"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "userId": int.parse(userId),
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );

      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      print("changePassword error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Actualizar nombre de usuario
  static Future<bool> updateUsername(String newUsername) async {
    try {
      final userId = getCurrentUserId();
      final response = await http.post(
        Uri.parse("$_baseUrl/update_username"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "userId": int.parse(userId),
          "newUsername": newUsername,
        }),
      );

      if (response.statusCode == 200) return true;
      return false;
    } catch (e) {
      print("updateUsername error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Eliminar cuenta
  static Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/delete_user/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // limpiar sesión local si era el usuario actual
        if (_currentUserId == userId.toString()) logout();
        return true;
      }
      return false;
    } catch (e) {
      print("deleteUser error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // sacar nombre de usuario
  static Future<String?> fetchUsernameById() async {
    try {
      final userId = getCurrentUserId();
      final response = await http.get(Uri.parse("$_baseUrl/user/$userId"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['nombre_usuario'];
      }
      return null;
    } catch (e) {
      print("fetchUsernameById error: $e");
      return null;
    }
  }
}
