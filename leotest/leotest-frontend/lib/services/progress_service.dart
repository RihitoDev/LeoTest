// lib/services/progress_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BookProgress {
  final int idProgreso;
  final int idLibro;
  final String titulo;
  final int paginasLeidas;
  final int totalPaginas;
  final int capitulosCompletados;
  final String estado;

  final String? portada;
  final String? autor;
  final String? descripcion;
  final String? urlPdf;
  final String? categoria;
  final String? fechaInicio;
  final String? fechaFin;

  BookProgress({
    required this.idProgreso,
    required this.idLibro,
    required this.titulo,
    required this.paginasLeidas,
    required this.totalPaginas,
    required this.capitulosCompletados,
    required this.estado,
    this.portada,
    this.autor,
    this.descripcion,
    this.urlPdf,
    this.categoria,
    this.fechaInicio,
    this.fechaFin,
  });

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    // 🔹 Aseguramos que los números sean int aunque vengan como String
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return BookProgress(
      idProgreso: json['id_progreso'],
      idLibro: json['id_libro'],
      titulo: json['titulo'] ?? '',
      paginasLeidas: json['paginas_leidas'],
      totalPaginas: json['total_paginas'],
      capitulosCompletados: json['capitulos_completados'],
      estado: json['estado'],
      portada: json['portada'],
      autor: json['autor'],
      descripcion: json['descripcion'],
      urlPdf: json['url_pdf'],
      categoria: json['categoria'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
    );
  }
}

class ProgressService {
  static String get _baseUrl => "${dotenv.env['API_BASE']}/api/progress";

  static Future<List<BookProgress>> getUserProgress(int userId) async {
    final url = "$_baseUrl/$userId";
    print("📡 GET → $url");

    try {
      final response = await http.get(Uri.parse(url));

      print("🔍 STATUS CODE: ${response.statusCode}");
      print("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data["progreso"] ?? [];

        print("📚 TOTAL ELEMENTOS EN LA LISTA: ${list.length}");

        return list.map((item) => BookProgress.fromJson(item)).toList();
      } else {
        print("❌ ERROR del servidor: ${response.body}");
        return [];
      }
    } catch (e) {
      print('❌ Error de conexión al obtener progreso: $e');
      return [];
    }
  }
}
