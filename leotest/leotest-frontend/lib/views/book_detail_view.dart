// book_detail_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/models/user_book_progress.dart';
import 'package:leotest/services/my_books_service.dart';
import 'package:leotest/services/favorito_service.dart';
import 'package:leotest/views/book_reader_view.dart';

class BookDetailView extends StatefulWidget {
  final Book book;
  final int idPerfil; // 🔹 NUEVO PARÁMETRO

  const BookDetailView({
    super.key,
    required this.book,
    required this.idPerfil, // 🔹 requerido
  });

  @override
  State<BookDetailView> createState() => _BookDetailViewState();
}

class _BookDetailViewState extends State<BookDetailView> {
  UserBookProgress? _bookProgress;
  bool _isLoading = true;
  bool _isFavorito = false;

  @override
  void initState() {
    super.initState();

    // Cargar después del primer frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _fetchBookProgress();
      _cargarFavorito();
    });
  }

  Future<void> _cargarFavorito() async {
    try {
      final favoritos = await FavoritoService.obtenerFavoritos(
        idPerfil: widget.idPerfil, // 🔹 usar widget.idPerfil
      );
      if (mounted) {
        setState(() => _isFavorito = favoritos.contains(widget.book.idLibro));
      }
    } catch (e) {
      print('Error al verificar favorito: $e');
    }
  }

  Future<void> _toggleFavorito() async {
    try {
      if (_isFavorito) {
        // Quitar favorito
        await FavoritoService.quitarFavorito(
          idPerfil: widget.idPerfil, // 🔹 usar widget.idPerfil
          idLibro: widget.book.idLibro,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Libro eliminado de favoritos.')),
        );
      } else {
        // Agregar favorito
        await FavoritoService.agregarFavorito(
          idPerfil: widget.idPerfil, // 🔹 usar widget.idPerfil
          idLibro: widget.book.idLibro,
        );

        // Si no existe en MyBooks, agregar automáticamente
        if (_bookProgress == null) {
          try {
            await MyBooksService.addBookToLibrary(widget.book);
            await _fetchBookProgress();
          } catch (e) {
            print('Error al agregar libro a MyBooks desde BookDetail: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Libro añadido a favoritos.')),
        );
      }

      if (mounted) setState(() => _isFavorito = !_isFavorito);
    } catch (e) {
      print('Error al actualizar favorito: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar favorito.')),
        );
      }
    }
  }

  Future<void> _fetchBookProgress() async {
    try {
      final progress = await MyBooksService.getBookProgress(
        widget.book.titulo ?? "Título desconocido",
      );
      if (mounted) {
        setState(() {
          _bookProgress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error al cargar progreso: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startReading() async {
    if (_bookProgress == null) {
      await MyBooksService.addBookToLibrary(widget.book);
      await _fetchBookProgress();
    }

    final initialPage = _bookProgress?.currentPage ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderView(
          book: widget.book,
          initialPage: initialPage,
          idPerfil: widget.idPerfil,
        ),
      ),
    ).then((_) => _fetchBookProgress());
  }

  Widget _buildCover(String? portada) {
    final safePortada = portada ?? "";
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
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      child: safePortada.isEmpty
          ? const Center(
              child: Icon(Icons.menu_book, size: 50, color: Colors.white70),
            )
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
    final progressPercentage = progress != null
        ? (progress.progressPercentage * 100).toInt()
        : 0;

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
            _buildCover(widget.book.portada),
            const SizedBox(height: 25),
            Text(
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
              'Autor: ${widget.book.autor ?? 'Desconocido'}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoChip(
                  Icons.category,
                  widget.book.categoria ?? 'Sin Categoría',
                ),
                _buildInfoChip(
                  Icons.bookmark_border,
                  'Total: ${widget.book.totalPaginas ?? '?'} págs.',
                ),
              ],
            ),
            const SizedBox(height: 25),
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
              const SizedBox(height: 20),
              // ❤️ Ícono de favorito debajo del progreso
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _toggleFavorito,
                  icon: Icon(
                    _isFavorito ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorito ? Colors.redAccent : Colors.white,
                    size: 28,
                  ),
                  tooltip: _isFavorito
                      ? 'Quitar de favoritos'
                      : 'Agregar a favoritos',
                ),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _startReading,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 18,
      ),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}
