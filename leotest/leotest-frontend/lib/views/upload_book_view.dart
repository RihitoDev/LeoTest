// lib/views/upload_book_view.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data'; 
import 'package:leotest/services/book_service.dart'; 

class UploadBookView extends StatefulWidget {
  const UploadBookView({super.key});

  @override
  State<UploadBookView> createState() => _UploadBookViewState();
}

class _UploadBookViewState extends State<UploadBookView> {
  final _formKey = GlobalKey<FormState>();
  
  // Archivo del LIBRO (PDF/ePub)
  Uint8List? _bookFileBytes; 
  String _bookFileName = 'Ningún archivo de libro seleccionado';

  // Archivo de la PORTADA (Imagen)
  Uint8List? _coverFileBytes; 
  String _coverFileName = 'Ningún archivo de portada seleccionado';

  // Datos del libro
  String _titulo = '';
  String _autor = '';
  String _descripcion = '';
  int? _selectedCategoriaId;
  int? _selectedNivelId;
  
  // 🚨 NUEVAS VARIABLES PARA PÁGINAS Y CAPÍTULOS
  int _totalPaginas = 0;
  int _totalCapitulos = 0;
  
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos iniciales: ${e.toString()}')),
        );
      });
    }
  }

  Future<void> _pickBookFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
      withData: true, 
    );

    if (result != null) {
      PlatformFile file = result.files.single;
      setState(() {
        _bookFileBytes = file.bytes; 
        _bookFileName = file.name;    
        
        if (_titulo.isEmpty) {
          _titulo = _bookFileName.replaceAll(RegExp(r'\.(pdf|epub)$', caseSensitive: false), '');
        }
      });
    }
  }

  Future<void> _pickCoverFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, 
      withData: true, 
    );

    if (result != null) {
      PlatformFile file = result.files.single;
      setState(() {
        _coverFileBytes = file.bytes; 
        _coverFileName = file.name;    
      });
    }
  }

  Future<void> _submitForm() async {
    // Validar campos y selección de archivos
    if (!_formKey.currentState!.validate() || _bookFileBytes == null || _coverFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos y selecciona el libro y la portada.')),
      );
      return;
    }
    
    _formKey.currentState!.save();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subiendo libro y portada...')),
    );

    // 🚨 ENVIANDO LOS NUEVOS CAMPOS totalPaginas y totalCapitulos
    final success = await BookService.subirLibro(
      titulo: _titulo,
      autor: _autor,
      descripcion: _descripcion,
      idCategoria: _selectedCategoriaId!,
      idNivelEducativo: _selectedNivelId!,
      
      bookFileBytes: _bookFileBytes!,     
      bookFileName: _bookFileName,        
      coverFileBytes: _coverFileBytes!,   
      coverFileName: _coverFileName,      
      
      totalPaginas: _totalPaginas,       // 🚨 NUEVO VALOR
      totalCapitulos: _totalCapitulos,   // 🚨 NUEVO VALOR
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Libro subido correctamente!')),
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al subir el libro. Revisa la consola del servidor.')),
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
                    // 1. SELECTOR DE ARCHIVO DEL LIBRO
                    ElevatedButton.icon(
                      onPressed: _pickBookFile,
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Seleccionar Archivo del Libro (PDF/ePub)'),
                    ),
                    const SizedBox(height: 8),
                    Text('Libro: $_bookFileName', style: TextStyle(fontSize: 14, color: _bookFileBytes == null ? Colors.red : Colors.green)),
                    const SizedBox(height: 16),

                    // 2. SELECTOR DE ARCHIVO DE LA PORTADA
                    ElevatedButton.icon(
                      onPressed: _pickCoverFile,
                      icon: const Icon(Icons.image),
                      label: const Text('Seleccionar Archivo de Portada (Imagen)'),
                    ),
                    const SizedBox(height: 8),
                    Text('Portada: $_coverFileName', style: TextStyle(fontSize: 14, color: _coverFileBytes == null ? Colors.red : Colors.green)),
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

                    // 🚨 NUEVO: Total Páginas
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total de Páginas'),
                      initialValue: '0',
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) < 0) {
                          return 'Ingresa un número válido de páginas.';
                        }
                        return null;
                      },
                      onSaved: (value) => _totalPaginas = int.tryParse(value!) ?? 0,
                    ),
                    const SizedBox(height: 20),

                    // 🚨 NUEVO: Total Capítulos
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total de Capítulos'),
                      initialValue: '0',
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) < 0) {
                          return 'Ingresa un número válido de capítulos.';
                        }
                        return null;
                      },
                      onSaved: (value) => _totalCapitulos = int.tryParse(value!) ?? 0,
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
                        child: const Text('SUBIR LIBRO Y PORTADA', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}