import 'package:flutter/material.dart';
import 'package:leotest/services/auth_service.dart'; // Importar AuthService

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  // Controladores
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Estado
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validación mínima (puedes añadir más regex o validación de Form)
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return;
    }
    
    // Simulación de usar el nombre completo como nombre de usuario (si aplica)
    final username = _usernameController.text.trim();
    
    setState(() => _isLoading = true);
    
    final result = await AuthService.register(
      fullName: _fullNameController.text.trim(),
      username: username,
      password: _passwordController.text,
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.success) {
      // Registro exitoso: Vuelve al Login
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Registro exitoso. ¡Inicia sesión!'),
          backgroundColor: Colors.green[700],
        )
      );
    } else {
      // Muestra el mensaje de error del backend (ej. "Usuario ya está en uso")
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Error desconocido al registrar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent, 
        elevation: 0,
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
                color: primaryColor, 
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
                controller: _fullNameController,
              ),
              const SizedBox(height: 20),

              // --- 3. Campo de Correo Electrónico ---
               _buildInputField(
                context, 
                label: 'Correo Electrónico',
                icon: Icons.email_outlined,
                cardColor: cardColor,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              
              // --- 4. Campo de Usuario ---
              _buildInputField(
                context, 
                label: 'Usuario (Nombre Corto)',
                icon: Icons.person,
                cardColor: cardColor,
                controller: _usernameController,
              ),
              const SizedBox(height: 20),


              // --- 5. Campo de Contraseña ---
              _buildInputField(
                context, 
                label: 'Contraseña',
                icon: Icons.lock_outline,
                cardColor: cardColor,
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 40),

              // --- 6. Botón de Registro ---
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : ElevatedButton(
                      onPressed: _handleRegister, // Llamar a la nueva lógica
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, 
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
                          color: Colors.black, 
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
    {required String label, required IconData icon, required Color cardColor, required TextEditingController controller, bool obscureText = false, TextInputType keyboardType = TextInputType.text}
  ) {
    return TextFormField(
      controller: controller, // Usar el controlador
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: Theme.of(context).colorScheme.primary, 
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }
}