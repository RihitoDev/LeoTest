import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/views/book_detail_view.dart';

class BookListWidget extends StatelessWidget {
  final String title;
  final List<Book> books;

  /// Mostrar el icono de favorito
  final bool mostrarFavorito;

  /// Callback al tocar el corazón
  final Function(Book)? onToggleFavorito;

  /// IDs de libros favoritos
  final Set<int> favoritos;

  const BookListWidget({
    super.key,
    required this.title,
    required this.books,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Lista horizontal de libros
          SizedBox(
            height: 210, // Ajuste para incluir el icono debajo de la portada
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
                        builder: (context) => BookDetailView(book: book),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Portada del libro
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

                        // 🔹 Título y autor
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
