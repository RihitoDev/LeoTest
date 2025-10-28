// lib/models/user_book_progress.dart

class UserBookProgress {
  final String userId;
  final int idProgreso;
  final int idLibro;
  final String title;
  final String coverAssetName; // portada
  final int currentPage; // paginas_leidas
  final int totalPages; // total_paginas (viene del JOIN de libro)
  final String estado;

  // ✅ CAMPOS AÑADIDOS (para poder construir un objeto Book)
  final String autor;
  final String descripcion;
  final String? urlPdf;
  final String? categoria;

  double get progressPercentage =>
      totalPages > 0 ? currentPage / totalPages : 0.0;

  UserBookProgress({
    required this.userId,
    required this.idProgreso,
    required this.idLibro,
    required this.title,
    required this.coverAssetName,
    required this.currentPage,
    required this.totalPages,
    required this.estado,
    // ✅ AÑADIDOS AL CONSTRUCTOR
    required this.autor,
    required this.descripcion,
    this.urlPdf,
    this.categoria,
  });

  factory UserBookProgress.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    return UserBookProgress(
      userId: currentUserId,
      idProgreso: json['id_progreso'] as int,
      idLibro: json['id_libro'] as int,
      title: json['titulo'] as String,
      coverAssetName: json['portada'] as String,
      currentPage: json['paginas_leidas'] as int,
      totalPages: json['total_paginas'] as int,
      estado: json['estado'] as String,
      // ✅ AÑADIDOS AL FACTORY
      autor: json['autor'] as String,
      descripcion: json['descripcion'] as String,
      urlPdf: json['url_pdf'] as String?,
      categoria: json['categoria'] as String?,
    );
  }

  UserBookProgress copyWith({int? currentPage, String? estado}) {
    return UserBookProgress(
      userId: userId,
      idProgreso: idProgreso,
      idLibro: idLibro,
      title: title,
      coverAssetName: coverAssetName,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages,
      estado: estado ?? this.estado,
      autor: autor,
      descripcion: descripcion,
      urlPdf: urlPdf,
      categoria: categoria,
    );
  }
}