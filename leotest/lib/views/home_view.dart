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
    // El color de fondo del body es oscuro (Color.fromARGB(255, 3, 0, 12))

    return Scaffold(
      appBar: AppBar(
        // Fondo de la AppBar también oscuro para la apariencia unificada
        backgroundColor: const Color.fromARGB(255, 0, 4, 8), 
        elevation: 1, 
        title: Text(
          'LeoTest', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: primaryColor // Naranja
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70), // Icono claro
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primaryColor), // Naranja
                Text('$booksRead', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)), // Naranja
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
            icon: const Icon(Icons.search, color: Colors.white70), // Icono claro
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
          ),
        ],
      ),
      
      body: Container(
        color: const Color.fromARGB(255, 3, 0, 12), // Fondo oscuro
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Aquí el texto 'CLASE 1', 'CLASE 2', etc., debe ser visible.
              // El widget BookListWidget también debe usar colores claros.
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