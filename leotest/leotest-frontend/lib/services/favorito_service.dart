// favorito_service.dart
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

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agregar favorito');
    }
  }

  /// Quitar favorito
  static Future<void> quitarFavorito({
    required int idPerfil,
    required int idLibro,
  }) async {
    // Nota: algunos servidores no aceptan body en DELETE; si el tuyo no lo acepta,
    // puedes cambiar a enviar por query params o usar POST a /delete.
    final request = http.Request('DELETE', Uri.parse(_baseUrl));
    request.headers['Content-Type'] = 'application/json';
    request.body = json.encode({'id_perfil': idPerfil, 'id_libro': idLibro});

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar favorito');
    }
  }
}
