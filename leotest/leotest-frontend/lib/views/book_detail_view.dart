import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/models/user_book_progress.dart';
import 'package:leotest/services/my_books_service.dart';
import 'package:leotest/services/auth_service.dart';
import 'package:leotest/views/book_reader_view.dart'; 

class BookDetailView extends StatefulWidget {
  final Book book;

  const BookDetailView({super.key, required this.book});

  @override
  State<BookDetailView> createState() => _BookDetailViewState();
}

class _BookDetailViewState extends State<BookDetailView> {
  UserBookProgress? _bookProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookProgress();
  }

  /// Carga el progreso existente del libro para el usuario actual desde el backend.
  Future<void> _fetchBookProgress() async {
    // 🚨 Seguridad: Usamos '?? "Título desconocido"' para garantizar que la API siempre reciba una String
    final bookTitle = widget.book.titulo ?? "Título desconocido"; 
    
    try {
      // Intentar obtener el progreso usando el título como clave de búsqueda
      final progress = await MyBooksService.getBookProgress(bookTitle);
      setState(() {
        _bookProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      // Manejar el caso de un error en el servicio, autenticación o conexión
      print("Error al cargar el progreso del libro: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Lógica para iniciar o continuar la lectura, interactuando con la BD.
  void _startReading() async {
    // 🚨 Doble chequeo de seguridad antes de navegar
    if (widget.book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error: El libro no está disponible.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    try {
      // 1. Verificar autenticación.
      final currentUserId = AuthService.getCurrentUserId(); 
      
      // 2. Si el libro NO está en la biblioteca, lo agregamos (HTTP POST)
      if (_bookProgress == null) {
        
        await MyBooksService.addBookToLibrary(widget.book);
        
        // Recarga los datos para obtener la instancia completa con los IDs de la BD
        await _fetchBookProgress(); 

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${widget.book.titulo ?? "Libro"}" añadido a tu biblioteca. (ID: $currentUserId)')),
        );
      } 
      
      // 3. Determinar la página inicial (0 si es nuevo o no se pudo cargar)
      final initialPage = _bookProgress?.currentPage ?? 0;

      // 🚨 NAVEGACIÓN A LA VISTA DE LECTOR
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReaderView(
            // El objeto widget.book es el que se pasa. La vista lectora ya maneja los nulos.
            book: widget.book,
            initialPage: initialPage,
          ),
        ),
      ).then((_) {
        // Al regresar del lector, volvemos a cargar el progreso
        _fetchBookProgress();
      });


    } catch (e) {
      // 4. Manejo completo de errores (autenticación y otros)
      
      // Error de autenticación
      if (e.toString().contains('sin ID de usuario')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Debes iniciar sesión para iniciar la lectura.'),
            backgroundColor: Colors.red,
          ),
        );
      } 
      // Otros errores (red, servidor, fallo al guardar/obtener)
      else {
        print("Error inesperado al intentar iniciar lectura: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la solicitud: ${e.toString().split(':')[0]}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Construye la imagen de portada usando NetworkImage o AssetImage según corresponda.
  Widget _buildCoverImage(String? portada) { // Acepta portada como String?
    // Usamos '?? ""' para asegurar que portada siempre sea una String no nula (vacía si es null)
    final safePortada = portada ?? ""; 
    
    // Asumimos que si la cadena empieza por 'http', es una URL de red.
    final isNetworkImage = safePortada.startsWith('http');
    final ImageProvider imageProvider = isNetworkImage
        ? NetworkImage(safePortada)
        : AssetImage(safePortada) as ImageProvider;

    return Container(
      width: 150,
      height: 225,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        image: safePortada.isNotEmpty
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: safePortada.isEmpty
          ? const Center(
              child: Icon(Icons.menu_book, size: 50, color: Colors.white70))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalles del Libro')),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }
    
    // Calcula el progreso
    final progress = _bookProgress;
    final progressPercentage = progress != null ? (progress.progressPercentage * 100).toInt() : 0;
    
    // Determinar texto del botón
    String buttonText;
    if (progress == null) {
      buttonText = 'INICIAR LECTURA';
    } else if (progress.estado == 'Completado') {
      buttonText = 'RELEER (Completado)';
    } else {
      buttonText = 'CONTINUAR LECTURA (Pág. ${progress.currentPage})';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Libro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. Portada del Libro ---
            _buildCoverImage(widget.book.portada), // Puede ser nulo
            const SizedBox(height: 25),

            // --- 2. Título y Autor ---
            Text(
              // 🚨 CORRECCIÓN: Manejo de nulos para 'titulo'
              widget.book.titulo ?? 'Título Desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              // 🚨 CORRECCIÓN: Manejo de nulos para 'autor'
              'Autor: ${widget.book.autor ?? 'Desconocido'}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. Información Detallada (Categoría y Páginas Totales) ---
            Wrap(
              spacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoChip(Icons.category, widget.book.categoria ?? 'Sin Categoría'), 
                
                // 🚨 CORRECCIÓN: Manejo de nulos para 'totalPaginas'
                _buildInfoChip(Icons.bookmark_border, 'Total: ${widget.book.totalPaginas ?? '?'} págs.'),
              ],
            ),
            const SizedBox(height: 25),

            // --- 4. Barra de Progreso ---
            if (progress != null) ...[
              const Divider(color: Colors.grey, height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tu Progreso: $progressPercentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    'Pág. ${progress.currentPage} de ${progress.totalPages}', 
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress.progressPercentage,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 30),
            ],

            // --- 5. Botón de Acción ---
            ElevatedButton(
              onPressed: _startReading,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Color contrastante
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- 6. Resumen / Descripción ---
            const Text(
              'Resumen:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // 🚨 CORRECCIÓN: Manejo de nulos para 'descripcion'
              widget.book.descripcion ?? 'Sin descripción disponible.',
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget auxiliar para mostrar información en 'chips'
  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}