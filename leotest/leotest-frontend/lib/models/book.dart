class Book {
  final int id;
  final String titulo;
  final String autor;
  final String portada;
  final String descripcion;
  final int totalPaginas;
  final int totalCapitulos;
  final String? categoria;

  final String? estado;
  final int pagesRead;
  final int chaptersCompleted;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  Book({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.portada,
    required this.descripcion,
    required this.totalPaginas,
    required this.totalCapitulos,
    this.categoria,
    this.estado,
    this.pagesRead = 0,
    this.chaptersCompleted = 0,
    this.fechaInicio,
    this.fechaFin,
  });

  double get progressPercentage =>
      totalPaginas > 0 ? pagesRead / totalPaginas : 0.0;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id_libro'] ?? 0,
      titulo: json['titulo'] ?? '',
      autor: json['autor'] ?? '',
      portada: json['portada'] ?? '',
      descripcion: json['descripcion'] ?? '',
      totalPaginas: json['total_paginas'] ?? 0,
      totalCapitulos: json['total_capitulos'] ?? 0,
      categoria: json['categoria'],
      estado: json['estado'],
      pagesRead: json['paginas_leidas'] ?? 0,
      chaptersCompleted: json['capitulos_completados'] ?? 0,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_libro': id,
      'titulo': titulo,
      'autor': autor,
      'portada': portada,
      'descripcion': descripcion,
      'total_paginas': totalPaginas,
      'total_capitulos': totalCapitulos,
      'categoria': categoria,
      'estado': estado,
      'paginas_leidas': pagesRead,
      'capitulos_completados': chaptersCompleted,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
    };
  }
}

// Datos de ejemplo
const List<Book> class1Books = [/* ... */];
const List<Book> class2Books = [/* ... */];
const List<Book> class3Books = [/* ... */];
