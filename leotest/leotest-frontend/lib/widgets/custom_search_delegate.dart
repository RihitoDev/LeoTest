import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/book_service.dart';
import 'package:leotest/views/book_detail_view.dart';

class CustomSearchDelegate extends SearchDelegate<Book?> {
  List<Book> searchResults = [];

  @override
  String get searchFieldLabel => 'Buscar libro...';

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(color: Colors.white70, fontSize: 16);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 0, 4, 8),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
      textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white)),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white70),
          onPressed: () {
            query = '';
            searchResults.clear();
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white70),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Book>>(
      future: BookService.buscarLibros(titulo: query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al buscar libros: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final books = snapshot.data!;
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isNetworkImage = book.portada.startsWith('http');

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isNetworkImage
                      ? Image.network(
                          book.portada,
                          width: 55,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                              ),
                        )
                      : Image.asset(
                          book.portada,
                          width: 55,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                ),
                title: Text(
                  book.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  book.autor,
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailView(book: book),
                    ),
                  );
                },
              );
            },
          );
        } else {
          return const Center(
            child: Text(
              'No se encontraron resultados',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Puedes mostrar sugerencias locales o dejar vacío
    return const Center(
      child: Text(
        'Escribe el título del libro para buscar',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
