import 'package:flutter/material.dart';

class BookProgressCard extends StatelessWidget {
  final String title;
  final String coverAssetName;
  final int currentPage;
  final int totalPages;

  /// Favoritos
  final bool mostrarFavorito;
  final bool esFavorito;
  final VoidCallback? onToggleFavorito;

  const BookProgressCard({
    super.key,
    required this.title,
    required this.coverAssetName,
    required this.currentPage,
    required this.totalPages,
    this.mostrarFavorito = false,
    this.esFavorito = false,
    this.onToggleFavorito,
  });

  double get progressPercentage =>
      totalPages > 0 ? currentPage / totalPages : 0.0;
  String get pagesInfo => '$currentPage / $totalPages págs.';

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final progress = (progressPercentage * 100).toInt();

    return Card(
      color: const Color.fromARGB(255, 10, 10, 30),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Abriendo el libro: $title')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverImage(coverAssetName),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👉 Título + corazón a la derecha
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mostrarFavorito)
                          GestureDetector(
                            onTap: onToggleFavorito,
                            child: Icon(
                              esFavorito
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: esFavorito
                                  ? Colors.redAccent
                                  : Colors.white70,
                              size: 22,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 👉 Fila de progreso y páginas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso: $progress%',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          pagesInfo,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 👉 Barra de progreso
                    LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 8),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverAssetName) {
    final isNetworkImage = coverAssetName.startsWith('http');
    final ImageProvider imageProvider = isNetworkImage
        ? NetworkImage(coverAssetName)
        : AssetImage(coverAssetName);

    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }
}
