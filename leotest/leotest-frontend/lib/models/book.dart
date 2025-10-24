// lib/models/book.dart

class Book {
  final int idLibro; // 👈 ¡NUEVA PROPIEDAD REQUERIDA!
  final String titulo;
  final String autor;
  final String portada;
  final String? categoria; // Puede ser String? según errores anteriores
  final String descripcion;
  final int totalPaginas;
  final String? urlPdf;

  Book({
    required this.idLibro, // 👈 ¡Añadir al constructor!
    required this.titulo,
    required this.autor,
    required this.portada,
    this.categoria, // Si es nulo
    required this.descripcion,
    required this.totalPaginas,
    this.urlPdf,
    // ... (otros parámetros)
  });

  // Asegúrate de actualizar el factory constructor (si tienes uno)
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      idLibro: json['id_libro'] as int, // Asegura la lectura del JSON
      titulo: json['titulo'] as String,
      autor: json['autor'] as String,
      portada: json['portada'] as String,
      urlPdf: json['url_pdf'] as String?,
      categoria: json['categoria'] as String?, // Usar String?
      descripcion: json['descripcion'] as String,
      totalPaginas: json['total_paginas'] as int,
    );
  }
}