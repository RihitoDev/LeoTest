// lib/views/profile_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/views/evaluation_list_view.dart';
import 'package:leotest/views/settings_view.dart';
import 'package:leotest/views/progress_view.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/services/profile_service.dart';
import 'package:leotest/services/my_books_service.dart';
import 'package:leotest/views/stats_view.dart';
import '../models/user_book_progress.dart';

class ProfileView extends StatefulWidget {
  final int? profileId;
  const ProfileView({super.key, this.profileId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Future<Map<String, dynamic>> _futureProfileWithStats;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    if (mounted) {
      setState(() {
        _futureProfileWithStats = _fetchProfileWithStats();
      });
    }
  }

  /// ⚡ Trae perfil + libros leídos reales
  Future<Map<String, dynamic>> _fetchProfileWithStats() async {
    final profile = await ProfileService.fetchProfileData(widget.profileId);
    final books = await MyBooksService.getUserBooks(profile.idPerfil!);
    final librosLeidos = books.where((b) => b.estado == 'Completado').length;

    return {'profile': profile, 'librosLeidos': librosLeidos};
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildAvatarSection(
    BuildContext context,
    Color primaryColor,
    dynamic profile,
    int librosLeidos,
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
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Libros Leídos', librosLeidos.toString()),
            _buildStatItem('Edad', profile.edad?.toString() ?? '-'),
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
    dynamic profile,
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
                } else if (title == 'Editar Datos de Cuenta') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsView(profileId: widget.profileId),
                    ),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureProfileWithStats,
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

          final profile = snapshot.data!['profile'];
          final librosLeidos = snapshot.data!['librosLeidos'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatarSection(
                  context,
                  primaryColor,
                  profile,
                  librosLeidos,
                ),
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
                  onTapAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EvaluationListView(idPerfil: profile.idPerfil!),
                      ),
                    );
                  },
                ),
                _buildProfileOption(
                  context,
                  'Estadísticas',
                  Icons.bar_chart,
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
                  'Editar Datos de Cuenta',
                  Icons.settings,
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
