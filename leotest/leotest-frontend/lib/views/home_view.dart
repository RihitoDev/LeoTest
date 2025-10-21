// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/widgets/custom_search_delegate.dart';
import 'package:leotest/widgets/book_list_widget.dart';
import 'package:leotest/models/book.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    const int booksRead = 12;
    const int currentStreak = 5;
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Fondo del body oscuro
    const backgroundColor = Color.fromARGB(255, 3, 0, 12);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
        title: Text(
          'LeoTest',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryColor, // Naranja
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white70,
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                Text(
                  '$currentStreak',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Botón de búsqueda con estilo y acción
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
              // Listas de libros por clase
              BookListWidget(title: 'CLASE 1', books: class1Books),
              BookListWidget(title: 'CLASE 2', books: class2Books),
              BookListWidget(title: 'CLASE 3', books: class3Books),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
