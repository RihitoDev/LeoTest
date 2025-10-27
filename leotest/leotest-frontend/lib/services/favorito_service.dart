import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FavoritoService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/favoritos";

  /// Obtener favoritos de un perfil
  static Future<List<int>> obtenerFavoritos({required int idPerfil}) async {
    final response = await http.get(Uri.parse('$_baseUrl/$idPerfil'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => e as int).toList();
    } else {
      throw Exception('Error al obtener favoritos');
    }
  }

  /// Agregar favorito
  static Future<void> agregarFavorito({
    required int idPerfil,
    required int idLibro,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id_perfil': idPerfil, 'id_libro': idLibro}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al agregar favorito');
    }
  }

  /// Quitar favorito
  static Future<void> quitarFavorito({
    required int idPerfil,
    required int idLibro,
  }) async {
    final response = await http.delete(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id_perfil': idPerfil, 'id_libro': idLibro}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar favorito');
    }
  }
}
