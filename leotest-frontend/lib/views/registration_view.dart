import 'package:flutter/material.dart';

class RegistrationView extends StatelessWidget {
  const RegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent, // Transparente para usar el fondo oscuro
        elevation: 0,
        // Flecha de regreso (back button) automáticamente se muestra
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Logo o Título de la Aplicación ---
              Icon(
                Icons.person_add_alt_1,
                size: 80,
                color: primaryColor, // Naranja de acento
              ),
              const SizedBox(height: 10),
              const Text(
                'Únete a LeoTest',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // --- 2. Campo de Nombre Completo ---
              _buildInputField(
                context, 
                label: 'Nombre Completo',
                icon: Icons.person_outline,
                cardColor: cardColor,
              ),
              const SizedBox(height: 20),

              // --- 3. Campo de Correo Electrónico/Usuario ---
              _buildInputField(
                context, 
                label: 'Correo Electrónico',
                icon: Icons.email_outlined,
                cardColor: cardColor,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // --- 4. Campo de Contraseña ---
              _buildInputField(
                context, 
                label: 'Contraseña',
                icon: Icons.lock_outline,
                cardColor: cardColor,
                obscureText: true,
              ),
              const SizedBox(height: 40),

              // --- 5. Botón de Registro ---
              ElevatedButton(
                onPressed: () {
                  // Lógica de Registro (Front-end simulado)
                  Navigator.pop(context); // Vuelve a la pantalla de Login
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registro exitoso. ¡Inicia sesión!', style: TextStyle(color: primaryColor)),
                      backgroundColor: cardColor,
                    )
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
                  'REGISTRARSE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Texto negro sobre naranja
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        fillColor: cardColor,
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