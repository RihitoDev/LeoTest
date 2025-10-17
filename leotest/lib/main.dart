// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Añade esto a tu pubspec.yaml: google_fonts: ^x.x.x

// Importa las vistas que crearemos
import 'views/home_view.dart';
import 'views/profile_view.dart';

void main() {
  runApp(const LeoTestApp());
}

class LeoTestApp extends StatelessWidget {
  const LeoTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeoTest Reader App',
      theme: ThemeData(
        // FONDO: Usa el #1A1A1A para el fondo principal
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        // ESQUEMA DE COLOR
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF39C12), // ACENTO PRIMARIO NARANJA 
          surface: Color(0xFF1A1A1A), // Fondo de elementos UI 
        ),
        // ESTILO DE TEXTO
        textTheme: GoogleFonts.poppinsTextTheme( // Usa una fuente moderna y legible
          Theme.of(context).textTheme.apply(
            bodyColor: const Color(0xFFE0E0E0), // Texto Claro Principal 
            displayColor: const Color(0xFFE0E0E0),
          ),
        ),
        // CONFIGURACIÓN GLOBAL
        useMaterial3: true,
      ),
      home: const MainNavigator(), 
    );
  }
}

// Esta clase va al final de lib/main.dart

// Widget para manejar la navegación principal (BottomNavigationBar) (HU-7.1, 7.2)
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  // Las vistas principales, mapeadas a los botones del menú [cite: 81, 145, 151, 140, 105]
  final List<Widget> _views = const [
    HomeView(),              // Home (Página Principal/Menú) [cite: 81]
    Placeholder(),           // Biblioteca (Boton de Lista de Libros) [cite: 145]
    Placeholder(),           // Agregar Libro (Boton de Agregar Libro) [cite: 151]
    Placeholder(),           // Misiones (Misiones Diarias de Lectura) [cite: 140]
    ProfileView(),           // Perfil del Usuario [cite: 105]
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _views[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Mantiene los iconos fijos
        backgroundColor: const Color(0xFF121212), // Fondo más oscuro para la barra 
        selectedItemColor: Theme.of(context).colorScheme.primary, // Naranja para el activo 
        unselectedItemColor: const Color(0xFFAAAAAA), // Gris suave para el inactivo 
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          // Iconos según la imagen de referencia
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'Lista'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Agregar'),
          BottomNavigationBarItem(icon: Icon(Icons.star_outline), label: 'Misiones'), // Usamos star para misiones
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}