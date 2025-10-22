import 'package:flutter/material.dart';

class BookProgressCard extends StatelessWidget {
  final String title;
  final String coverAssetName; // Puede ser una URL de red o un asset local
  final int currentPage;
  final int totalPages;

  const BookProgressCard({
    super.key,
    required this.title,
    required this.coverAssetName,
    required this.currentPage,
    required this.totalPages,
  });

  double get progressPercentage => totalPages > 0 ? currentPage / totalPages : 0.0;
  String get pagesInfo => '$currentPage / $totalPages págs.';

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final progress = (progressPercentage * 100).toInt();

    return Card(
      color: const Color.fromARGB(255, 10, 10, 30), // Fondo oscuro para la tarjeta
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: Implementar navegación a la vista de detalle de progreso o lector
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abriendo el libro: $title')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Portada del Libro (Imagen Corregida) ---
              _buildCoverImage(coverAssetName),
              const SizedBox(width: 15),

              // --- 2. Información y Progreso ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Progreso en Porcentaje y Páginas
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

                    // Barra de Progreso
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
              
              // Ícono de Acción (opcional)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 20),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade600,
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
    final ImageProvider imageProvider;

    if (isNetworkImage) {
      // Usar NetworkImage para URLs de Supabase/internet
      imageProvider = NetworkImage(coverAssetName);
    } else {
      // Usar AssetImage para archivos locales
      imageProvider = AssetImage(coverAssetName);
    }

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
        image: DecorationImage(
          image: imageProvider, // Usa el proveedor de imagen adecuado
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}