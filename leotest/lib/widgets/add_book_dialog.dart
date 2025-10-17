import 'package:flutter/material.dart';

class AddBookDialog extends StatelessWidget {
  const AddBookDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Nuevo Libro', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Selecciona el archivo de tu libro (PDF, EPUB) para iniciar la carga.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Botón para SELECCIONAR ARCHIVO
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar lógica de File Picker (paquete file_picker)
                // Aquí se abriría el explorador de archivos para que el usuario elija el libro.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abriendo selector de archivos...'))
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Seleccionar Archivo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Ancho completo
              ),
            ),
            const SizedBox(height: 15),

            // Opcional: Campo de Título Manual
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Título del Libro',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        // Botón Cancelar
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        // Botón Cargar
        FilledButton(
          child: const Text('Cargar y Procesar'),
          onPressed: () {
            // TODO: Implementar lógica de subida a la API Principal
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}