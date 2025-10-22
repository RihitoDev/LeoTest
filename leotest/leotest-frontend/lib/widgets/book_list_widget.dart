// lib/widgets/book_list_widget.dart (ACTUALIZADO CON NAVEGACIÓN A DETALLE)

import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/views/book_detail_view.dart'; // 🚨 NECESITAS ESTE IMPORT

class BookListWidget extends StatelessWidget {
  final String title;
  final List<Book> books;

  const BookListWidget({super.key, required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    // Si la lista de libros está vacía, no muestra el widget
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Obtenemos los colores para mantener la consistencia con el código original
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Asumo que el color de fondo de tu app es oscuro, por eso surface (fondo de la "tarjeta") puede ser el que usas en el Container.
    const cardColor = Color.fromARGB(255, 30, 30, 30); // Usaremos un color oscuro para el placeholder

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
              style: TextStyle(
                fontSize: 22, // Usaremos el tamaño de tu carrusel anterior (22)
                fontWeight: FontWeight.bold,
                color: Colors.white, // Usamos blanco para el título de la categoría
              ),
            ),
          ),

          // Lista horizontal de libros (Carrusel)
          SizedBox(
            height: 190, // Altura del carrusel (tomada de tu código)
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final book = books[index];

                return GestureDetector(
                  // 🚀 IMPLEMENTACIÓN DE LA NAVEGACIÓN
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailView(book: book),
                      ),
                    );
                  },
                  child: Container(
                    width: 100, // Ancho de la tarjeta
                    margin: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Portada del libro
                        Expanded( // Usa Expanded para que la imagen ocupe el espacio flexible
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
                                        // Mantenemos la lógica de NetworkImage/AssetImage si es necesario, 
                                        // aunque por lo general solo usarás NetworkImage.
                                        image: book.portada.startsWith('http')
                                            ? NetworkImage(book.portada)
                                            : AssetImage(book.portada) as ImageProvider,
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
                        
                        // Título del libro
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
                        
                        // Autor del libro
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