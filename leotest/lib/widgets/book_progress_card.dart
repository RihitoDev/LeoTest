// lib/widgets/book_progress_card.dart

import 'package:flutter/material.dart';

class BookProgressCard extends StatelessWidget {
  final String title;
  final String coverAssetName; // Usaremos un path a un asset para la carátula
  final int currentPage;
  final int totalPages;

  const BookProgressCard({
    super.key,
    required this.title,
    required this.coverAssetName,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final progress = currentPage / totalPages;
    
    // Color de la barra de progreso (verde brillante como en el ejemplo)
    const Color progressColor = Color.fromARGB(255, 30, 255, 100); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // Fondo oscuro de card
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Contenedor de la carátula (Usando un círculo como placeholder basado en el diseño)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                // Simulación de carátula de libro (usando color y sombra)
                color: Colors.white, 
                shape: BoxShape.circle,
                image: DecorationImage(
                  // Nota: Aquí usarías Image.asset(coverAssetName), pero para simplificar, usaremos un color temporal.
                  image: AssetImage(coverAssetName), // Asume que tienes assets de las carátulas
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            
            // Título y Progreso
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título del Libro
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Barra de Progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            
            // Conteo de Páginas
            Text(
              '${currentPage}/${totalPages}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}