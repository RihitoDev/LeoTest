import 'package:flutter/material.dart';
import 'package:leotest/services/profile_service.dart';
import 'package:leotest/views/create_profile_view.dart';
import 'package:leotest/views/home_view.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/models/perfil.dart';

class SelectProfileView extends StatefulWidget {
  const SelectProfileView({super.key});

  @override
  State<SelectProfileView> createState() => _SelectProfileViewState();
}

class _SelectProfileViewState extends State<SelectProfileView> {
  late Future<List<Perfil>> _futureProfiles;

  @override
  void initState() {
    super.initState();
    _futureProfiles = ProfileService.fetchProfiles();
  }

  void _refreshProfiles() {
    setState(() {
      _futureProfiles = ProfileService.fetchProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text(
          'Seleccionar Perfil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginView()),
            );
          },
        ),
      ),

      body: SafeArea(
        child: FutureBuilder<List<Perfil>>(
          future: _futureProfiles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error al cargar perfiles',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final perfiles = snapshot.data ?? [];

            // Si no hay perfiles → ir directo a crear uno
            if (perfiles.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateProfileView()),
                );
              });
              return const SizedBox();
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "¿Quién va a leer hoy?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 perfiles por fila
                          crossAxisSpacing: 25,
                          mainAxisSpacing: 25,
                        ),
                    itemCount: perfiles.length + 1,
                    itemBuilder: (context, index) {
                      // Botón "Agregar perfil"
                      if (index == perfiles.length) {
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateProfileView(),
                              ),
                            );
                            _refreshProfiles();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }

                      final perfil = perfiles[index];

                      // Al tocar un perfil → navegar a HomeView
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomeView(perfil: perfil),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    perfil.imagen != null &&
                                        perfil.imagen!.isNotEmpty
                                    ? Image.network(
                                        perfil.imagen!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Container(
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.menu_book,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              perfil.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}
