// lib/views/profile_edit_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/services/profile_service.dart';

class ProfileEditView extends StatefulWidget {
  final int? profileId;
  const ProfileEditView({super.key, this.profileId});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  late Future<UserProfileData> _futureProfile;
  final TextEditingController _nombrePerfilController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  List<NivelEducativo> _niveles = [];
  int? _selectedNivelId;
  String? _selectedImage;
  bool _loading = false;

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
    _futureProfile = ProfileService.fetchProfileData(widget.profileId);

    _futureProfile.then((profile) async {
      _nombrePerfilController.text = profile.nombrePerfil;
      _edadController.text = profile.edad.toString();
      _selectedImage = profile.imagenPerfil;

      _niveles = await ProfileService.fetchNivelesEducativos();
      _selectedNivelId = profile.idNivelEducativo;

      setState(() {});
    });
  }

  void _loadNiveles() async {
    final niveles = await ProfileService.fetchNivelesEducativos();
    setState(() {
      _niveles = niveles;
    });
  }

  Future<void> _save() async {
    final nombre = _nombrePerfilController.text.trim();
    final edad = int.tryParse(_edadController.text.trim()) ?? 0;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa nombre del perfil")),
      );
      return;
    }

    setState(() => _loading = true);

    final ok = await ProfileService.updateProfile(
      profileId: widget.profileId,
      nombrePerfil: nombre,
      edad: edad,
      idNivelEducativo: _selectedNivelId,
      imagenPerfilUrl: _selectedImage,
    );

    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al guardar perfil")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),

      body: FutureBuilder<UserProfileData>(
        future: _futureProfile,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Selecciona un avatar",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _avatarImages.map((img) {
                    final selected = img == _selectedImage;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImage = img),
                      child: Container(
                        padding: selected
                            ? const EdgeInsets.all(4)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          border: selected
                              ? Border.all(color: primary, width: 3)
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
                const SizedBox(height: 16),
                TextField(
                  controller: _nombrePerfilController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Nombre del Perfil",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _edadController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Edad"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedNivelId,
                  dropdownColor: Colors.black87,
                  items: _niveles
                      .map(
                        (n) => DropdownMenuItem(
                          value: n.id,
                          child: Text(
                            n.nombre,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedNivelId = v),
                  decoration: const InputDecoration(
                    labelText: "Nivel Educativo",
                  ),
                ),
                const SizedBox(height: 20),
                _loading
                    ? CircularProgressIndicator(color: primary)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text("Guardar Cambios"),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
