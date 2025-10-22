// lib/services/my_books_service.dart (Completo y usando HTTP)

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/user_book_progress.dart';
import '../models/book.dart'; // Necesitas la clase Book para el addBook
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
      }
      return [];
    } catch (e) {
      print('Error al obtener la biblioteca del usuario: $e');
      return []; // Devuelve lista vacía en caso de error
    }
  }

  /// Busca el progreso de un libro específico en el backend.
  static Future<UserBookProgress?> getBookProgress(String title) async {
    final books = await getUserBooks();
    // Filtra localmente después de obtener todos, o crea un endpoint para esto.
    // Por simplicidad, filtramos en el cliente después de obtener todos.
    try {
      return books.firstWhere((b) => b.title == title);
    } catch (e) {
      return null;
    }
  }

  /// Añade un libro nuevo a la biblioteca del usuario a través del API.
  static Future<void> addBookToLibrary(Book book) async {
    final userId = _currentUserId;
    
    // Asumimos que 'Book' ahora tiene un 'id_libro'
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
        print('❌ Error al añadir libro: ${data['mensaje']}');
      }
    } catch (e) {
      print('Error de conexión al añadir libro: $e');
    }
  }

  /// Actualiza el progreso de un libro existente en el backend.
  static Future<void> updateBookProgress(UserBookProgress progress, int newPage) async {
    final userId = _currentUserId;
    // Determinar si está completo (ejemplo: si la nueva página es la última)
    final newStatus = (newPage >= progress.totalPages) ? 'Completado' : 'Iniciado';
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$userId/${progress.idLibro}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paginas_leidas': newPage,
          'capitulos_completados': 0, // Ajustar si manejas capítulos
          'estado': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        print('🔄 Progreso actualizado en BD para ${progress.title} a página $newPage');
      } else {
        final data = json.decode(response.body);
        print('❌ Error al actualizar progreso: ${data['mensaje']}');
      }
    } catch (e) {
      print('Error de conexión al actualizar progreso: $e');
    }
  }
}