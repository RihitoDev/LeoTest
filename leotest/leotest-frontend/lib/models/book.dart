// lib/models/book.dart

class Book {
  final int idLibro;
  final String titulo;
  final String autor;
  final String portada;
  final String? categoria;
  final String descripcion;
  final int totalPaginas;
  final String? urlPdf;

  Book({
    required this.idLibro,
    required this.titulo,
    required this.autor,
    required this.portada,
    this.categoria,
    required this.descripcion,
    required this.totalPaginas,
    this.urlPdf,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      idLibro: json['id_libro'] as int,
      titulo: json['titulo'] as String,
      autor: json['autor'] as String,
      portada: json['portada'] as String,
      urlPdf: json['url_pdf'] as String?,
      categoria: json['categoria'] as String?,
      descripcion: json['descripcion'] as String,
      totalPaginas: json['total_paginas'] as int,
    );
  }
}
