// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/widgets/custom_search_delegate.dart';
import 'package:leotest/widgets/book_list_widget.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/book_service.dart';
import 'package:leotest/services/stats_service.dart';
import 'package:leotest/services/notification_service.dart'; 
import 'package:leotest/models/notification.dart'; // Importado

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final Future<List<Category>> _futureCategories =
      BookService.obtenerCategorias();
      
  // Futures para datos dinámicos
  late Future<int> _futureBooksRead;
  late Future<int> _futureCurrentStreak;
  late Future<List<AppNotification>> _futureNotifications; // Nuevo Future

  @override
  void initState() {
    super.initState();
    _loadStatsAndNotifications();
  }
  
  // Función para carga/recarga de estadísticas y notificaciones
  void _loadStatsAndNotifications() {
     if (mounted) {
        setState(() {
          _futureBooksRead = StatsService.fetchGeneralStats().then((stats) => stats.librosLeidos ?? 0);
          _futureCurrentStreak = StatsService.fetchCurrentStreak();
          _futureNotifications = NotificationService.fetchNotifications();
        });
     }
  }

  // Widget para el Panel de Notificaciones (HU-1.3)
  void _showNotificationPanel(BuildContext context, List<AppNotification> notifications) {
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
                            notification.tipo == 'mision' ? Icons.check_circle_outline : Icons.notifications_none,
                            color: isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
                          ),
                          title: Text(notification.mensaje, style: TextStyle(color: isUnread ? Colors.white : Colors.white70, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text('Tipo: ${notification.tipo} - ${notification.fecha}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: isUnread ? const Icon(Icons.circle, size: 10, color: Colors.redAccent) : null,
                          onTap: () async {
                            if (isUnread) {
                              await NotificationService.markAsRead(notification.id);
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
    const backgroundColor = Color.fromARGB(255, 3, 0, 12);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
        title: Text(
          'LeoTest',
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor),
        ),
        actions: [
          // Integración: Botón de Notificaciones con Conteo (HU-1.3)
          FutureBuilder<List<AppNotification>>(
            future: _futureNotifications,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => n.estado != 'leída').length;

              return IconButton(
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white70, size: 28),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
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
                    const Icon(Icons.local_fire_department, color: Colors.orange),
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
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final categories = snapshot.data!;
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

  /// Obtener libros por categoría
  Future<List<Book>> _fetchBooks(int categoryId) async {
    return BookService.buscarLibros(categoriaId: categoryId.toString());
  }


  /// Construye un carrusel por categoría
  Widget _buildCategoryCarousel(Category category) {
    return FutureBuilder<List<Book>>(
      future: _fetchBooks(category.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.grey),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return BookListWidget(
            category: category, 
            books: snapshot.data!
          );
        }

        if (snapshot.hasData && snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'No hay libros en esta categoría por ahora.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 20.0),
            child: Text(
              'Error al cargar ${category.name}: ${snapshot.error}',
              style: const TextStyle(color: Colors.orange),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}