// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/widgets/custom_search_delegate.dart';
import 'package:leotest/widgets/book_list_widget.dart';
import 'package:leotest/models/book.dart'; 
import 'package:leotest/services/book_service.dart'; 

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // CORRECCIÓN: Inicializa la variable directamente.
  // Será un Future que contendrá la lista de todas las categorías.
  late final Future<List<Category>> _futureCategories = BookService.obtenerCategorias();

  @override
  void initState() {
    super.initState();
    // No necesitamos inicializar _futureCategories aquí gracias a la corrección 'late final'
  }
  
  // Función para obtener libros, filtrados por ID de categoría
  Future<List<Book>> _fetchBooks(int categoryId) async {
    final categoryIdString = categoryId.toString();
    return BookService.buscarLibros(categoriaId: categoryIdString);
  }

  @override
  Widget build(BuildContext context) {
    const int booksRead = 12;
    const int currentStreak = 5;
    final primaryColor = Theme.of(context).colorScheme.primary;
    const backgroundColor = Color.fromARGB(255, 3, 0, 12);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
        title: Text(
          'LeoTest',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white70), onPressed: () {},),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primaryColor),
                Text('$booksRead', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                Text('$currentStreak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Buscar libros',
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              showSearch(context: context, delegate: CustomSearchDelegate());
            },
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // FUTUREBUILDER PRINCIPAL: Carga todas las categorías
              FutureBuilder<List<Category>>(
                future: _futureCategories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    );
                  } 
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error al cargar categorías: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } 
                  
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final categories = snapshot.data!;
                    
                    // Itera sobre CADA categoría y construye un carrusel
                    return Column(
                      children: categories.map((category) {
                        return _buildCategoryCarousel(category);
                      }).toList(),
                    );

                  } else {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No se encontraron categorías disponibles.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: Muestra un carrusel por categoría
  Widget _buildCategoryCarousel(Category category) {
    return FutureBuilder<List<Book>>(
      // Llamada a la API para obtener los libros de esta categoría
      future: _fetchBooks(category.id), 
      builder: (context, snapshot) {
        
        // Estado de carga para cada carrusel
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  category.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(color: Colors.grey)),
              ),
            ],
          );
        }

        // Si hay libros, muestra el widget del carrusel (BookListWidget)
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return BookListWidget(
            title: category.name, 
            books: snapshot.data!,
          );
        }
        
        // Si no hay libros en esta categoría, lo omite o muestra un mensaje
        if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      category.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'No hay libros en esta categoría por ahora.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                ],
              ),
            );
        }

        // Manejo de errores de carga individuales por carrusel
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 20.0),
            child: Text('Error al cargar ${category.name}: ${snapshot.error}', style: const TextStyle(color: Colors.orange)),
          );
        }

        return const SizedBox.shrink(); // En caso de cualquier otro estado
      },
    );
  }
}