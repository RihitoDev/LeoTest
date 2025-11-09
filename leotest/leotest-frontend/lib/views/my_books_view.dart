// lib/views/my_books_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/models/perfil.dart';
import '../models/book.dart';
import '../views/book_reader_view.dart';
import '../widgets/book_progress_card.dart';
import '../models/user_book_progress.dart';
import '../services/my_books_service.dart';
import '../services/favorito_service.dart';
import 'package:leotest/services/stats_service.dart';
import 'package:leotest/services/notification_service.dart'; // Importado
import 'package:leotest/models/notification.dart'; // Importado

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
  final Perfil perfil; // <-- recibe el perfil

  const MyBooksView({super.key, required this.perfil});

  @override
  State<MyBooksView> createState() => _MyBooksViewState();
}

class _MyBooksViewState extends State<MyBooksView> {
  late Future<List<UserBookProgress>> _futureUserBooks;
  Set<int> favoritosSet = {};
  late final int idPerfil;

  // Futures para datos dinámicos
  late Future<int> _futureBooksRead;
  late Future<int> _futureCurrentStreak;
  late Future<List<AppNotification>> _futureNotifications; // Nuevo Future

  bool _isDeleting = false; // Estado para evitar recargas mientras se borra

  @override
  void initState() {
    super.initState();
    idPerfil = widget.perfil.id; // usar el id del perfil recibido
    _loadStatsAndNotifications();
  }

  void _loadStatsAndNotifications() {
    if (mounted) {
      setState(() {
        _futureUserBooks = MyBooksService.getUserBooks();
        _cargarFavoritos();
        // Recargar futures de estadísticas
        _futureBooksRead = StatsService.fetchGeneralStats().then(
          (stats) => stats.librosLeidos ?? 0,
        );
        _futureCurrentStreak = StatsService.fetchCurrentStreak();
        _futureNotifications = NotificationService.fetchNotifications();
      });
    }
  }

  Future<void> _cargarFavoritos() async {
    if (!mounted) return;
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
      print('Error al actualizar favorito: $e');
      if (mounted) {
        setState(() {
          // Revertir UI
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
    if (mounted && !_isDeleting) {
      _loadStatsAndNotifications(); // Llama a la función unificada
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    UserBookProgress bookToDelete,
  ) async {
    if (_isDeleting) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Confirmar Eliminación',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar "${bookToDelete.title}" de tu biblioteca? Se perderá tu progreso de lectura.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (mounted) {
        setState(() => _isDeleting = true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eliminando "${bookToDelete.title}"...'),
          backgroundColor: Colors.orange[800],
        ),
      );

      final bool success = await MyBooksService.deleteBookProgress(
        idLibro: bookToDelete.idLibro,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
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
              content: Text(
                'Error al eliminar "${bookToDelete.title}". Inténtalo de nuevo.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // Widget para el Panel de Notificaciones (HU-1.3)
  void _showNotificationPanel(
    BuildContext context,
    List<AppNotification> notifications,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Alertas y Notificaciones',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isUnread = notification.estado != 'leída';
                        return ListTile(
                          leading: Icon(
                            notification.tipo == 'mision'
                                ? Icons.check_circle_outline
                                : Icons.notifications_none,
                            color: isUnread
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          title: Text(
                            notification.mensaje,
                            style: TextStyle(
                              color: isUnread ? Colors.white : Colors.white70,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            'Tipo: ${notification.tipo} - ${notification.fecha}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: isUnread
                              ? const Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Colors.redAccent,
                                )
                              : null,
                          onTap: () async {
                            if (isUnread) {
                              await NotificationService.markAsRead(
                                notification.id,
                              );
                              _loadStatsAndNotifications(); // Recarga para actualizar el conteo
                              Navigator.pop(modalContext); // Cierra el modal
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Mi Biblioteca',
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor),
        ),
        actions: <Widget>[
          // Integración: Botón de Notificaciones con Conteo (HU-1.3)
          FutureBuilder<List<AppNotification>>(
            future: _futureNotifications,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications
                  .where((n) => n.estado != 'leída')
                  .length;

              return IconButton(
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white70,
                      size: 28,
                    ),
                    if (unreadCount > 0)
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
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showNotificationPanel(context, notifications),
              );
            },
          ),

          // Integración: Libros Leídos
          FutureBuilder<int>(
            future: _futureBooksRead,
            builder: (context, snapshot) {
              final booksRead = snapshot.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: primaryColor),
                    Text(
                      '$booksRead',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Integración: Racha
          FutureBuilder<int>(
            future: _futureCurrentStreak,
            builder: (context, snapshot) {
              final currentStreak = snapshot.data ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    Text(
                      '$currentStreak',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            },
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
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final userBooks = snapshot.data ?? [];

            if (userBooks.isEmpty) {
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

                      if (result == true && mounted) {
                        print(
                          "Recargando biblioteca porque se guardó progreso...",
                        );
                        _reloadBooks();
                      } else {
                        print(
                          "No se recarga biblioteca (resultado: $result o widget desmontado)",
                        );
                      }
                    },
                    onDeleteTapped: () =>
                        _showDeleteConfirmationDialog(bookProgress),
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
