import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

// Vistas
import 'package:leotest/views/home_view.dart';
import 'package:leotest/views/profile_view.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/views/my_books_view.dart';
import 'package:leotest/views/missions_view.dart';

// Widgets
import 'package:leotest/widgets/add_book_modal.dart';

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

// ===========================================================
// MAIN SCREEN
// ===========================================================

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final int? profileId;

  const MainScreen({super.key, this.initialIndex = 0, this.profileId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedViewIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedViewIndex = widget.initialIndex;
  }

  /// Lista de Vistas
  List<Widget> _buildWidgetOptions(int? profileId) {
    return <Widget>[
      HomeView(profileId: profileId),
      MyBooksView(profileId: profileId),
      MissionsView(profileId: profileId),
      ProfileView(profileId: profileId),
    ];
  }

  /// Modal para agregar libros
  void _showAddBookModal() {
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

  /// Manejo del BottomNavigationBar
  void _onItemTapped(int navbarIndex) {
    if (navbarIndex == 2) {
      _showAddBookModal();
      return;
    }

    setState(() {
      if (navbarIndex < 2) {
        _selectedViewIndex = navbarIndex;
      } else {
        _selectedViewIndex = navbarIndex - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final widgetOptions = _buildWidgetOptions(widget.profileId);

    int currentNavbarIndex = _selectedViewIndex < 2
        ? _selectedViewIndex
        : _selectedViewIndex + 1;

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(child: widgetOptions.elementAt(_selectedViewIndex)),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[700],
        currentIndex: currentNavbarIndex,
        onTap: _onItemTapped,

        items: <BottomNavigationBarItem>[
          /// Inicio
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: 'Inicio',
          ),

          /// Mis Libros
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 1
                  ? Icons.menu_book
                  : Icons.menu_book_outlined,
            ),
            label: 'Mis Libros',
          ),

          /// Agregar
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

          /// Misiones (nuevo)
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 3
                  ? Icons.task_alt
                  : Icons.task_alt_outlined,
            ),
            label: 'Misiones',
          ),

          /// Perfil
          BottomNavigationBarItem(
            icon: Icon(
              currentNavbarIndex == 4 ? Icons.person : Icons.person_outline,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
