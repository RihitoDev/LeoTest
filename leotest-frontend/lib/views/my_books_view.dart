import 'package:flutter/material.dart';
import '../widgets/book_progress_card.dart';

// =========================================================================
// CLASE DUMMY PARA EL DELEGADO DE BÚSQUEDA
// Nota: Esta clase debe estar fuera de MyBooksView para evitar errores de compilación
// Reemplaza esta clase con tu CustomSearchDelegate real.
// =========================================================================

class _DummySearchDelegate extends SearchDelegate<String> {
  // Configuración de la apariencia (opcional, para que se vea bien en tema oscuro)
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Fondo oscuro
        foregroundColor: Colors.white, // Íconos y texto claro
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
    // Botón para borrar la búsqueda
    return [
      IconButton(
        icon: const Icon(Icons.clear), 
        onPressed: () => query = '',
      )
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    // Botón para cerrar el delegado de búsqueda
    return IconButton(
      icon: const Icon(Icons.arrow_back), 
      onPressed: () => close(context, ''), // Cierra la búsqueda
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    // Muestra resultados al presionar Enter/Buscar
    return Center(
      child: Text('Resultados para: "$query"', style: const TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    // Muestra sugerencias mientras el usuario escribe
    return const Center(
      child: Text('Escribe para empezar a buscar...', style: TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}

// =========================================================================
// VISTA PRINCIPAL: MYBOOKSVIEW
// =========================================================================

class MyBooksView extends StatelessWidget {
  const MyBooksView({super.key});

  // Datos de ejemplo para la lista de libros
  final List<Map<String, dynamic>> _myBooks = const [
    {
      'title': 'El día que dejó de nevar en Alaska',
      'cover': 'assets/covers/alaska_cover.png',
      'current': 107,
      'total': 204
    },
    {
      'title': 'Donde todo brilla',
      'cover': 'assets/covers/brilla_cover.png',
      'current': 163,
      'total': 204
    },
    {
      'title': 'El principito',
      'cover': 'assets/covers/principito_cover.png',
      'current': 97,
      'total': 204
    },
    {
      'title': 'Don Quijote de la mancha',
      'cover': 'assets/covers/quijote_cover.png',
      'current': 60,
      'total': 204
    },
    {
      'title': 'Borracho estaba pero me acuerdo',
      'cover': 'assets/covers/borracho_cover.png',
      'current': 18,
      'total': 204
    },
  ];

  // Variables dummy para los contadores (ajusta a tus variables reales de estado/modelo)
  final int _booksRead = 12;
  final int _currentStreak = 5;
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary; 

    return Scaffold(
      // --- CABECERA SOLICITADA (AppBar Estándar) ---
      appBar: AppBar(
        // Fondo de la AppBar también oscuro
        backgroundColor: const Color.fromARGB(255, 0, 4, 8), 
        elevation: 1, 
        automaticallyImplyLeading: false, 
        title: Text(
          'LeoTest', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: primaryColor // Naranja
          ),
        ),
        actions: <Widget>[
          // Notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          // Contador de Libros Leídos
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primaryColor), // Naranja
                Text('$_booksRead', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)), // Naranja
              ],
            ),
          ),
          // Contador de Racha (Fuego)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange), 
                Text('$_currentStreak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
          // Búsqueda
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              // Ahora usa la clase _DummySearchDelegate definida fuera de esta clase
              showSearch(
                context: context,
                delegate: _DummySearchDelegate(), 
              );
            },
          ),
        ],
      ),
      // --- FIN DE CABECERA SOLICITADA ---

      // Contenido: Lista de libros con progreso
      body: ListView.builder(
        itemCount: _myBooks.length,
        itemBuilder: (context, index) {
          final book = _myBooks[index];
          return BookProgressCard(
            title: book['title'],
            // Nota: Asegúrate de que los paths en 'cover' existan en tus assets
            coverAssetName: book['cover'],
            currentPage: book['current'],
            totalPages: book['total'],
          );
        },
      ),
    );
  }
}