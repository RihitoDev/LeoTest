// lib/views/category_detail_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/book_service.dart';
import 'package:leotest/views/book_detail_view.dart';

class CategoryDetailView extends StatelessWidget {
  final Category category;

  //AGREGADO: el ID del perfil del usuario
  final int idPerfil;

  const CategoryDetailView({
    super.key,
    required this.category,
    required this.idPerfil, // <-- AGREGADO
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category.name,
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
      ),
      body: Container(
        color: const Color.fromARGB(255, 3, 0, 12),
        child: FutureBuilder<List<Book>>(
          future: BookService.buscarLibros(categoriaId: category.id.toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar libros: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final books = snapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.6,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return _buildBookGridItem(context, book);
                },
              );
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No se encontraron libros en esta categoría.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookGridItem(BuildContext context, Book book) {
    const cardColor = Color.fromARGB(255, 30, 30, 30);
    final isNetworkImage = book.portada.startsWith('http');

    final ImageProvider imageProvider = (book.portada.isNotEmpty)
        ? (isNetworkImage
              ? NetworkImage(book.portada)
              : AssetImage(book.portada) as ImageProvider)
        : const AssetImage('assets/images/placeholder.png');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailView(
              book: book,
              idPerfil: idPerfil, // <-- AHORA SÍ
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
              alignment: Alignment.center,
              child: (book.portada.isEmpty)
                  ? const Icon(Icons.book, color: Colors.white70, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
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
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
