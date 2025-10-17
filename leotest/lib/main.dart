import 'package:flutter/material.dart';
import 'package:leotest/views/home_view.dart';
import 'package:leotest/widgets/add_book_dialog.dart';
import 'package:leotest/views/profile_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color.fromARGB(255, 255, 166, 0); // Tono azul/cian

    return MaterialApp(
      title: 'LeoTest App',
      theme: ThemeData(
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: primaryBlue,
        ).copyWith(
          primary: primaryBlue,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 4, 8),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Índice de la vista seleccionada: 0=Inicio, 1=Mis Libros, 2=Amigos, 3=Perfil
  int _selectedViewIndex = 0;

  // Vistas (4 Vistas + 1 Acción Central = 5 ítems en el nav bar)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeView(), // 0: Inicio
    Text('Página de Mis Libros', style: TextStyle(fontSize: 30)), // 1: Mis Libros
    Text('Página de Amigos', style: TextStyle(fontSize: 30)), // 2: Amigos
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
        // Mapea los índices del navbar a las vistas reales:
        // Nav Index 0 -> View Index 0 (Inicio)
        // Nav Index 1 -> View Index 1 (Mis Libros)
        // Nav Index 3 -> View Index 2 (Amigos)
        // Nav Index 4 -> View Index 3 (Perfil)
        
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
    // Mapea el índice de la vista al índice del navbar para que el ícono esté seleccionado
    int currentNavbarIndex;
    if (_selectedViewIndex < 2) {
      currentNavbarIndex = _selectedViewIndex;
    } else {
      currentNavbarIndex = _selectedViewIndex + 1;
    }

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedViewIndex),
      ),
      
      // --- IMPLEMENTACIÓN DEL BottomNavigationBar (5 Ítems) ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Es esencial para 5 ítems
        backgroundColor: const Color.fromARGB(255, 3, 0, 12),
        selectedItemColor: Theme.of(context).colorScheme.primary, 
        unselectedItemColor: Colors.grey[600],
        
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
                color: Theme.of(context).colorScheme.primary, 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.0),
                    blurRadius: 10,
                  )
                ]
              ),
              child: const Icon(Icons.add, size: 30, color: Colors.black), 
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