// lib/services/book_service.dart (COMPLETO Y MULTI-PLATAFORMA)

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:leotest/models/book.dart';

// ------------------------------
// --- Modelos de Datos de Apoyo ---
// ------------------------------

class Category {
  final int id;
  final String name;
  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id_categoria'] as int,
    name: json['nombre_categoria'] as String,
  );
}

class Level {
  final int id;
  final String name;
  Level({required this.id, required this.name});

  factory Level.fromJson(Map<String, dynamic> json) => Level(
    id: json['id_nivel_educativo'] as int,
    name: json['nombre_nivel_educativo'] as String,
  );
}

// -------------------------
// --- Clase BookService ---
// -------------------------

class BookService {
  static String get baseUrl {
    final apiBase = dotenv.env['API_BASE'];
    if (apiBase == null) {
      throw Exception("API_BASE no está definido en .env");
    }
    return "$apiBase/api";
  }

  // URL principal de libros
  static String get _librosUrl => "$baseUrl/libros";

  // 🚨 CORRECCIÓN: Rutas anidadas bajo /libros
  static String get _categoriasUrl => "$_librosUrl/categorias";
  static String get _nivelesUrl => "$_librosUrl/niveles";

  // ----------------------------------------------------
  // MÉTODOS DE BÚSQUEDA Y OBTENCIÓN DE DATOS
  // ----------------------------------------------------

  static Future<List<Book>> buscarLibros({
    String? query, // Texto de búsqueda (titulo, autor o categoría)
    String? categoriaId, // ID de categoría para filtrar
  }) async {
    try {
      final uri = Uri.parse("$_librosUrl/buscar").replace(
        queryParameters: {
          if (query != null && query.isNotEmpty) "query": query,
          if (categoriaId != null && categoriaId.isNotEmpty)
            "categoriaId": categoriaId,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultados'] is List) {
          return (data['resultados'] as List)
              .map((e) => Book.fromJson(e))
              .toList();
        } else {
          print(
            'Error de formato de API: La clave "resultados" no es una lista.',
          );
          return [];
        }
      } else {
        print('Error HTTP al buscar libros: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error de conexión al buscar libros: $e');
      return [];
    }
  }

  static Future<List<Category>> obtenerCategorias() async {
    try {
      // Usa la URL corregida: /api/libros/categorias
      final response = await http.get(Uri.parse(_categoriasUrl));
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)
            .map((e) => Category.fromJson(e))
            .toList();
      }
      print('Error al obtener categorías: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error de conexión al obtener categorías: $e');
      return [];
    }
  }

  static Future<List<Level>> obtenerNiveles() async {
    try {
      // Usa la URL corregida: /api/libros/niveles
      final response = await http.get(Uri.parse(_nivelesUrl));
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)
            .map((e) => Level.fromJson(e))
            .toList();
      }
      print('Error al obtener niveles: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error de conexión al obtener niveles: $e');
      return [];
    }
  }

  // ----------------------------------------------------
  // MÉTODOS DE ADMINISTRACIÓN
  // ----------------------------------------------------

  static Future<bool> crearCategoria(String name) async {
    try {
      // La ruta de creación podría estar directamente bajo /api/categorias
      // Si el 404 persiste aquí, también prueba a usar $_librosUrl/categorias
      final response = await http.post(
        Uri.parse(_categoriasUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nombre': name}),
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 409) {
        print('Error 409: La categoría ya existe.');
        return false;
      } else {
        print(
          'Error al crear categoría (HTTP ${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error de red al crear categoría: $e');
      return false;
    }
  }

  static Future<bool> subirLibro({
    required String titulo,
    required String autor,
    required String descripcion,
    required int idCategoria,
    required int idNivelEducativo,
    required Uint8List bookFileBytes,
    required String bookFileName,
    required Uint8List coverFileBytes,
    required String coverFileName,
    int totalPaginas = 0,
    int totalCapitulos = 0,
  }) async {
    final uri = Uri.parse("$_librosUrl/subir");
    final request = http.MultipartRequest('POST', uri);

    request.fields['titulo'] = titulo;
    request.fields['autor'] = autor;
    request.fields['descripcion'] = descripcion;
    request.fields['id_categoria'] = idCategoria.toString();
    request.fields['id_nivel_educativo'] = idNivelEducativo.toString();
    request.fields['total_paginas'] = totalPaginas.toString();
    request.fields['total_capitulos'] = totalCapitulos.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bookFileBytes,
        filename: bookFileName,
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'portada',
        coverFileBytes,
        filename: coverFileName,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print('Libro y portada subidos con éxito');
        return true;
      } else {
        print(
          'Error al subir libro (HTTP ${response.statusCode}): ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error de red al subir libro: $e');
      return false;
    }
  }
}
