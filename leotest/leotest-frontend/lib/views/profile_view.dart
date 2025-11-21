// lib/views/profile_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/views/settings_view.dart';
import 'package:leotest/views/progress_view.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/services/profile_service.dart';
import 'package:leotest/views/stats_view.dart';

class ProfileView extends StatefulWidget {
  final int? profileId;
  const ProfileView({super.key, this.profileId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Future<UserProfileData> _futureProfileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    if (mounted) {
      setState(() {
        _futureProfileData = ProfileService.fetchProfileData(widget.profileId!);
      });
    }
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildAvatarSection(
    BuildContext context,
    Color primaryColor,
    UserProfileData profile,
  ) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: profile.imagenPerfil == null
              ? const Icon(Icons.person, size: 60, color: Colors.black)
              : ClipOval(
                  child: Image.network(
                    profile.imagenPerfil!,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Text(
          profile.nombrePerfil,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          profile.email,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Libros Leídos', profile.librosLeidos.toString()),
            _buildStatItem('Racha', '${profile.rachaDias} días'),
            _buildStatItem('Nivel', profile.nivelEducativo),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    Color cardColor,
    Color primaryColor, {
    bool isLogout = false,
    VoidCallback? onTapAction,
    UserProfileData? profile,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isLogout ? Colors.redAccent : primaryColor,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isLogout ? Colors.redAccent : Colors.white,
            ),
          ),
          trailing: isLogout
              ? null
              : const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFAAAAAA),
                ),
          onTap:
              onTapAction ??
              () {
                if (isLogout) {
                  AuthService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                    (route) => false,
                  );
                } else if (title == 'Editar Datos y Preferencias') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsView()),
                  ).then((_) => _loadProfileData());
                } else if (title == 'Progreso') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProgressView(userId: widget.profileId!),
                    ),
                  );
                } else if (title == 'Estadísticas') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatsView()),
                  );
                }
              },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<UserProfileData>(
        future: _futureProfileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error al cargar perfil. Asegúrate de que el backend esté activo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadProfileData,
                      child: const Text('Recargar Perfil'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatarSection(context, primaryColor, profile),
                const SizedBox(height: 30),
                _buildProfileOption(
                  context,
                  'Progreso',
                  Icons.timeline,
                  cardColor,
                  primaryColor,
                  profile: profile,
                ),
                _buildProfileOption(
                  context,
                  'Evaluaciones',
                  Icons.checklist,
                  cardColor,
                  primaryColor,
                ),
                _buildProfileOption(
                  context,
                  'Estadísticas',
                  Icons.bar_chart,
                  cardColor,
                  primaryColor,
                ),
                _buildProfileOption(
                  context,
                  'Social',
                  Icons.people_outline,
                  cardColor,
                  primaryColor,
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Configuración',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildProfileOption(
                  context,
                  'Editar Datos y Preferencias',
                  Icons.settings,
                  cardColor,
                  primaryColor,
                ),
                _buildProfileOption(
                  context,
                  'Privacidad',
                  Icons.lock_outline,
                  cardColor,
                  primaryColor,
                ),
                _buildProfileOption(
                  context,
                  'Cerrar Sesión',
                  Icons.logout,
                  cardColor,
                  primaryColor,
                  isLogout: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
