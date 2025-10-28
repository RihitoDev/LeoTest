// lib/services/my_books_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/user_book_progress.dart';
import '../models/book.dart';
import 'auth_service.dart';

class MyBooksService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/progress";
  static String get _currentUserId => AuthService.getCurrentUserId();

  /// Obtiene todos los libros en progreso para el usuario actual desde el backend.
  static Future<List<UserBookProgress>> getUserBooks() async {
    final userId = _currentUserId;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['exito'] == true) {
          final List<dynamic> progresoList = data['progreso'];
          return progresoList
              .map((json) => UserBookProgress.fromJson(json, userId))
              .toList();
        }
      } else {
         print('Error HTTP [${response.statusCode}] al obtener biblioteca: ${response.body}');
      }
      return [];
    } catch (e) {
      print('Error de conexión al obtener la biblioteca del usuario: $e');
      return [];
    }
  }

  /// Busca el progreso de un libro específico en el backend.
  static Future<UserBookProgress?> getBookProgress(String title) async {
    try {
      final books = await getUserBooks();
      // Filtra localmente después de obtener todos.
      return books.firstWhere((b) => b.title == title);
    } catch (e) {
      // Si no lo encuentra (FirstWhereError) o hay otro error, retorna null
      print("Libro '$title' no encontrado en progreso o error: $e");
      return null;
    }
  }


  /// Añade un libro nuevo a la biblioteca del usuario a través del API.
  static Future<void> addBookToLibrary(Book book) async {
    final userId = _currentUserId;

    if (book.idLibro == null) {
      print('Error: El objeto Book debe tener idLibro para guardarse.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'id_libro': book.idLibro,
          'total_paginas': book.totalPaginas,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Libro añadido a la BD para Usuario: $userId - ${book.titulo}');
      } else if (response.statusCode == 409) {
        print('⚠️ El libro ya está en la biblioteca del usuario.');
      } else {
        final data = json.decode(response.body);
        print('❌ Error [${response.statusCode}] al añadir libro: ${data['mensaje']}');
      }
    } catch (e) {
      print('Error de conexión al añadir libro: $e');
    }
  }

  /// Actualiza el progreso de un libro existente en el backend.
  static Future<void> updateBookProgress(
      UserBookProgress progress, int newPage) async {
    final userId = _currentUserId;
    final newStatus =
        (newPage >= progress.totalPages) ? 'Completado' : 'Iniciado';

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$userId/${progress.idLibro}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paginas_leidas': newPage,
          'capitulos_completados': 0,
          'estado': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        print(
            '🔄 Progreso actualizado en BD para ${progress.title} a página $newPage');
      } else {
        final data = json.decode(response.body);
        print('❌ Error [${response.statusCode}] al actualizar progreso: ${data['mensaje']}');
      }
    } catch (e) {
      print('Error de conexión al actualizar progreso: $e');
    }
  }

  /// Actualiza solo la página de un libro, usado por el lector.
  static Future<void> updatePageProgress({
    required int idLibro,
    required int newPage,
    required int totalPages,
  }) async {
    try {
      final userId = _currentUserId;
      final newStatus = (newPage >= totalPages) ? 'Completado' : 'Iniciado';

      final response = await http.put(
        Uri.parse('$_baseUrl/$userId/$idLibro'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paginas_leidas': newPage,
          'capitulos_completados': 0,
          'estado': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        print(
            '🔄 Progreso (Lector) actualizado en BD para libro $idLibro a página $newPage');
      } else {
        final data = json.decode(response.body);
        print('❌ Error [${response.statusCode}] al actualizar progreso (Lector): ${data['mensaje']}');
      }
    } catch (e) {
      print('Error de conexión al actualizar progreso (Lector): $e');
    }
  }

  // ✅ --- INICIO DE NUEVO MÉTODO ---
  /// Elimina el progreso de un libro para el usuario actual.
  static Future<bool> deleteBookProgress({required int idLibro}) async {
    try {
      final userId = _currentUserId;
      final response = await http.delete(
        Uri.parse('$_baseUrl/$userId/$idLibro'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('✅ Libro $idLibro eliminado de la biblioteca para usuario $userId');
        return true; // Éxito
      } else if (response.statusCode == 404) {
        print('⚠️ Libro $idLibro no encontrado en la biblioteca para eliminar.');
        return false; // No encontrado, pero no es un error grave
      } else {
        // Otros errores del servidor
        final data = json.decode(response.body);
        print('❌ Error [${response.statusCode}] al eliminar libro: ${data['mensaje']}');
        return false; // Error
      }
    } catch (e) {
      print('Error de conexión al eliminar libro: $e');
      return false; // Error de conexión
    }
  }
  // ✅ --- FIN DE NUEVO MÉTODO ---

}