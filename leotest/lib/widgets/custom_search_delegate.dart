import 'package:flutter/material.dart';

// SearchDelegate es la forma estándar de crear la funcionalidad de búsqueda en Flutter
class CustomSearchDelegate extends SearchDelegate {
  // Ejemplos de sugerencias (deberían ser libros destacados del backend)
  final List<String> searchTerms = [
    "Cien años de soledad",
    "El Quijote",
    "Física Cuántica para Dummies",
    "Programación en Dart",
  ];

  @override
  // Botones a la derecha del AppBar de búsqueda
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Limpia el término de búsqueda
        },
      ),
    ];
  }

  @override
  // Botón a la izquierda del AppBar de búsqueda (generalmente el botón "Back")
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Cierra la ventana de búsqueda
      },
    );
  }

  @override
  // Resultados de la búsqueda (lo que se muestra después de presionar Enter)
  Widget buildResults(BuildContext context) {
    final results = searchTerms.where((term) => term.toLowerCase().contains(query.toLowerCase())).toList();
    
    // Aquí es donde harías la llamada a tu API para obtener los resultados reales
    return Center(
      child: Text('Buscando: "$query". Resultados encontrados: ${results.length}'),
    );
  }

  @override
  // Sugerencias de búsqueda (se muestran mientras el usuario escribe)
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? searchTerms
        : searchTerms.where((term) => term.toLowerCase().startsWith(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.book),
          title: Text(suggestionList[index]),
          onTap: () {
            query = suggestionList[index];
            showResults(context); // Muestra los resultados al tocar la sugerencia
          },
        );
      },
    );
  }
}