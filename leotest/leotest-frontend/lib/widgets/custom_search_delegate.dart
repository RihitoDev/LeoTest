// lib/widgets/custom_search_delegate.dart

import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/book_service.dart';
import 'package:leotest/views/book_detail_view.dart';

class CustomSearchDelegate extends SearchDelegate<Book?> {
  // 🔹 AGREGADO: ID del perfil
  final int idPerfil;

  // Almacena el ID y nombre de la categoría seleccionada
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // 🔹 Constructor que recibe idPerfil
  CustomSearchDelegate({required this.idPerfil});

  late final Future<List<Category>> _futureCategories =
      BookService.obtenerCategorias();

  @override
  String get searchFieldLabel {
    if (_selectedCategoryName != null) {
      return 'Libros en: ${_selectedCategoryName!}';
    }
    return 'Buscar libro o filtrar por área...';
  }

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
      if (_selectedCategoryId != null)
        IconButton(
          icon: const Icon(Icons.close, color: Colors.blueAccent),
          tooltip: 'Limpiar filtro',
          onPressed: () {
            _selectedCategoryId = null;
            _selectedCategoryName = null;
            query = '';
            showSuggestions(context);
          },
        ),
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white70),
          onPressed: () {
            query = '';
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
    String? titleQuery = query.isNotEmpty ? query : null;
    String? categoryIdQuery = _selectedCategoryId;

    if (categoryIdQuery != null && query.isEmpty) {
      titleQuery = null;
    } else {
      categoryIdQuery = null;
    }

    return FutureBuilder<List<Book>>(
      future: BookService.buscarLibros(
        query: titleQuery,
        categoriaId: categoryIdQuery,
      ),
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

          return Container(
            color: const Color.fromARGB(255, 3, 0, 12),
            child: ListView.builder(
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
                        builder: (context) => BookDetailView(
                          book: book,
                          idPerfil: idPerfil, // ✅ CORRECTO
                        ),
                      ),
                    );
                  },
                );
              },
            ),
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
    final backgroundColor = const Color.fromARGB(255, 3, 0, 12);

    if (_selectedCategoryId != null || query.isNotEmpty) {
      return Container(
        color: backgroundColor,
        child: const Center(
          child: Text(
            'Presiona buscar para ver los resultados.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return FutureBuilder<List<Category>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: backgroundColor,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final categories = snapshot.data!;
          categories.sort((a, b) => a.name.compareTo(b.name));

          return Container(
            color: backgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(12.0),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    'Opciones de Búsqueda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    backgroundColor: const Color.fromARGB(255, 12, 12, 29),
                    collapsedBackgroundColor: const Color.fromARGB(
                      255,
                      12,
                      12,
                      29,
                    ),
                    iconColor: Colors.blueAccent,
                    collapsedIconColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: const Text(
                      'Filtrar por Área/Categoría',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    leading: const Icon(
                      Icons.filter_list,
                      color: Colors.blueAccent,
                    ),
                    children: categories.map((category) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        tileColor: const Color.fromARGB(255, 10, 10, 25),
                        leading: const Icon(
                          Icons.folder_open,
                          color: Colors.white54,
                          size: 20,
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          _selectedCategoryId = category.id.toString();
                          _selectedCategoryName = category.name;
                          query = '';
                          showResults(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            color: backgroundColor,
            child: const Center(
              child: Text(
                'No hay categorías disponibles.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }
      },
    );
  }
}
