import 'package:flutter/material.dart';
import 'package:leotest/main.dart'; // Necesario para navegar a MainScreen
import 'package:leotest/views/registration_view.dart'; // Necesario para navegar a RegistrationView

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Usamos 'surface' para el fondo del campo de texto
    final cardColor = Theme.of(context).colorScheme.surface; 

    return Scaffold(
      // El color de fondo oscuro viene del tema global (scaffoldBackgroundColor)
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Logo o Título de la Aplicación ---
              Icon(
                Icons.menu_book_rounded,
                size: 100,
                color: primaryColor, // Naranja de acento
              ),
              const SizedBox(height: 10),
              const Text(
                'LeoTest',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),

              // --- 2. Campo de Correo Electrónico/Usuario ---
              _buildInputField(
                context, 
                label: 'Correo Electrónico',
                icon: Icons.person,
                cardColor: cardColor,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // --- 3. Campo de Contraseña ---
              _buildInputField(
                context, 
                label: 'Contraseña',
                icon: Icons.lock,
                cardColor: cardColor,
                obscureText: true,
              ),
              const SizedBox(height: 40),

              // --- 4. Botón de Inicio de Sesión ---
              ElevatedButton(
                onPressed: () {
                  // Navega a MainScreen y reemplaza LoginView (para evitar el regreso)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // Fondo naranja
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'INICIAR SESIÓN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Texto negro sobre naranja
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 5. Opción de Registro ---
              TextButton(
                onPressed: () {
                  // Navega a RegistrationView (permite el regreso)
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const RegistrationView())
                  );
                },
                child: Text(
                  '¿No tienes cuenta? Regístrate',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir los campos de entrada
  Widget _buildInputField(
    BuildContext context, 
    {required String label, required IconData icon, required Color cardColor, bool obscureText = false, TextInputType keyboardType = TextInputType.text}
  ) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: Theme.of(context).colorScheme.primary, // Cursor naranja
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        fillColor: cardColor, // Color de fondo del campo
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), // Borde naranja al enfocar
        ),
      ),
    );
  }
}