// lib/main.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:leotest/views/home_view.dart';
import 'package:leotest/views/profile_view.dart';
import 'package:leotest/widgets/add_book_modal.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/views/my_books_view.dart';
// ✅ 1. IMPORTAR LA NUEVA VISTA DE MISIONES
import 'package:leotest/views/missions_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print('API BASE: ${dotenv.env['API_BASE']}');
  } catch (e) {
    print('Error al cargar .env: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Código del ThemeData sin cambios) ...
    const Color accentColor = Color.fromARGB(255, 255, 166, 0);
    const Color darkBackground = Color.fromARGB(255, 3, 0, 12);

    final ColorScheme customColorScheme = ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      background: darkBackground,
      surface: const Color.fromARGB(255, 15, 10, 30),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'LeoTest App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: accentColor,
        colorScheme: customColorScheme,
        scaffoldBackgroundColor: darkBackground,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white70),
        ),
      ),
      home: const LoginView(),
    );
  }
}

// ----------------------------------------------------------------------

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedViewIndex = 0;

  // Vistas disponibles
  static const List<Widget> _widgetOptions = <Widget>[
    HomeView(),
    MyBooksView(),
    // ✅ 2. MODIFICADO: Reemplazar el placeholder de Amigos por MissionsView()
    MissionsView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedViewIndex = widget.initialIndex;
  }

  // Muestra el modal para agregar un libro
  void _showAddBookModal() {
    // ... (Código del modal sin cambios) ...
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return const AddBookModal();
      },
    );
  }

  // Maneja los clics del BottomNavigationBar
  void _onItemTapped(int navbarIndex) {
    // ... (Código de _onItemTapped sin cambios) ...
    if (navbarIndex == 2) {
      _showAddBookModal(); // Botón central "Agregar"
    } else {
      setState(() {
        if (navbarIndex < 2) {
          _selectedViewIndex = navbarIndex;
        } else {
          _selectedViewIndex = navbarIndex - 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentNavbarIndex;
    if (_selectedViewIndex < 2) {
      currentNavbarIndex = _selectedViewIndex;
    } else {
      currentNavbarIndex = _selectedViewIndex + 1;
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedViewIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[700],
        items: <BottomNavigationBarItem>[
          // ... (Item 'Inicio' sin cambios) ...
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: 'Inicio',
          ),
          // ... (Item 'Mis Libros' sin cambios) ...
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 1
                  ? Icons.menu_book
                  : Icons.menu_book_outlined,
            ),
            label: 'Mis Libros',
          ),
          // ... (Item 'Agregar' sin cambios) ...
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 30, color: Colors.black),
            ),
            label: 'Agregar',
          ),

          // ✅ 3. MODIFICADO: Cambiar 'Amigos' por 'Misiones'
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 3
                  ? Icons.task_alt // Icono para 'Misiones'
                  : Icons.task_alt_outlined,
            ),
            label: 'Misiones', // Etiqueta 'Misiones'
          ),

          // ... (Item 'Perfil' sin cambios) ...
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 4 ? Icons.person : Icons.person_outline,
            ),
            label: 'Perfil',
          ),
        ],
        currentIndex: currentNavbarIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}