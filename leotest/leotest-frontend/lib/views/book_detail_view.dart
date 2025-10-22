import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/models/user_book_progress.dart';
import 'package:leotest/services/my_books_service.dart';
import 'package:leotest/services/auth_service.dart';

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

  // Carga el progreso existente del libro para el usuario actual.
  Future<void> _fetchBookProgress() async {
    // 🚨 Manejo de errores de autenticación aquí y en el servicio
    try {
      final progress = await MyBooksService.getBookProgress(widget.book.titulo);
      setState(() {
        _bookProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('sin ID de usuario')) {
        print("Usuario no autenticado para cargar progreso. (Debe loguearse)");
      } else {
        print("Error al cargar el progreso del libro: $e");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Lógica para iniciar o continuar la lectura, interactuando con la BD.
  void _startReading() async { // 👈 Ahora es async
    try {
      // Intentar obtener la ID del usuario (esto fallará si no está logueado)
      final currentUserId = AuthService.getCurrentUserId(); 

      // 1. Si el libro NO está en la biblioteca (se añade a la BD)
      if (_bookProgress == null) {
        
        // Llama al servicio para guardar el libro en la tabla 'progreso' (HTTP POST)
        await MyBooksService.addBookToLibrary(widget.book);
        
        // Recarga los datos para obtener la instancia completa (con idProgreso, idLibro, etc.)
        await _fetchBookProgress(); 

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${widget.book.titulo}" añadido a tu biblioteca y guardado. (ID Usuario: $currentUserId)')),
        );
      } 
      
      // 2. Si ya está en progreso (o acaba de ser añadido), simular la apertura del lector
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simulando la apertura del lector. Pág: ${_bookProgress?.currentPage ?? 0}')),
      );
      
      // 🚨 Simulación de actualización de progreso (Ejemplo)
      if (_bookProgress != null && _bookProgress!.currentPage < widget.book.totalPaginas) {
        final newPage = _bookProgress!.currentPage + 1; // Avanza una página
        await MyBooksService.updateBookProgress(_bookProgress!, newPage); 
        await _fetchBookProgress(); // Recargar el progreso después de la actualización
      }


    } catch (e) {
      // 🚨 Manejo de la excepción de autenticación
      if (e.toString().contains('sin ID de usuario')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Debes iniciar sesión para añadir un libro a tu biblioteca.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Manejar otros errores inesperados (ej: fallo de red)
        print("Error inesperado al intentar iniciar lectura: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Construye la imagen de portada usando NetworkImage o AssetImage
  Widget _buildCoverImage(String portada) {
    final isNetworkImage = portada.startsWith('http');
    final ImageProvider imageProvider = isNetworkImage
        ? NetworkImage(portada)
        : AssetImage(portada) as ImageProvider;

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
        image: portada.isNotEmpty
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: portada.isEmpty
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
    
    final progress = _bookProgress;
    final progressPercentage = progress != null ? (progress.progressPercentage * 100).toInt() : 0;
    
    // Determinar el texto del botón basado en el estado (si existe)
    String buttonText;
    if (progress == null) {
      buttonText = 'INICIAR LECTURA';
    } else if (progress.estado == 'Completado') {
      buttonText = 'LEÍDO (Volver a empezar)';
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
            _buildCoverImage(widget.book.portada),
            const SizedBox(height: 25),

            // --- 2. Título y Autor ---
            Text(
              widget.book.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Autor: ${widget.book.autor}',
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
                // 🚨 CORRECCIÓN: Manejar nulidad de widget.book.categoria
                _buildInfoChip(Icons.category, widget.book.categoria ?? 'Sin Categoría'),
                _buildInfoChip(Icons.bookmark_border, 'Total: ${widget.book.totalPaginas} págs.'),
              ],
            ),
            const SizedBox(height: 25),

            // --- 4. Barra de Progreso (Visible solo si el libro ya fue iniciado) ---
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
                  color: Colors.black,
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
              widget.book.descripcion,
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