// lib/views/profile_view.dart

import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Área de avatar (círculo Naranja)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // Naranja de acento 
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text('Alejandro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // Botones de navegación (simulando Progreso, Evaluaciones, etc.)
            _buildProfileOption(context, 'Progreso', Icons.timeline), // HU-24
            _buildProfileOption(context, 'Evaluaciones', Icons.checklist), // HU-25
            _buildProfileOption(context, 'Estadísticas', Icons.bar_chart), // HU-26
            _buildProfileOption(context, 'Social', Icons.people_outline), // HU-27
            _buildProfileOption(context, 'Ajustes', Icons.settings), // Configuración / Privacidad HU-28
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF333333), // Gris de borde/separador 
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFAAAAAA)),
          onTap: () {
            // Lógica de navegación a la vista correspondiente
          },
        ),
      ),
    );
  }
}