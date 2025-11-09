// lib/views/create_profile_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/services/profile_service.dart';

class CreateProfileView extends StatefulWidget {
  const CreateProfileView({super.key});

  @override
  State<CreateProfileView> createState() => _CreateProfileViewState();
}

class _CreateProfileViewState extends State<CreateProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();

  int? _selectedNivel;
  late Future<List<Map<String, dynamic>>> _nivelesFuture;

  String? selectedImageUrl =
      "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/default.jpg";

  final List<String> imagenesPerfil = [
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/default.jpg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/HD-wallpaper-perfil-cool-tecnologia-thumbnail.jpg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/images.jpeg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/lector2.jpg",
    "https://htnzhsbddlsxewwpbjpx.supabase.co/storage/v1/object/public/leoTest/imagenes_perfil/lector3.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _nivelesFuture = ProfileService.fetchNivelesEducativos();
  }

  void _guardarPerfil() async {
    if (_formKey.currentState!.validate() && _selectedNivel != null) {
      final success = await ProfileService.createProfile(
        nombrePerfil: _nombreController.text,
        edad: int.parse(_edadController.text),
        idNivelEducativo: _selectedNivel!,
        imagenPerfil: selectedImageUrl!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil creado exitosamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al crear perfil')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Perfil')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _nivelesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final niveles = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del perfil',
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _edadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Edad'),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text('Nivel Educativo'),
                    ...niveles.map((nivel) {
                      return CheckboxListTile(
                        value: _selectedNivel == nivel['id'],
                        title: Text(nivel['nombre']),
                        onChanged: (_) {
                          setState(() {
                            _selectedNivel = nivel['id'];
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text(
                      "Selecciona una imagen de perfil",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: imagenesPerfil.map((url) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImageUrl = url;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedImageUrl == url
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _guardarPerfil,
                      child: const Text('Guardar Perfil'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
