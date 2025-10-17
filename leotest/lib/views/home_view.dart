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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 1, 
        title: Text(
          'LeoTest', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: primaryColor
          ),
        ),
        actions: <Widget>[
          // ... (Elementos de la barra superior: Notificaciones, Libros, Racha, Búsqueda)
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
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
            icon: Icon(Icons.search, color: Colors.grey[700]),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
          ),
        ],
      ),
      
      // --- FONDO DEGRADADO (EXACTO) Y ORDENAMIENTO DE CLASES ---
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Tonalidad suave: Blanco a un azul muy pálido
            colors: [
              Colors.white, 
              Colors.lightBlue.shade50!, 
              Colors.lightBlue.shade100!.withOpacity(0.5), 
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // 1. CLASE 1 (Dos libros) - Orden Exacto
              BookListWidget(title: 'CLASE 1', books: class1Books),
              
              // 2. CLASE 2 (Tres libros) - Orden Exacto
              BookListWidget(title: 'CLASE 2', books: class2Books),

              // 3. CLASE 3 (Dos libros) - Orden Exacto
              BookListWidget(title: 'CLASE 3', books: class3Books),
              
              const SizedBox(height: 50), 
            ],
          ),
        ),
      ),
    );
  }
}