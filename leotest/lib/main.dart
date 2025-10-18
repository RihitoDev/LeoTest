import 'package:flutter/material.dart';
import 'package:leotest/views/home_view.dart';
import 'package:leotest/views/profile_view.dart';
import 'package:leotest/widgets/add_book_dialog.dart';
import 'package:leotest/views/login_view.dart'; // <-- ¡NUEVA IMPORTACIÓN!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Definiciones de colores existentes)
    const Color accentColor = Color.fromARGB(255, 255, 166, 0); 
    const Color darkBackground = Color.fromARGB(255, 3, 0, 12); 

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


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Índice de la vista seleccionada (0, 1, 2, 3)
  // 0=Inicio, 1=Mis Libros, 2=Amigos, 3=Perfil
  int _selectedViewIndex = 0;

  // Vistas (4 Vistas)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeView(), // 0: Inicio
    Text('Página de Mis Libros', style: TextStyle(fontSize: 30, color: Colors.white)), // 1: Mis Libros
    Text('Página de Amigos', style: TextStyle(fontSize: 30, color: Colors.white)), // 2: Amigos
    ProfileView(), // 3: Perfil
  ];

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddBookDialog();
      },
    );
  }

  // Mapea el índice del navbar (0 a 4) a la acción o a la vista
  void _onItemTapped(int navbarIndex) {
    if (navbarIndex == 2) { // El índice 2 es el botón "Agregar" (Acción)
      _showAddBookDialog(); 
    } else {
      setState(() {
        // Mapeo: 0, 1, [2], 3, 4 -> 0, 1, [Acción], 2, 3
        if (navbarIndex < 2) {
          _selectedViewIndex = navbarIndex; // 0 o 1
        } else {
          _selectedViewIndex = navbarIndex - 1; // 3 -> 2, 4 -> 3
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mapea el índice de la vista al índice del navbar para que el ícono esté seleccionado
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
            icon: Icon(_selectedViewIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Inicio',
          ),
          
          // 1. Mis Libros
          BottomNavigationBarItem(
            icon: Icon(_selectedViewIndex == 1 ? Icons.menu_book : Icons.menu_book_outlined),
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
          
          // 3. Amigos
          BottomNavigationBarItem(
            icon: Icon(_selectedViewIndex == 2 ? Icons.group : Icons.group_outlined),
            label: 'Amigos',
          ),
          
          // 4. Perfil
          BottomNavigationBarItem(
            icon: Icon(_selectedViewIndex == 3 ? Icons.person : Icons.person_outline),
            label: 'Perfil',
          ),
        ],
        
        currentIndex: currentNavbarIndex, 
        onTap: _onItemTapped,
      ),
    );
  }
}