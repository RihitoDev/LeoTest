// lib/views/my_books_view.dart

import 'package:flutter/material.dart';
import '../models/book.dart';
import '../views/book_reader_view.dart';
import '../widgets/book_progress_card.dart';
import '../models/user_book_progress.dart';
import '../services/my_books_service.dart';
import '../services/favorito_service.dart';

// ... (Clase _DummySearchDelegate sin cambios) ...
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
  Set<int> favoritosSet = {};
  final int idPerfil = 2; // Temporal
  final int _booksRead = 12; // Simulado
  final int _currentStreak = 5; // Simulado

  // ✅ 1. AÑADIDO: Estado para indicar si se está eliminando
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _futureUserBooks = MyBooksService.getUserBooks();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    if (!mounted) return;
    try {
      final favoritos = await FavoritoService.obtenerFavoritos(idPerfil: idPerfil);
      if (mounted) {
        setState(() => favoritosSet = favoritos.toSet());
      }
    } catch (e) {
      print('Error al cargar favoritos: $e');
    }
  }

  Future<void> toggleFavorito(UserBookProgress book) async {
    final bool eraFavorito = favoritosSet.contains(book.idLibro);
    if (mounted) {
      setState(() {
        if (eraFavorito) {
          favoritosSet.remove(book.idLibro);
        } else {
          favoritosSet.add(book.idLibro);
        }
      });
    }

    try {
      if (eraFavorito) {
        await FavoritoService.quitarFavorito(idPerfil: idPerfil, idLibro: book.idLibro);
      } else {
        await FavoritoService.agregarFavorito(idPerfil: idPerfil, idLibro: book.idLibro);
      }
    } catch (e) {
      print('Error al actualizar favorito: $e');
      if (mounted) {
        setState(() { // Revertir UI
          if (eraFavorito) {
            favoritosSet.add(book.idLibro);
          } else {
            favoritosSet.remove(book.idLibro);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar favorito.')),
        );
      }
    }
  }

  bool esFavorito(UserBookProgress book) => favoritosSet.contains(book.idLibro);

  void _reloadBooks() {
    if (mounted && !_isDeleting) { // Solo recarga si no está en proceso de borrado
      setState(() {
        _futureUserBooks = MyBooksService.getUserBooks();
        _cargarFavoritos();
      });
    }
  }

  // ✅ --- INICIO DE NUEVA FUNCIÓN ---
  /// Muestra el diálogo de confirmación y maneja la eliminación.
  Future<void> _showDeleteConfirmationDialog(UserBookProgress bookToDelete) async {
    // Evita múltiples diálogos si ya se está eliminando
    if (_isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // El usuario debe elegir una opción
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface, // Fondo oscuro
          title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
          content: Text(
            '¿Estás seguro de que quieres eliminar "${bookToDelete.title}" de tu biblioteca? Se perderá tu progreso de lectura.',
             style: const TextStyle(color: Colors.white70)
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Devuelve false al cancelar
              },
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Devuelve true al confirmar
              },
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó (confirmed == true)
    if (confirmed == true) {
      if(mounted) {
        setState(() => _isDeleting = true); // Activa el indicador de borrado
      }

      // Muestra un SnackBar indicando que se está eliminando
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eliminando "${bookToDelete.title}"...'),
          backgroundColor: Colors.orange[800],
        ),
      );

      // Llama al servicio para eliminar el libro
      final bool success = await MyBooksService.deleteBookProgress(idLibro: bookToDelete.idLibro);

      // Quita el SnackBar de "eliminando"
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
          setState(() => _isDeleting = false); // Desactiva el indicador

          if (success) {
            // Muestra mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${bookToDelete.title}" eliminado con éxito.'),
                backgroundColor: Colors.green[700],
              ),
            );
            // Recarga la lista de libros para reflejar el cambio
            _reloadBooks();
          } else {
            // Muestra mensaje de error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al eliminar "${bookToDelete.title}". Inténtalo de nuevo.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
      }
    }
  }
  // ✅ --- FIN DE NUEVA FUNCIÓN ---


  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        // ... (AppBar sin cambios) ...
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
                  '$_booksRead', // Simulado
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
                  '$_currentStreak', // Simulado
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refrescar biblioteca',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _reloadBooks,
          ),
          IconButton(
            tooltip: 'Buscar en biblioteca',
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
            // ... (Manejo de estados de carga y error sin cambios) ...
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Ocurrió un error al cargar tu biblioteca:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

             final userBooks = snapshot.data ?? [];

             if (userBooks.isEmpty) {
              return Center( // Envuelto en Center para asegurar centrado
                child: RefreshIndicator( // Añadido RefreshIndicator aquí también
                   onRefresh: () async {
                      _reloadBooks();
                      await _futureUserBooks;
                   },
                  child: ListView( // Usar ListView para que RefreshIndicator funcione
                     physics: const AlwaysScrollableScrollPhysics(),
                     children: const [
                       Padding(
                         padding: EdgeInsets.all(30.0),
                         child: Text(
                           'Tu biblioteca está vacía. ¡Inicia una lectura desde el catálogo principal!',
                           style: TextStyle(color: Colors.white70, fontSize: 18),
                           textAlign: TextAlign.center,
                         ),
                       ),
                     ],
                   ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                 _reloadBooks();
                 await _futureUserBooks;
              },
              color: primaryColor,
              backgroundColor: const Color.fromARGB(255, 10, 10, 30),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: userBooks.length,
                itemBuilder: (context, index) {
                  final bookProgress = userBooks[index];
                  return BookProgressCard(
                    title: bookProgress.title,
                    coverAssetName: bookProgress.coverAssetName,
                    currentPage: bookProgress.currentPage,
                    totalPages: bookProgress.totalPages,
                    mostrarFavorito: true,
                    esFavorito: esFavorito(bookProgress),
                    onToggleFavorito: () => toggleFavorito(bookProgress),

                    onTap: () async {
                      final bookToOpen = Book(
                        idLibro: bookProgress.idLibro,
                        titulo: bookProgress.title,
                        autor: bookProgress.autor,
                        portada: bookProgress.coverAssetName,
                        categoria: bookProgress.categoria,
                        descripcion: bookProgress.descripcion,
                        totalPaginas: bookProgress.totalPages,
                        urlPdf: bookProgress.urlPdf,
                      );

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookReaderView(
                            book: bookToOpen,
                            initialPage: bookProgress.currentPage,
                          ),
                        ),
                      );

                      if (result == true && mounted) { // Verifica mounted
                        print("Recargando biblioteca porque se guardó progreso...");
                        _reloadBooks();
                      } else {
                         print("No se recarga biblioteca (resultado: $result o widget desmontado)");
                      }
                    },
                    // ✅ 2. PASAR EL CALLBACK DE ELIMINACIÓN
                    onDeleteTapped: () => _showDeleteConfirmationDialog(bookProgress),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}