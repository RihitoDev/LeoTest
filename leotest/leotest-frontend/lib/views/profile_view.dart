import 'package:flutter/material.dart';
import 'package:leotest/views/settings_view.dart';
import 'package:leotest/views/progress_view.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/models/perfil.dart';

class ProfileView extends StatefulWidget {
  final Perfil perfil;

  const ProfileView({super.key, required this.perfil});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // --- WIDGETS AUXILIARES ---

  Widget _buildAvatarSection(
    BuildContext context,
    Color primaryColor,
    Perfil perfil,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor,
          backgroundImage: perfil.imagen != null && perfil.imagen!.isNotEmpty
              ? NetworkImage(perfil.imagen!)
              : null,
          child: (perfil.imagen == null || perfil.imagen!.isEmpty)
              ? const Icon(Icons.person, size: 60, color: Colors.black)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          perfil.nombre,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Edad: ${perfil.edad} | Nivel: ${perfil.nivelEducativo}",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
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
                    (Route<dynamic> route) => false,
                  );
                } else if (title == 'Editar Datos y Preferencias') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsView(),
                    ),
                  );
                } else if (title == 'Progreso') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProgressView(),
                    ),
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
    final perfil = widget.perfil;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatarSection(context, primaryColor, perfil),
            const SizedBox(height: 30),

            _buildProfileOption(
              context,
              'Progreso',
              Icons.timeline,
              cardColor,
              primaryColor,
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
              'Cambiar de Perfil',
              Icons.switch_account,
              cardColor,
              primaryColor,
              onTapAction: () {
                Navigator.pushReplacementNamed(context, '/selectProfile');
              },
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
      ),
    );
  }
}
