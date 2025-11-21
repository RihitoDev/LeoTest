import 'package:flutter/material.dart';
import 'package:leotest/main.dart';
import 'package:leotest/views/registration_view.dart';
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/services/profile_service.dart';
import 'package:leotest/views/profile_editor_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================================================================
  // LÓGICA DE LOGIN
  // ================================================================
  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa usuario y contraseña.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      // OBTENER USER ID REAL
      final String userIdStr = result.userId ?? AuthService.getCurrentUserId();

      // Buscar si el usuario ya tiene perfil
      final profile = await ProfileService.fetchProfileForUser(userIdStr);

      if (profile == null) {
        // No tiene perfil -> Enviar al creador de perfil
        final int userIdInt = int.tryParse(userIdStr) ?? 0;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileEditorView(userId: userIdInt),
          ),
        );
        return;
      }

      // Sí tiene perfil → Enviar al MainScreen
      final int? idPerfil = profile.idPerfil;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              MainScreen(initialIndex: 0, profileId: idPerfil),
        ),
        (Route<dynamic> route) => false,
      );
    } else {
      // Error de autenticación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Error de autenticación desconocido.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // INPUT FIELD REUTILIZABLE
  // ================================================================
  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color cardColor,
    bool obscureText = false,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: Theme.of(context).colorScheme.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // UI
  // ================================================================
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
              Icon(Icons.menu_book_rounded, size: 100, color: primaryColor),
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

              // Usuario
              _buildInputField(
                context,
                label: 'Usuario',
                icon: Icons.person,
                cardColor: cardColor,
                controller: _usernameController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Contraseña
              _buildInputField(
                context,
                label: 'Contraseña',
                icon: Icons.lock,
                cardColor: cardColor,
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 40),

              // Botón Login
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : ElevatedButton(
                      onPressed: _handleLogin,
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

              // Registro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrationView()),
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
