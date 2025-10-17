// lib/widgets/book_list_widget.dart

import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';

class BookListWidget extends StatelessWidget {
  final String title;
  final List<Book> books;

  const BookListWidget({super.key, required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la Clase (Ej. CLASE 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Lista Horizontal de Libros
          SizedBox(
            height: 150, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final book = books[index];
                return GestureDetector(
                  onTap: () {
                    // Acción: Navegar a la Ficha del Libro (HU-6)
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simulación de Portada
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              book.title.split(' ')[0], // Muestra la primera palabra del título
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Título del Libro
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        // Autor
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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