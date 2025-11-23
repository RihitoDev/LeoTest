// lib/views/registration_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/services/profile_service.dart';
import 'package:leotest/main.dart';
import 'package:leotest/views/login_view.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombrePerfilController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  bool _isLoading = false;
  List<NivelEducativo> _niveles = [];
  int? _selectedNivelId;

  String? _selectedImage;

  final List<String> _avatarImages = [
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/avatar1.jpg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/avatar2.jpeg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/avatar3.jpeg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/avatar4.jpg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/avatar5.jpg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/avatar6.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _loadNiveles();
  }

  void _loadNiveles() async {
    final niveles = await ProfileService.fetchNivelesEducativos();
    setState(() {
      _niveles = niveles;
      if (niveles.isNotEmpty) _selectedNivelId = niveles.first.id;
    });
  }

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nombrePerfilController.text.isEmpty ||
        _edadController.text.isEmpty ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1️⃣ Crear usuario
    final result = await AuthService.register(
      fullName: "", // Ya no se usa
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!result.success) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? "Error al registrar usuario."),
        ),
      );
      return;
    }

    final String userIdStr = result.userId!;
    final int userId = int.parse(userIdStr);

    // 2️⃣ Crear perfil
    final perfilId = await ProfileService.createProfile(
      idUsuario: userId,
      nombrePerfil: _nombrePerfilController.text.trim(),
      edad: int.parse(_edadController.text.trim()),
      idNivelEducativo: _selectedNivelId,
      imagenPerfilUrl: _selectedImage,
    );

    setState(() => _isLoading = false);

    if (perfilId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso. Ahora inicia sesión.")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al crear perfil.")));
    }
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Cuenta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(Icons.person_add_alt_1, size: 80, color: primaryColor),
            const SizedBox(height: 20),

            _buildInputField(
              label: "Nombre de Usuario",
              icon: Icons.person,
              controller: _usernameController,
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: "Contraseña",
              icon: Icons.lock,
              controller: _passwordController,
              obscure: true,
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: "Nombre del Perfil",
              icon: Icons.badge,
              controller: _nombrePerfilController,
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: "Edad",
              icon: Icons.cake,
              controller: _edadController,
            ),
            const SizedBox(height: 20),

            // Avatar Grid
            const Text(
              "Selecciona un Avatar",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _avatarImages.map((img) {
                final selected = (img == _selectedImage);
                return GestureDetector(
                  onTap: () => setState(() => _selectedImage = img),
                  child: Container(
                    padding: selected ? EdgeInsets.all(4) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      border: selected
                          ? Border.all(color: primaryColor, width: 3)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(img),
                      radius: 30,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Selector Nivel Educativo
            DropdownButtonFormField<int>(
              value: _selectedNivelId,
              dropdownColor: Colors.black87,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _niveles.map((n) {
                return DropdownMenuItem(
                  value: n.id,
                  child: Text(
                    n.nombre,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedNivelId = v),
            ),
            const SizedBox(height: 40),

            _isLoading
                ? CircularProgressIndicator(color: primaryColor)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.4),
                      ),
                      child: const Text(
                        "Crear Cuenta",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
