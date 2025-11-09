import 'package:flutter/material.dart';
import 'package:leotest/widgets/custom_search_delegate.dart';
import 'package:leotest/widgets/book_list_widget.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/book_service.dart';
import 'package:leotest/services/stats_service.dart';
import 'package:leotest/services/notification_service.dart';
import 'package:leotest/models/notification.dart';
import 'package:leotest/views/my_books_view.dart';
import 'package:leotest/views/missions_view.dart';
import 'package:leotest/views/profile_view.dart';
import 'package:leotest/models/perfil.dart';

class HomeView extends StatefulWidget {
  final Perfil perfil;

  const HomeView({super.key, required this.perfil});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  late final Future<List<Category>> _futureCategories =
      BookService.obtenerCategorias();
  late Future<int> _futureBooksRead;
  late Future<int> _futureCurrentStreak;
  late Future<List<AppNotification>> _futureNotifications;

  @override
  void initState() {
    super.initState();
    _loadStatsAndNotifications();
  }

  void _loadStatsAndNotifications() {
    if (mounted) {
      setState(() {
        _futureBooksRead = StatsService.fetchGeneralStats().then(
          (stats) => stats.librosLeidos ?? 0,
        );
        _futureCurrentStreak = StatsService.fetchCurrentStreak();
        _futureNotifications = NotificationService.fetchNotifications();
      });
    }
  }

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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break; // Ya estás en Home
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyBooksView(perfil: widget.perfil)),
        );
        break;

      case 2:
        // Ejemplo: abrir vista para agregar libro
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Agregar libro'),
            content: Text('Aquí puedes implementar el formulario de agregar.'),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MissionsView()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileView(perfil: widget.perfil)),
        );
        break;
    }
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
          'Hola, ${widget.perfil.nombre} 👋',
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor),
        ),
        actions: [
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
          FutureBuilder<int>(
            future: _futureBooksRead,
            builder: (context, snapshot) {
              final booksRead = snapshot.data ?? 0;
              return Row(
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
              );
            },
          ),
          const SizedBox(width: 12),
          FutureBuilder<int>(
            future: _futureCurrentStreak,
            builder: (context, snapshot) {
              final streak = snapshot.data ?? 0;
              return Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
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

                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
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

                  return Column(
                    children: categories
                        .map((category) => _buildCategoryCarousel(category))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),

      /// 🔽 Aquí añadimos la barra inferior
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[700],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1 ? Icons.menu_book : Icons.menu_book_outlined,
            ),
            label: 'Mis Libros',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 30, color: Colors.black),
            ),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 3 ? Icons.task_alt : Icons.task_alt_outlined,
            ),
            label: 'Misiones',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 4 ? Icons.person : Icons.person_outline,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Future<List<Book>> _fetchBooks(int categoryId) async {
    return BookService.buscarLibros(categoriaId: categoryId.toString());
  }

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
                  horizontal: 16,
                  vertical: 8,
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

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 20),
            child: Text(
              'Error al cargar ${category.name}: ${snapshot.error}',
              style: const TextStyle(color: Colors.orange),
            ),
          );
        }

        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'No hay libros en esta categoría por ahora.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          );
        }

        return BookListWidget(category: category, books: books);
      },
    );
  }
}
