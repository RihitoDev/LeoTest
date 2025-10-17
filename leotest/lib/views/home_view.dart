// lib/views/home_view.dart

import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Simula la visualización de datos de racha/libros leídos
            const Text('LeoTest', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            // Cantidad de Libros Leídos (HU-82) y Racha (HU-83)
            Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary),
            const Text(' 19', style: TextStyle(fontSize: 14)), 
            const SizedBox(width: 10),
            Icon(Icons.local_fire_department, color: Theme.of(context).colorScheme.primary),
            const Text(' 17', style: TextStyle(fontSize: 14)), 
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          // Ícono de Notificaciones o Alertas (HU-117)
          Icon(Icons.notifications_outlined), 
          SizedBox(width: 10),
          // Ícono de Buscador / Navegador (HU-90, HU-125)
          Icon(Icons.search), 
          SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categorías', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 15),
            // Contenido simulado de Categorías (Romance, Novela, Infantil, etc.)
            for (var category in ['Romance', 'Novela', 'Infantil'])
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    // Aquí iría el Row con las portadas de los libros (HU-6.1)
                    Container(
                      height: 200,
                      color: const Color(0xFF333333), // Simula el área de libros 
                      alignment: Alignment.center,
                      child: Text('Portadas de Libros de $category', style: TextStyle(color: Color(0xFFAAAAAA))),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}