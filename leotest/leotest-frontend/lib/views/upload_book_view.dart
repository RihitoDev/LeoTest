// lib/views/upload_book_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/services/book_service.dart';
import 'package:file_picker/file_picker.dart'; // Asegúrate de agregar el paquete 'file_picker' a pubspec.yaml

class UploadBookView extends StatefulWidget {
  const UploadBookView({super.key});

  @override
  State<UploadBookView> createState() => _UploadBookViewState();
}

class _UploadBookViewState extends State<UploadBookView> {
  final _formKey = GlobalKey<FormState>();
  String? _filePath;
  String _fileName = 'Ningún archivo seleccionado';

  // Datos del libro
  String _titulo = '';
  String _autor = '';
  String _descripcion = '';
  int? _selectedCategoriaId;
  int? _selectedNivelId;
  
  // Listas de la API
  List<Category> _categorias = [];
  List<Level> _niveles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final categories = await BookService.obtenerCategorias();
      final levels = await BookService.obtenerNiveles();
      setState(() {
        _categorias = categories;
        _niveles = levels;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos del formulario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'], // Permite PDF y ePub
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        // Opcionalmente, prellenar título si está vacío
        if (_titulo.isEmpty) {
          _titulo = _fileName.replaceAll(RegExp(r'\.(pdf|epub)$', caseSensitive: false), '');
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _filePath != null) {
      _formKey.currentState!.save();
      
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subiendo libro...')),
      );

      final success = await BookService.subirLibro(
        titulo: _titulo,
        autor: _autor,
        descripcion: _descripcion,
        idCategoria: _selectedCategoriaId!,
        idNivelEducativo: _selectedNivelId!,
        filePath: _filePath!,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Libro subido correctamente!')),
        );
        // Limpiar formulario y cerrar vista
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al subir el libro. Revisa la consola.')),
        );
      }
    } else if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un archivo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Nuevo Libro'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Selector de Archivo
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Seleccionar Archivo (PDF/ePub)'),
                    ),
                    const SizedBox(height: 8),
                    Text('Archivo: $_fileName', style: const TextStyle(fontSize: 14)),
                    const Divider(height: 32),

                    // Título
                    TextFormField(
                      initialValue: _titulo,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (value) => value!.isEmpty ? 'Ingresa el título' : null,
                      onSaved: (value) => _titulo = value!,
                      onChanged: (value) => _titulo = value,
                    ),
                    // Autor
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Autor'),
                      validator: (value) => value!.isEmpty ? 'Ingresa el autor' : null,
                      onSaved: (value) => _autor = value!,
                    ),
                    // Descripción
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Ingresa la descripción' : null,
                      onSaved: (value) => _descripcion = value!,
                    ),
                    const SizedBox(height: 20),

                    // Categoría
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      value: _selectedCategoriaId,
                      hint: const Text('Selecciona Categoría'),
                      items: _categorias.map((cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          )).toList(),
                      onChanged: (value) => setState(() => _selectedCategoriaId = value),
                      validator: (value) => value == null ? 'Selecciona una categoría' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    // Nivel Educativo
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Nivel Educativo'),
                      value: _selectedNivelId,
                      hint: const Text('Selecciona Nivel'),
                      items: _niveles.map((lvl) => DropdownMenuItem(
                            value: lvl.id,
                            child: Text(lvl.name),
                          )).toList(),
                      onChanged: (value) => setState(() => _selectedNivelId = value),
                      validator: (value) => value == null ? 'Selecciona un nivel' : null,
                    ),
                    const SizedBox(height: 40),

                    // Botón de Subida
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('SUBIR LIBRO', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}