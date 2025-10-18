import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/views/book_detail_view.dart'; // Importación necesaria para la navegación

class BookListWidget extends StatelessWidget {
  final String title;
  final List<Book> books;

  const BookListWidget({super.key, required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    // Usamos el color de acento para el título y colores oscuros para el fondo/tarjetas
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface; 

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la Clase (Ej. CLASE 1) - Adaptado al tema oscuro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor, // Usamos el color de acento naranja para destacar
              ),
            ),
          ),
          
          // Lista Horizontal de Libros
          SizedBox(
            height: 190, // Aumentado ligeramente para el título y el autor
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final book = books[index];
                
                return GestureDetector(
                  // --- LÓGICA DE NAVEGACIÓN (HU-6.2) ---
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailView(book: book),
                      ),
                    );
                  },
                  // ------------------------------------
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simulación de Portada (Ahora usa el coverUrl del modelo)
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              // Usamos el color de tarjeta para el fondo, o un color de placeholder
                              color: cardColor, 
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                              // Intenta cargar la imagen desde assets
                              image: DecorationImage(
                                image: AssetImage(book.coverUrl), 
                                fit: BoxFit.cover,
                                // Si la imagen no carga, el color de fondo cardColor servirá como placeholder.
                                onError: (exception, stackTrace) {
                                  // Puedes poner un ícono o un texto simple si falla la carga.
                                },
                              ),
                            ),
                            alignment: Alignment.center,
                            // Texto de emergencia si la portada no carga (visible en cardColor)
                            child: book.coverUrl.isEmpty || !book.coverUrl.startsWith('assets') 
                                ? Text(
                                    book.title.split(' ')[0], 
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Título del Libro (Color blanco para tema oscuro)
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        // Autor (Color gris claro para tema oscuro)
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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