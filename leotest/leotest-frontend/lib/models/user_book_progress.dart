// lib/models/user_book_progress.dart (Actualizado para coincidir con la respuesta del JOIN)

class UserBookProgress {
  final String userId; // Ya lo tienes
  final int idProgreso; // Nuevo: ID del registro de progreso en la BD
  final int idLibro; // Nuevo: ID del libro en la BD
  final String title;
  final String coverAssetName; // portada
  final int currentPage; // paginas_leidas
  final int totalPages; // total_paginas (viene del JOIN de libro)
  final String estado; // estado

  double get progressPercentage => totalPages > 0 ? currentPage / totalPages : 0.0;

  UserBookProgress({
    required this.userId, 
    required this.idProgreso,
    required this.idLibro,
    required this.title,
    required this.coverAssetName,
    required this.currentPage,
    required this.totalPages,
    required this.estado,
  });

  factory UserBookProgress.fromJson(Map<String, dynamic> json, String currentUserId) {
    return UserBookProgress(
      userId: currentUserId,
      idProgreso: json['id_progreso'] as int,
      idLibro: json['id_libro'] as int,
      title: json['titulo'] as String,
      coverAssetName: json['portada'] as String,
      currentPage: json['paginas_leidas'] as int,
      totalPages: json['total_paginas'] as int,
      estado: json['estado'] as String,
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
    );
  }
}