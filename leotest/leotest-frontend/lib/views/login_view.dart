import 'package:flutter/material.dart';
import 'package:leotest/main.dart'; // Asumiendo que MainScreen está aquí o es una vista clave
import 'package:leotest/views/registration_view.dart';
import 'package:leotest/services/auth_service.dart'; // <-- Servicio de autenticación
import 'package:leotest/views/admin_home_view.dart'; // <-- Vista de administrador
import 'package:leotest/views/home_view.dart'; // <-- Vista de usuario estándar

// 1. Convertir a StatefulWidget para manejar el estado y la lógica de login
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controladores de texto para capturar la entrada del usuario
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Estado para el indicador de carga
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. Lógica de Login y Navegación por Roles
  Future<void> _handleLogin() async {
    // Validaciones básicas (puedes añadir más si usas Form y GlobalKey)
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa usuario y contraseña.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    // Llamar al servicio de autenticación
    final result = await AuthService.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      Widget targetView;
      
      // La API devuelve "administrador" o "usuario" (se compara en minúsculas por seguridad)
      if (result.role?.toLowerCase() == 'administrador') {
        targetView = const AdminHomeView();
      } else {
        // Asumiendo que MainScreen es la vista principal del usuario normal, 
        // o si HomeView es la vista principal. Usa la que corresponda a tu estructura.
        // Si MainScreen es un wrapper con BottomNavigationBar, úsalo. Si HomeView es el contenido, úsalo.
        targetView = const MainScreen(); 
      }

      // Navegar y eliminar todas las rutas anteriores
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetView),
        (Route<dynamic> route) => false,
      );
    } else {
      // Mostrar mensaje de error del API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Error de autenticación desconocido.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // 3. Modificación del Widget _buildInputField para usar Controllers
  Widget _buildInputField(
    BuildContext context, 
    {required String label, required IconData icon, required Color cardColor, bool obscureText = false, required TextEditingController controller, TextInputType keyboardType = TextInputType.text}
  ) {
    return TextFormField(
      controller: controller, // <-- Asignar el controlador
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface; 

    return Scaffold(
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
                color: primaryColor,
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
                label: 'Usuario',
                icon: Icons.person,
                cardColor: cardColor,
                controller: _usernameController, // <-- USAR CONTROLADOR
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // --- 3. Campo de Contraseña ---
              _buildInputField(
                context, 
                label: 'Contraseña',
                icon: Icons.lock,
                cardColor: cardColor,
                controller: _passwordController, // <-- USAR CONTROLADOR
                obscureText: true,
              ),
              const SizedBox(height: 40),

              // --- 4. Botón de Inicio de Sesión ---
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : ElevatedButton(
                      onPressed: _handleLogin, // <-- LLAMAR A LA LÓGICA DE LOGIN
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
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
                          color: Colors.black,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // --- 5. Opción de Registro ---
              TextButton(
                onPressed: () {
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
}