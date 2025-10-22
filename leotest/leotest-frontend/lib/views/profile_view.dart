import 'package:flutter/material.dart';
import 'package:leotest/views/settings_view.dart';
import 'package:leotest/views/progress_view.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/services/auth_service.dart'; // <-- Servicio de autenticación

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  // --- WIDGETS AUXILIARES ---

  // Muestra el avatar y las estadísticas rápidas (HU-11.2)
  Widget _buildAvatarSection(BuildContext context, Color primaryColor) {
    // 🚨 NOTA: En un sistema real, el nombre y email deben obtenerse del AuthService.
    // Usaremos valores estáticos por ahora.
    
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor, // Naranja
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 60, color: Colors.black), // Icono negro sobre naranja
        ),
        const SizedBox(height: 10),
        const Text(
          // Simulación: Nombre del usuario actual
          'Alejandro', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
        ),
        const SizedBox(height: 5),
        const Text(
          // Simulación: Email del usuario actual
          'alejandro.u@example.com', 
          style: TextStyle(fontSize: 14, color: Colors.grey)
        ),

        // Simulación de estadísticas rápidas
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Libros Leídos', '12'),
            _buildStatItem('Racha', '5 días'),
            _buildStatItem('Nivel', 'Avanzado'),
          ],
        ),
      ],
    );
  }

  // Muestra un ítem individual de estadística
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Construye las opciones de navegación o acción
  Widget _buildProfileOption(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color cardColor, 
    Color primaryColor,
    {bool isLogout = false}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor, // Color de tarjeta oscuro
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
              BoxShadow(
              color: Colors.black.withOpacity(0.4), 
              blurRadius: 5,
              offset: const Offset(0, 3)
            )
          ]
        ),
        child: ListTile(
          leading: Icon(icon, color: isLogout ? Colors.redAccent : primaryColor),
          title: Text(
            title, 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: isLogout ? Colors.redAccent : Colors.white
            )
          ),
          trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFAAAAAA)),
          onTap: () {
            if (isLogout) {
              // 🚨 ACCIÓN DE CERRAR SESIÓN
              AuthService.logout(); // Limpiar el estado de sesión (userId = null)

              // Navega al Login y elimina el historial de navegación
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (Route<dynamic> route) => false,
              );
            } else if (title == 'Editar Datos y Preferencias') {
              // NAVEGACIÓN a SettingsView
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            } else if (title == 'Progreso') {
              // NAVEGACIÓN a ProgressView
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProgressView()),
              );
            }
            // Agrega más lógica de navegación aquí si es necesario (Evaluaciones, Estadísticas, Social)
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Sección de Avatar y Estadísticas (HU-11.2)
            _buildAvatarSection(context, primaryColor),
            
            const SizedBox(height: 30),
            
            // 2. Opciones de Perfil/Navegación
            _buildProfileOption(context, 'Progreso', Icons.timeline, cardColor, primaryColor), 
            _buildProfileOption(context, 'Evaluaciones', Icons.checklist, cardColor, primaryColor), 
            _buildProfileOption(context, 'Estadísticas', Icons.bar_chart, cardColor, primaryColor), 
            _buildProfileOption(context, 'Social', Icons.people_outline, cardColor, primaryColor), 
            
            const SizedBox(height: 30),

            // 3. Sección de Configuración (HU-11.3)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Configuración',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white70, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            _buildProfileOption(context, 'Editar Datos y Preferencias', Icons.settings, cardColor, primaryColor),
            _buildProfileOption(context, 'Privacidad', Icons.lock_outline, cardColor, primaryColor),
            
            // 4. Opción de Cerrar Sesión (Llama a AuthService.logout())
            _buildProfileOption(context, 'Cerrar Sesión', Icons.logout, cardColor, primaryColor, isLogout: true),
          ],
        ),
      ),
    );
  }
}