// lib/views/profile_editor_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/services/profile_service.dart';
import 'package:leotest/main.dart'; // para MainScreen
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/views/login_view.dart';

class ProfileEditorView extends StatefulWidget {
  final int userId;
  const ProfileEditorView({super.key, required this.userId});

  @override
  State<ProfileEditorView> createState() => _ProfileEditorViewState();
}

class _ProfileEditorViewState extends State<ProfileEditorView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombrePerfilController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  List<NivelEducativo> _niveles = [];
  int? _selectedNivelId;
  bool _isLoading = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final nombre = _nombrePerfilController.text.trim();
    final edad = int.tryParse(_edadController.text.trim());
    final imagen = _selectedImage;

    final idPerfil = await ProfileService.createProfile(
      idUsuario: widget.userId,
      nombrePerfil: nombre,
      edad: edad,
      idNivelEducativo: _selectedNivelId,
      imagenPerfilUrl: imagen,
    );

    setState(() => _isLoading = false);

    if (idPerfil != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainScreen(initialIndex: 0, profileId: idPerfil),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al crear perfil. Intenta nuevamente."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombrePerfilController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Perfil"),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginView()),
              (route) => false,
            );
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Nombre de Perfil
              TextFormField(
                controller: _nombrePerfilController,
                decoration: InputDecoration(
                  labelText: "Nombre de Perfil",
                  filled: true,
                  fillColor: cardColor,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Ingresa un nombre" : null,
              ),

              const SizedBox(height: 12),

              // Edad
              TextFormField(
                controller: _edadController,
                decoration: InputDecoration(
                  labelText: "Edad (opcional)",
                  filled: true,
                  fillColor: cardColor,
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),

              // Nivel Educativo
              DropdownButtonFormField<int>(
                value: _selectedNivelId,
                items: _niveles
                    .map(
                      (n) =>
                          DropdownMenuItem(value: n.id, child: Text(n.nombre)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedNivelId = v),
                decoration: InputDecoration(
                  labelText: "Nivel Educativo",
                  filled: true,
                  fillColor: cardColor,
                ),
              ),

              const SizedBox(height: 12),

              // Selector de Imágenes
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Selecciona tu imagen de perfil:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _avatarImages.length,
                itemBuilder: (context, index) {
                  final img = _avatarImages[index];
                  final isSelected = _selectedImage == img;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedImage = img),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(img, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Botón Crear Perfil
              _isLoading
                  ? CircularProgressIndicator(color: primaryColor)
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 20,
                        ),
                        child: Text(
                          "Crear Perfil",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
