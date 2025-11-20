// lib/widgets/book_list_widget.dart

import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/views/book_detail_view.dart';
// ✅ 1. IMPORTAR LA NUEVA VISTA Y EL MODELO CATEGORY
import 'package:leotest/views/category_detail_view.dart';
import 'package:leotest/services/book_service.dart'; // Para el modelo Category

class BookListWidget extends StatelessWidget {
  // ✅ 2. MODIFICADO: AHORA RECIBE EL OBJETO CATEGORY COMPLETO
  final Category category;
  final List<Book> books;

  /// Mostrar el icono de favorito
  final bool mostrarFavorito;

  /// Callback al tocar el corazón
  final Function(Book)? onToggleFavorito;

  /// IDs de libros favoritos
  final Set<int> favoritos;
  final int idPerfil;

  const BookListWidget({
    super.key,
    required this.category, // Modificado
    required this.books,
    required this.idPerfil,
    this.mostrarFavorito = false,
    this.onToggleFavorito,
    this.favoritos = const {},
  });

  /// Saber si un libro es favorito
  bool esFavorito(Book book) => favoritos.contains(book.idLibro);

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    const cardColor = Color.fromARGB(255, 30, 30, 30);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 3. MODIFICADO: Título de la sección ahora en un Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título
                Text(
                  category.name, // Usa el nombre de la categoría
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Botón "Ver más"
                TextButton(
                  onPressed: () {
                    // Navega a la nueva pantalla de detalles de categoría
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailView(
                          category: category,
                          idPerfil: idPerfil,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Ver más',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista horizontal de libros (sin cambios)
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final book = books[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailView(
                          book: book,
                          idPerfil: idPerfil, // 🔥 PASAMOS EL PERFIL AQUÍ
                        ),
                      ),
                    );
                  },

                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Portada del libro
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                              image: (book.portada.isNotEmpty)
                                  ? DecorationImage(
                                      image: book.portada.startsWith('http')
                                          ? NetworkImage(book.portada)
                                          : AssetImage(book.portada)
                                                as ImageProvider,
                                      fit: BoxFit.cover,
                                      // Manejo de error de imagen
                                      onError: (exception, stackTrace) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: (book.portada.isEmpty)
                                ? const Icon(
                                    Icons.book,
                                    color: Colors.white70,
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Título y autor
                        Text(
                          book.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          book.autor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
