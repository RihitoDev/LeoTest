import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/user_book_progress.dart';
import '../models/book.dart';

class MyBooksService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/progress";

  // ================================================================
  // 1. Obtener todos los libros del perfil
  // ================================================================
  static Future<List<UserBookProgress>> getUserBooks(int idPerfil) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$idPerfil'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['exito'] == true) {
          final List<dynamic> progresoList = data['progreso'];
          return progresoList
              .map((json) => UserBookProgress.fromJson(json, idPerfil))
              .toList();
        }
      }

      print(
        'Error HTTP [${response.statusCode}] al obtener biblioteca: ${response.body}',
      );
      return [];
    } catch (e) {
      print(
        '❌ Error de conexión al obtener la biblioteca del perfil $idPerfil: $e',
      );
      return [];
    }
  }

  // ================================================================
  // 2. Obtener progreso de un libro por TÍTULO
  // ================================================================
  static Future<UserBookProgress?> getBookProgress(
    String title,
    int idPerfil,
  ) async {
    try {
      final books = await getUserBooks(idPerfil);
      return books.firstWhere((b) => b.title == title);
    } catch (e) {
      print("⚠ Libro '$title' no encontrado en perfil $idPerfil | Error: $e");
      return null;
    }
  }

  // ================================================================
  // 3. Agregar libro a la biblioteca del perfil
  // ================================================================
  static Future<void> addBookToLibrary(Book book, int idPerfil) async {
    if (book.idLibro == null) {
      print('❌ Error: El objeto Book debe tener idLibro.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': idPerfil,
          'id_libro': book.idLibro,
          'total_paginas': book.totalPaginas,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Libro añadido a BD para Perfil: $idPerfil - ${book.titulo}');
      } else if (response.statusCode == 409) {
        print('⚠ Libro ya estaba en biblioteca del perfil ($idPerfil)');
      } else {
        final data = json.decode(response.body);
        print(
          '❌ Error [${response.statusCode}] al añadir libro: ${data['mensaje']}',
        );
      }
    } catch (e) {
      print('❌ Error de conexión al añadir libro para perfil $idPerfil: $e');
    }
  }

  // ================================================================
  // 4. Actualizar progreso de lectura (general)
  // ================================================================
  static Future<void> updateBookProgress(
    UserBookProgress progress,
    int newPage,
    int idPerfil,
  ) async {
    final newStatus = (newPage >= progress.totalPages)
        ? 'Completado'
        : 'Iniciado';

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$idPerfil/${progress.idLibro}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paginas_leidas': newPage.toInt(), // 🔹 fuerza int
          'capitulos_completados': 0, // 🔹 fuerza int
          'estado': newStatus, // 🔹 string
        }),
      );

      if (response.statusCode == 200) {
        print(
          '✅ Progreso actualizado para libro ${progress.title} → página $newPage (perfil $idPerfil)',
        );
      } else {
        final data = json.decode(response.body);
        print(
          '❌ Error [${response.statusCode}] al actualizar progreso: ${data['mensaje']}',
        );
      }
    } catch (e) {
      print('❌ Error de conexión al actualizar progreso: $e');
    }
  }

  // ================================================================
  // 5. Actualizar progreso desde ReaderView (tipos asegurados)
  // ================================================================
  static Future<void> updatePageProgress({
    required int idLibro,
    required int newPage,
    required int totalPages,
    required int idPerfil,
  }) async {
    final newStatus = (newPage >= totalPages) ? 'Completado' : 'Iniciado';

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$idPerfil/$idLibro'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paginas_leidas': newPage.toInt(), // 🔹 fuerza int
          'capitulos_completados': 0, // 🔹 fuerza int
          'estado': newStatus, // 🔹 string
        }),
      );

      if (response.statusCode == 200) {
        print(
          '✅ Progreso actualizado (Reader) libro $idLibro → página $newPage (perfil $idPerfil)',
        );
      } else {
        final data = json.decode(response.body);
        print(
          '❌ Error [${response.statusCode}] al actualizar progreso: ${data['mensaje']}',
        );
      }
    } catch (e) {
      print('❌ Error de conexión al actualizar progreso (Reader): $e');
    }
  }

  // ================================================================
  // 6. Eliminar libro del perfil
  // ================================================================
  static Future<bool> deleteBookProgress({
    required int idLibro,
    required int idPerfil,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$idPerfil/$idLibro'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('🗑 Libro $idLibro eliminado para perfil $idPerfil');
        return true;
      }

      if (response.statusCode == 404) {
        print(
          '⚠ Libro $idLibro no estaba en la biblioteca del perfil $idPerfil',
        );
        return false;
      }

      final data = json.decode(response.body);
      print(
        '❌ Error [${response.statusCode}] al eliminar libro: ${data['mensaje']}',
      );
      return false;
    } catch (e) {
      print('❌ Error de conexión al eliminar libro: $e');
      return false;
    }
  }
}
