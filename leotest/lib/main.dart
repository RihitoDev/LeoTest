import 'package:flutter/material.dart';
import 'package:leotest/views/home_view.dart';
import 'package:leotest/views/profile_view.dart';
import 'package:leotest/widgets/add_book_modal.dart'; // Importación del modal
import 'package:leotest/views/login_view.dart'; // Importación del punto de entrada
import 'package:leotest/views/my_books_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definiciones de Colores para el Tema Oscuro
    const Color accentColor = Color.fromARGB(255, 255, 166, 0); // Naranja de acento
    const Color darkBackground = Color.fromARGB(255, 3, 0, 12); // Fondo muy oscuro

    final ColorScheme customColorScheme = ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      background: darkBackground,
      surface: const Color.fromARGB(255, 15, 10, 30), // Ligeramente más claro para cardColor/surface
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'LeoTest App',
      theme: ThemeData(
        brightness: Brightness.dark, 
        primaryColor: accentColor,
        colorScheme: customColorScheme, // Usamos el esquema corregido
        scaffoldBackgroundColor: darkBackground,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white70), 
        ),
      ),
      // --- PUNTO DE ENTRADA CAMBIADO ---
      home: const LoginView(), 
    );
  }
}

// ----------------------------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // El índice de la vista actual (0 a 3). 
  // Nota: El índice 2 del navbar es la acción, no una vista aquí.
  int _selectedViewIndex = 0; 

  // Vistas (4 Vistas)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeView(), // 0: Inicio
    MyBooksView(), // 1: Mis Libros
    Text('Página de Amigos', style: TextStyle(fontSize: 30, color: Colors.white)), // 2: Amigos (Mapeado del Navbar 3)
    ProfileView(), // 3: Perfil (Mapeado del Navbar 4)
  ];

  // Muestra el AddBookModal usando showModalBottomSheet para ese look de tarjeta emergente
  void _showAddBookModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Necesario para mostrar la esquina curva
      builder: (BuildContext context) {
        return const AddBookModal(); // Usamos el widget de Modal que diseñamos
      },
    );
  }

  // Mapea el índice del navbar (0 a 4) a la acción o a la vista
  void _onItemTapped(int navbarIndex) {
    if (navbarIndex == 2) { // El índice 2 es el botón "Agregar" (Acción)
      _showAddBookModal(); 
    } else {
      setState(() {
        // Mapeo de Navbar [0, 1, 2 (Acción), 3, 4] a Vistas [0, 1, 2, 3]
        if (navbarIndex < 2) {
          _selectedViewIndex = navbarIndex; // 0 -> 0, 1 -> 1
        } else {
          _selectedViewIndex = navbarIndex - 1; // 3 -> 2 (Amigos), 4 -> 3 (Perfil)
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula el índice del Navbar que debe estar 'seleccionado'
    int currentNavbarIndex;
    if (_selectedViewIndex < 2) {
      currentNavbarIndex = _selectedViewIndex;
    } else {
      currentNavbarIndex = _selectedViewIndex + 1;
    }

    // El color primario del tema es el naranja
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedViewIndex),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Es esencial para 5 ítems
        // Fondo de la barra de navegación también oscuro
        backgroundColor: const Color.fromARGB(255, 0, 4, 8), 
        // Color del ítem seleccionado (Naranja)
        selectedItemColor: primaryColor, 
        // Color de los ítems no seleccionados
        unselectedItemColor: Colors.grey[700], 
        
        items: <BottomNavigationBarItem>[
          // 0. Inicio
          BottomNavigationBarItem(
            icon: Icon(currentNavbarIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Inicio',
          ),
          
          // 1. Mis Libros
          BottomNavigationBarItem(
            icon: Icon(currentNavbarIndex == 1 ? Icons.menu_book : Icons.menu_book_outlined),
            label: 'Mis Libros',
          ),

          // 2. Agregar (Botón de acción - CENTRAL Y DESTACADO)
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: primaryColor, // Naranja
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.5),
                    blurRadius: 10,
                  )
                ]
              ),
              child: const Icon(Icons.add, size: 30, color: Colors.black), // Icono 'más' negro sobre círculo naranja
            ),
            label: 'Agregar', 
          ),
          
          // 3. Amigos (Vista 2)
          BottomNavigationBarItem(
            icon: Icon(currentNavbarIndex == 3 ? Icons.group : Icons.group_outlined),
            label: 'Amigos',
          ),
          
          // 4. Perfil (Vista 3)
          BottomNavigationBarItem(
            icon: Icon(currentNavbarIndex == 4 ? Icons.person : Icons.person_outline),
            label: 'Perfil',
          ),
        ],
        
        currentIndex: currentNavbarIndex, 
        onTap: _onItemTapped,
      ),
    );
  }
}