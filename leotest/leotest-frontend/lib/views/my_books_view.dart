// lib/views/my_books_view.dart

import 'package:flutter/material.dart';
import '../models/book.dart';
import '../views/book_reader_view.dart';
import '../widgets/book_progress_card.dart';
import '../models/user_book_progress.dart';
import '../services/my_books_service.dart';
import '../services/favorito_service.dart';
import 'package:leotest/services/stats_service.dart';
import 'package:leotest/services/notification_service.dart';
import 'package:leotest/models/notification.dart';

// -----------------------------------------------------------------------------
// BUSCADOR
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// MYBOOKS VIEW
// -----------------------------------------------------------------------------
class MyBooksView extends StatefulWidget {
  final int? profileId;

  const MyBooksView({super.key, this.profileId});

  @override
  State<MyBooksView> createState() => _MyBooksViewState();
}

class _MyBooksViewState extends State<MyBooksView> {
  late Future<List<UserBookProgress>> _futureUserBooks;
  Set<int> favoritosSet = {};
  late int idPerfil;

  late Future<int> _futureBooksRead;
  late Future<int> _futureCurrentStreak;
  late Future<List<AppNotification>> _futureNotifications;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    idPerfil = widget.profileId ?? 0;
    _loadStatsAndNotifications();
  }

  // Carga biblioteca + stats + notificaciones
  void _loadStatsAndNotifications() {
    if (mounted) {
      setState(() {
        _futureUserBooks = MyBooksService.getUserBooks(idPerfil); // 🔹 CAMBIO 1

        _cargarFavoritos();

        _futureBooksRead = StatsService.fetchGeneralStats().then(
          (stats) => stats.librosLeidos ?? 0,
        );

        _futureCurrentStreak = StatsService.fetchCurrentStreak();

        _futureNotifications = NotificationService.fetchNotifications();
      });
    }
  }

  // Favoritos
  Future<void> _cargarFavoritos() async {
    try {
      final favoritos = await FavoritoService.obtenerFavoritos(
        idPerfil: idPerfil,
      );
      if (mounted) {
        setState(() => favoritosSet = favoritos.toSet());
      }
    } catch (e) {
      print('Error al cargar favoritos: $e');
    }
  }

  Future<void> toggleFavorito(UserBookProgress book) async {
    final eraFavorito = favoritosSet.contains(book.idLibro);

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
        await FavoritoService.quitarFavorito(
          idPerfil: idPerfil,
          idLibro: book.idLibro,
        );
      } else {
        await FavoritoService.agregarFavorito(
          idPerfil: idPerfil,
          idLibro: book.idLibro,
        );
      }
    } catch (e) {
      print("Error al actualizar favorito: $e");

      if (mounted) {
        setState(() {
          if (eraFavorito) {
            favoritosSet.add(book.idLibro);
          } else {
            favoritosSet.remove(book.idLibro);
          }
        });
      }
    }
  }

  bool esFavorito(UserBookProgress book) => favoritosSet.contains(book.idLibro);

  // Reload de la vista
  void _reloadBooks() {
    if (mounted && !_isDeleting) {
      _loadStatsAndNotifications();
    }
  }

  // Diálogo de eliminación
  Future<void> _showDeleteConfirmationDialog(
    UserBookProgress bookToDelete,
  ) async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Confirmar Eliminación',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Eliminar "${bookToDelete.title}" de tu biblioteca?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() => _isDeleting = true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eliminando "${bookToDelete.title}"...'),
        backgroundColor: Colors.orange[800],
      ),
    );

    final success = await MyBooksService.deleteBookProgress(
      idLibro: bookToDelete.idLibro,
      idPerfil: idPerfil, // 🔹 CAMBIO 2
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (!mounted) return;

    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${bookToDelete.title}" eliminado con éxito.'),
          backgroundColor: Colors.green[700],
        ),
      );
      _reloadBooks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar "${bookToDelete.title}".'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Panel de notificaciones
  void _showNotificationPanel(
    BuildContext context,
    List<AppNotification> notifications,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, controller) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Alertas y Notificaciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: notifications.length,
                      itemBuilder: (context, i) {
                        final n = notifications[i];
                        final unread = n.estado != 'leída';

                        return ListTile(
                          leading: Icon(
                            n.tipo == 'mision'
                                ? Icons.check_circle_outline
                                : Icons.notifications_none,
                            color: unread
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          title: Text(
                            n.mensaje,
                            style: TextStyle(
                              color: unread ? Colors.white : Colors.white70,
                              fontWeight: unread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Tipo: ${n.tipo} - ${n.fecha}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: unread
                              ? const Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Colors.redAccent,
                                )
                              : null,
                          onTap: () async {
                            if (unread) {
                              await NotificationService.markAsRead(n.id);
                              _loadStatsAndNotifications();
                              Navigator.pop(modalContext);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
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
        actions: [
          // Notificaciones
          FutureBuilder<List<AppNotification>>(
            future: _futureNotifications,
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              final unread = list.where((n) => n.estado != 'leída').length;

              return IconButton(
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white70,
                      size: 28,
                    ),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showNotificationPanel(context, list),
              );
            },
          ),

          // Stats: libros leídos
          FutureBuilder<int>(
            future: _futureBooksRead,
            builder: (_, snap) {
              return Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: primaryColor),
                  Text(
                    '${snap.data ?? 0}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),

          // Stats: racha
          FutureBuilder<int>(
            future: _futureCurrentStreak,
            builder: (_, snap) {
              return Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  Text(
                    '${snap.data ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _reloadBooks,
          ),

          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () =>
                showSearch(context: context, delegate: _DummySearchDelegate()),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Ocurrió un error al cargar tu biblioteca:\n${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final libros = snapshot.data ?? [];

            if (libros.isEmpty) {
              return Center(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _reloadBooks();
                    await _futureUserBooks;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'Tu biblioteca está vacía.\n¡Inicia una lectura desde el catálogo!',
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
                itemCount: libros.length,
                itemBuilder: (context, index) {
                  final progress = libros[index];

                  return BookProgressCard(
                    title: progress.title,
                    coverAssetName: progress.coverAssetName,
                    currentPage: progress.currentPage,
                    totalPages: progress.totalPages,
                    mostrarFavorito: true,
                    esFavorito: esFavorito(progress),
                    onToggleFavorito: () => toggleFavorito(progress),

                    onTap: () async {
                      final book = Book(
                        idLibro: progress.idLibro,
                        titulo: progress.title,
                        autor: progress.autor,
                        portada: progress.coverAssetName,
                        categoria: progress.categoria,
                        descripcion: progress.descripcion,
                        totalPaginas: progress.totalPages,
                        urlPdf: progress.urlPdf,
                      );

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookReaderView(
                            book: book,
                            initialPage: progress.currentPage,
                            idPerfil: idPerfil,
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        _reloadBooks();
                      }
                    },

                    onDeleteTapped: () =>
                        _showDeleteConfirmationDialog(progress),
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
