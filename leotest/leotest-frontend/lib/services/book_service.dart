import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:leotest/models/book.dart';

class BookService {
  static String get baseUrl =>
      "${dotenv.env['API_BASE']}/api/libros"; // IP o URL pública de tu backend

  // Método para buscar libros
  static Future<List<Book>> buscarLibros({String? query}) async {
    try {
      final uri = Uri.parse("$baseUrl/buscar").replace(
        queryParameters: {
          if (query != null && query.isNotEmpty) "query": query,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['resultados'] as List)
            .map((e) => Book.fromJson(e))
            .toList();
      } else {
        print('Error HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error de conexión: $e');
      return [];
    }
  }
}
