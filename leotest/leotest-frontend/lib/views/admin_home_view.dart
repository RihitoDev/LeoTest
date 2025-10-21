import 'package:flutter/material.dart';
import 'package:leotest/views/upload_book_view.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/services/book_service.dart'; 

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (Route<dynamic> route) => false,
    );
  }

  // NUEVA FUNCIÓN PARA MOSTRAR EL DIÁLOGO
  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Añadir Nueva Categoría'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                final nombre = controller.text.trim();
                if (nombre.isNotEmpty) {
                  // Llama a la función que crea la categoría
                  _createCategory(context, nombre);
                  Navigator.of(dialogContext).pop();
                } else {
                  // Muestra un mensaje si el campo está vacío
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('El nombre no puede estar vacío.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // NUEVA FUNCIÓN PARA LLAMAR A LA API
  Future<void> _createCategory(BuildContext context, String name) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creando categoría...')),
    );
    
    // Necesitas una clase BookService que tenga el método crearCategoria
    final success = await BookService.crearCategoria(name); 

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categoría "$name" creada con éxito!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la categoría "$name". Ya podría existir.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido Administrador',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 40),
            // Botón para ir a la subida de libros
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Subir Nuevo Libro'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadBookView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Botón para gestionar categorías
            ElevatedButton.icon(
              icon: const Icon(Icons.category),
              label: const Text('Añadir Categorías'),
              onPressed: () {
                _showAddCategoryDialog(context); // <-- ¡LLAMADA A LA NUEVA FUNCIÓN!
              },
            ),
          ],
        ),
      ),
    );
  }
}