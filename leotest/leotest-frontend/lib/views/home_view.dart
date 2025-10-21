// home_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/widgets/custom_search_delegate.dart';
import 'package:leotest/widgets/book_list_widget.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/book_service.dart'; 

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Estado para manejar la llamada a la API
  late Future<List<Book>> _futureAllBooks;

  @override
  void initState() {
    super.initState();
    // Iniciar la carga de todos los libros de la API
    _futureAllBooks = BookService.buscarLibros();
  }

  @override
  Widget build(BuildContext context) {
    const int booksRead = 12;
    const int currentStreak = 5;
    final primaryColor = Theme.of(context).colorScheme.primary;
    const backgroundColor = Color.fromARGB(255, 3, 0, 12);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
        title: Text(
          'LeoTest',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
        actions: <Widget>[
          // ... (Tus IconButtons existentes) ...
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primaryColor),
                Text('$booksRead', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                Text('$currentStreak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
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
            children: [
              const SizedBox(height: 20),


              FutureBuilder<List<Book>>(
                future: _futureAllBooks,
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
                      child: Text(
                        'Error de conexión: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } 
                  
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final allBooks = snapshot.data!;
                    
                    return Column(
                      children: [
                        // Muestra todos los libros obtenidos de la API
                        BookListWidget(title: 'Libros Disponibles', books: allBooks),

                      ],
                    );

                  } else {
                    return const Center(
                      child: Text(
                        'No se encontraron libros en la base de datos.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
}