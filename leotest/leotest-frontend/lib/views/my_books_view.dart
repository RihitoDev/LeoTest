// lib/views/my_books_view.dart

import 'package:flutter/material.dart';
import '../widgets/book_progress_card.dart';
import '../models/user_book_progress.dart';
import '../services/my_books_service.dart';
import '../services/favorito_service.dart'; // ✅ Importar servicio de favoritos

// =========================================================================
// CLASE DUMMY PARA EL DELEGADO DE BÚSQUEDA
// =========================================================================
class _DummySearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        labelStyle: TextStyle(color: Colors.white),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text(
        'Resultados para: "$query"',
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text(
        'Escribe para empezar a buscar...',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

// =========================================================================
// VISTA PRINCIPAL: MYBOOKSVIEW
// =========================================================================
class MyBooksView extends StatefulWidget {
  const MyBooksView({super.key});

  @override
  State<MyBooksView> createState() => _MyBooksViewState();
}

class _MyBooksViewState extends State<MyBooksView> {
  late Future<List<UserBookProgress>> _futureUserBooks;

  /// IDs de libros favoritos
  Set<int> favoritosSet = {};

  /// ID del perfil del usuario (ejemplo, cambiar según tu sesión)
  final int idPerfil = 2;

  final int _booksRead = 12;
  final int _currentStreak = 5;

  @override
  void initState() {
    super.initState();
    _futureUserBooks = MyBooksService.getUserBooks();
    _cargarFavoritos();
  }

  /// Carga favoritos desde el backend
  Future<void> _cargarFavoritos() async {
    try {
      final favoritos = await FavoritoService.obtenerFavoritos(
        idPerfil: idPerfil,
      );
      setState(() {
        favoritosSet = favoritos.toSet();
      });
    } catch (e) {
      print('Error al cargar favoritos: $e');
    }
  }

  /// Alternar favorito
  Future<void> toggleFavorito(UserBookProgress book) async {
    try {
      if (favoritosSet.contains(book.idLibro)) {
        await FavoritoService.quitarFavorito(
          idPerfil: idPerfil,
          idLibro: book.idLibro,
        );
        setState(() => favoritosSet.remove(book.idLibro));
      } else {
        await FavoritoService.agregarFavorito(
          idPerfil: idPerfil,
          idLibro: book.idLibro,
        );
        setState(() => favoritosSet.add(book.idLibro));
      }
    } catch (e) {
      print('Error al actualizar favorito: $e');
    }
  }

  /// Saber si un libro es favorito
  bool esFavorito(UserBookProgress book) {
    return favoritosSet.contains(book.idLibro);
  }

  /// Refrescar la lista de libros
  void _reloadBooks() {
    setState(() {
      _futureUserBooks = MyBooksService.getUserBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Text(
          'Mi Biblioteca',
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white70,
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primaryColor),
                Text(
                  '$_booksRead',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                Text(
                  '$_currentStreak',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _reloadBooks,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              showSearch(context: context, delegate: _DummySearchDelegate());
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 3, 0, 12),
        child: FutureBuilder<List<UserBookProgress>>(
          future: _futureUserBooks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final userBooks = snapshot.data ?? [];

            if (userBooks.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text(
                    'Tu biblioteca está vacía. ¡Inicia una lectura desde el catálogo principal!',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: userBooks.length,
              itemBuilder: (context, index) {
                final book = userBooks[index];
                return BookProgressCard(
                  title: book.title,
                  coverAssetName: book.coverAssetName,
                  currentPage: book.currentPage,
                  totalPages: book.totalPages,
                  mostrarFavorito: true, // ✅ Muestra el corazón
                  esFavorito: esFavorito(book), // ✅ Marca según estado
                  onToggleFavorito: () => toggleFavorito(book), // ✅ Alterna
                );
              },
            );
          },
        ),
      ),
    );
  }
}
