// lib/views/settings_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/views/profile_edit_view.dart';
import 'package:leotest/views/user_edit_view.dart';
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/views/login_view.dart';

class SettingsView extends StatelessWidget {
  final int? profileId;
  const SettingsView({super.key, this.profileId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    void _confirmDelete(BuildContext ctx, int userId) async {
      final confirm = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text("Eliminar cuenta"),
          content: const Text(
            "¿Estás seguro? Esta acción no se puede deshacer.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Eliminar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final ok = await AuthService.deleteUser(userId);
        if (ok) {
          Navigator.pushAndRemoveUntil(
            ctx,
            MaterialPageRoute(builder: (_) => const LoginView()),
            (_) => false,
          );
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text("No se pudo eliminar la cuenta")),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Datos y Preferencias")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: cardColor,
              child: ListTile(
                leading: Icon(Icons.person, color: primary),
                title: const Text("Editar Perfil"),
                subtitle: const Text("Nombre, edad, avatar, nivel educativo"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileEditView(profileId: profileId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: cardColor,
              child: ListTile(
                leading: Icon(Icons.account_circle, color: primary),
                title: const Text("Editar Usuario"),
                subtitle: const Text("Nombre de usuario y contraseña"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserEditView(profileId: profileId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: cardColor,
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text(
                  "Eliminar Cuenta",
                  style: TextStyle(color: Colors.redAccent),
                ),
                subtitle: const Text("Eliminar cuenta y datos"),
                onTap: () async {
                  // necesitas el userId para eliminar -> pedirlo desde AuthService
                  try {
                    final userId = int.parse(AuthService.getCurrentUserId());
                    _confirmDelete(context, userId);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No se pudo obtener el usuario actual."),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
