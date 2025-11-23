// lib/views/user_edit_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/services/auth_service.dart';

class UserEditView extends StatefulWidget {
  final int? profileId;
  const UserEditView({super.key, this.profileId});

  @override
  State<UserEditView> createState() => _UserEditViewState();
}

class _UserEditViewState extends State<UserEditView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _loadingUsername = false;
  bool _loadingPassword = false;

  @override
  void initState() {
    super.initState();

    AuthService.fetchUsernameById().then((username) {
      if (username != null) {
        setState(() {
          _usernameController.text = username;
        });
      }
    });
  }

  Future<void> _updateUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un nombre de usuario")),
      );
      return;
    }

    setState(() => _loadingUsername = true);

    final ok = await AuthService.updateUsername(username);

    setState(() => _loadingUsername = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre de usuario actualizado")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo actualizar el nombre de usuario"),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirm = _confirmPassController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La nueva contraseña debe tener al menos 6 caracteres"),
        ),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La confirmación no coincide")),
      );
      return;
    }

    setState(() => _loadingPassword = true);

    final success = await AuthService.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );

    setState(() => _loadingPassword = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Contraseña actualizada")));
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña actual es incorrecta")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Usuario")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Nombre de Usuario"),
            ),
            const SizedBox(height: 12),
            _loadingUsername
                ? CircularProgressIndicator(color: primary)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateUsername,
                      child: const Text("Actualizar Nombre de Usuario"),
                    ),
                  ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Cambiar Contraseña",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Contraseña Actual"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Nueva Contraseña"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Confirmar Contraseña",
              ),
            ),
            const SizedBox(height: 12),
            _loadingPassword
                ? CircularProgressIndicator(color: primary)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      child: const Text("Actualizar Contraseña"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
