import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:leotest/models/book.dart'; // Asegúrate de que este modelo exista

// --- Modelos de Datos de Apoyo ---
class Category {
  final int id;
  final String name;
  Category({required this.id, required this.name});
  
  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id_categoria'], name: json['nombre_categoria']);
}

class Level {
  final int id;
  final String name;
  Level({required this.id, required this.name});
  
  factory Level.fromJson(Map<String, dynamic> json) =>
      Level(id: json['id_nivel_educativo'], name: json['nombre_nivel_educativo']);
}

// --- Clase BookService ---
class BookService {
  static String get baseUrl => "${dotenv.env['API_BASE']}/api/libros"; 

  // [MÉTODO EXISTENTE] Método para buscar libros
  static Future<List<Book>> buscarLibros({String? titulo}) async {
    try {
      final uri = Uri.parse("$baseUrl/buscar").replace(
        queryParameters: {
          if (titulo != null && titulo.isNotEmpty) "titulo": titulo,
        },
      );
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultados'] is List) {
          // Asumiendo que Book.fromJson maneja la estructura de los resultados de la búsqueda
          return (data['resultados'] as List).map((e) => Book.fromJson(e)).toList();
        } else {
          print('Error de formato de API: La clave "resultados" no es una lista.');
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

  // [MÉTODO EXISTENTE] Obtener Categorías
  static Future<List<Category>> obtenerCategorias() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/categorias"));
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

  // 🚀 [MÉTODO AÑADIDO] Crear Categoría (Para el Panel Admin)
  static Future<bool> crearCategoria(String name) async {
    try {
      final response = await http.post(
        // Asegúrate de que esta ruta coincida con tu backend (POST /api/libros/categorias)
        Uri.parse("$baseUrl/categorias"), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nombre': name}), // El backend espera 'nombre'
      );

      // El backend devuelve 201 (Created) si tiene éxito
      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 409) {
        // 409 Conflict si ya existe (basado en la lógica del controlador)
        print('Error 409: La categoría ya existe.');
        return false;
      } else {
        print('Error al crear categoría (HTTP ${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al crear categoría: $e');
      return false;
    }
  }

  // [MÉTODO EXISTENTE] Obtener Niveles Educativos
  static Future<List<Level>> obtenerNiveles() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/niveles"));
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

  // [MÉTODO EXISTENTE] Subir Libro (Multipart)
  static Future<bool> subirLibro({
    required String titulo,
    required String autor,
    required String descripcion,
    required int idCategoria,
    required int idNivelEducativo,
    required String filePath, // Ruta local del archivo PDF/ePub
    // Aquí puedes añadir total_paginas y total_capitulos si es necesario en la UI
  }) async {
    final uri = Uri.parse("$baseUrl/subir");
    final request = http.MultipartRequest('POST', uri)
      ..fields['titulo'] = titulo
      ..fields['autor'] = autor
      ..fields['descripcion'] = descripcion
      ..fields['id_categoria'] = idCategoria.toString()
      ..fields['id_nivel_educativo'] = idNivelEducativo.toString()
      // Se asume 0 si no se envían total_paginas/capitulos
      ..fields['total_paginas'] = '0' 
      ..fields['total_capitulos'] = '0'
      ..files.add(await http.MultipartFile.fromPath('archivo', filePath));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print('Libro subido con éxito');
        return true;
      } else {
        print('Error al subir libro (HTTP ${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al subir libro: $e');
      return false;
    }
  }
}