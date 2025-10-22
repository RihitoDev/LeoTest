import 'package:flutter/material.dart';
import '../widgets/book_progress_card.dart';
import '../models/user_book_progress.dart'; // Importar
import '../services/my_books_service.dart'; // Importar

// =========================================================================
// CLASE DUMMY PARA EL DELEGADO DE BÚSQUEDA (sin cambios)
// =========================================================================

class _DummySearchDelegate extends SearchDelegate<String> {
  // ... (código del delegado de búsqueda sin cambios)
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
      return [
         IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
      ];
   }
   
   @override
   Widget buildLeading(BuildContext context) {
      return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
   }
   
   @override
   Widget buildResults(BuildContext context) {
      return Center(
         child: Text('Resultados para: "$query"', style: const TextStyle(fontSize: 20, color: Colors.white)),
      );
   }
   
   @override
   Widget buildSuggestions(BuildContext context) {
      return const Center(
         child: Text('Escribe para empezar a buscar...', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
   }
}


// =========================================================================
// VISTA PRINCIPAL: MYBOOKSVIEW (CONVERTIDA A STATEFUL)
// =========================================================================

class MyBooksView extends StatefulWidget {
   const MyBooksView({super.key});

   @override
   State<MyBooksView> createState() => _MyBooksViewState();
}

class _MyBooksViewState extends State<MyBooksView> {
  
  // Future que contendrá la lista de libros del usuario.
  late Future<List<UserBookProgress>> _futureUserBooks;

  // Variables dummy para los contadores 
   final int _booksRead = 12;
   final int _currentStreak = 5;

  @override
  void initState() {
    super.initState();
    // Iniciar la carga de los libros
    _futureUserBooks = MyBooksService.getUserBooks();
  }

  // Función para refrescar la lista (útil al regresar de BookDetailView)
  void _reloadBooks() {
    setState(() {
      _futureUserBooks = MyBooksService.getUserBooks();
    });
  }
  
   @override
   Widget build(BuildContext context) {
      final primaryColor = Theme.of(context).colorScheme.primary; 

      return Scaffold(
         // ... (AppBar sin cambios, excepto añadiendo un botón de refrescar)
         appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 0, 4, 8), 
            elevation: 1, 
            automaticallyImplyLeading: false, 
            title: Text('Mi Biblioteca', style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor)),
            actions: <Widget>[
               IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white70), onPressed: () {}),
               Padding(padding: const EdgeInsets.only(left: 4.0), child: Row(children: [Icon(Icons.menu_book_rounded, color: primaryColor), Text('$_booksRead', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))],),),
               Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Row(children: [const Icon(Icons.local_fire_department, color: Colors.orange), Text('$_currentStreak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))],),),
          
          // Botón de refrescar para actualizar la vista después de una acción
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _reloadBooks),
          
               IconButton(icon: const Icon(Icons.search, color: Colors.white70), onPressed: () {showSearch(context: context, delegate: _DummySearchDelegate());}),
            ],
         ),

         // Contenido: FutureBuilder para cargar la lista
         body: Container(
        color: const Color.fromARGB(255, 3, 0, 12),
        child: FutureBuilder<List<UserBookProgress>>(
          future: _futureUserBooks,
          builder: (context, snapshot) {
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            
            final userBooks = snapshot.data ?? [];
            
            if (userBooks.isEmpty) {
              // Mensaje cuando la biblioteca está vacía
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text(
                    'Tu biblioteca está vacía. ¡Inicia una lectura desde el catálogo principal!',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Muestra la lista de libros del usuario
            return ListView.builder(
              itemCount: userBooks.length,
              itemBuilder: (context, index) {
                final book = userBooks[index];
                return BookProgressCard(
                  title: book.title,
                  coverAssetName: book.coverAssetName,
                  currentPage: book.currentPage,
                  totalPages: book.totalPages,
                  // Puedes añadir aquí un onTap para navegar al detalle de progreso
                );
              },
            );
          },
        ),
         ),
      );
   }
}