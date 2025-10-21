import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Datos y Preferencias'),
        backgroundColor: cardColor, // Un color oscuro para la AppBar
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Datos Personales
            _buildSectionTitle(context, 'Datos Personales'),
            _buildEditField('Nombre de Usuario', 'Alejandro', Icons.person, cardColor),
            _buildEditField('Email', 'alejandro.u@example.com', Icons.email, cardColor),
            _buildEditField('Contraseña', '********', Icons.lock, cardColor, obscureText: true),
            
            const SizedBox(height: 30),

            // Sección de Preferencias de Lectura
            _buildSectionTitle(context, 'Preferencias de Lectura'),
            _buildPreferenceToggle('Racha de Lectura Activa', true, cardColor),
            _buildPreferenceToggle('Recibir Notificaciones', false, cardColor),

            const SizedBox(height: 30),
            
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Lógica para guardar los cambios en la base de datos
                  Navigator.pop(context); // Vuelve a la vista de perfil
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('¡Datos guardados con éxito!', style: TextStyle(color: primaryColor)))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Guardar Cambios', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildEditField(String label, String initialValue, IconData icon, Color cardColor, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white70),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          fillColor: cardColor,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceToggle(String label, bool value, Color cardColor) {
    // Nota: Para que este Toggle cambie de estado, necesitaría ser un StatefulWidget.
    // Por ahora, solo simula la apariencia en un StatelessWidget.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SwitchListTile(
          title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          value: value,
          onChanged: (newValue) {
            // Lógica para cambiar el estado de la preferencia
          },
          activeColor: Colors.green, // Puedes usar tu primaryColor o verde para 'on'
        ),
      ),
    );
  }
}