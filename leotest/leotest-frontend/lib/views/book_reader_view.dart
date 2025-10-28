// lib/views/book_reader_view.dart

import 'package:flutter/material.dart';
import 'package:leotest/main.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/my_books_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart'; // ✅ 1. IMPORTAR INTL PARA FORMATEAR PORCENTAJE

class BookReaderView extends StatefulWidget {
  final Book book;
  final int initialPage;

  const BookReaderView({super.key, required this.book, this.initialPage = 0});

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  late int _currentPage;
  late final PdfViewerController _pdfController;
  final int _currentStreak = 17; // Simulado
  final int _notifications = 4; // Simulado
  late int _maxPageRead;
  bool _progressWasSaved = false;
  // ✅ 2. AÑADIR FORMATEADOR DE NÚMEROS
  final NumberFormat _percentFormat = NumberFormat('##0%');

  int get _safeTotalPages =>
      widget.book.totalPaginas > 0 ? widget.book.totalPaginas : 1;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _currentPage = widget.initialPage.clamp(0, _safeTotalPages - 1);
    _maxPageRead = _currentPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pdfController.jumpToPage(_currentPage + 1);
    });
  }

  @override
  void dispose() async {
    await _saveProgress();
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    if (_maxPageRead > widget.initialPage) {
      try {
        await MyBooksService.updatePageProgress(
          idLibro: widget.book.idLibro,
          newPage: _maxPageRead,
          totalPages: _safeTotalPages,
        );
        _progressWasSaved = true;
        print("✅ Progreso guardado exitosamente.");
      } catch (e) {
        _progressWasSaved = false;
        print("❌ Error al guardar progreso en dispose: $e");
      }
    } else {
      _progressWasSaved = false;
    }
  }

  void _goToPreviousPage() {
    _pdfController.previousPage();
  }

  void _goToNextPage() {
    _pdfController.nextPage();
  }

  Future<void> _exitReaderAndSignal() async {
    await _saveProgress();
    if (mounted) {
      Navigator.of(context).pop(_progressWasSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final pdfUrl = widget.book.urlPdf;
    final pdfUrlEscaped = pdfUrl != null ? Uri.encodeFull(pdfUrl) : null;

    if (pdfUrlEscaped == null || pdfUrlEscaped.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.titulo ?? "Error")),
        backgroundColor: const Color.fromARGB(255, 3, 0, 12),
        body: const Center(
          child: Text(
            "❌ Error: Ruta del PDF no especificada.",
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    final progressValue = (_maxPageRead + 1) / _safeTotalPages;
    // ✅ 3. CALCULAR PORCENTAJE FORMATEADO
    final String progressPercent = _percentFormat.format(progressValue);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 12),
      body: SafeArea(
        child: Column(
          children: [
            // Header con notificaciones, título y racha
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // ... (Row con notificaciones, título, racha sin cambios) ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 28,
                          ),
                          if (_notifications > 0)
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                '$_notifications',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.book.titulo ?? 'Libro',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentStreak',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    // ✅ 4. MODIFICADO: Mostrar el porcentaje formateado
                    child: Text(
                      progressPercent, // Muestra el porcentaje
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold, // Opcional: resaltar
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // PDF Viewer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10,
                ),
                child: Container(
                  // ... (Decoración y SfPdfViewer sin cambios) ...
                   decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                   child: SfPdfViewer.network(
                    pdfUrlEscaped,
                    controller: _pdfController,
                    pageSpacing: 0,
                    canShowPaginationDialog: false,
                    onDocumentLoaded: (details) {
                      print(
                        "PDF cargado, páginas: ${details.document.pages.count}",
                      );
                    },
                    onPageChanged: (details) {
                      if(mounted){
                        setState(() {
                          _currentPage = details.newPageNumber - 1;
                          if (_currentPage > _maxPageRead) {
                            _maxPageRead = _currentPage;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            // Barra inferior de navegación
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: _exitReaderAndSignal,
                    icon: const Icon(Icons.home, size: 36),
                    color: primaryColor,
                  ),
                  IconButton(
                    onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                    icon: Icon(
                      Icons.arrow_back,
                      size: 40,
                      color: _currentPage > 0 ? primaryColor : Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Guardar marcador', // Tooltip añadido
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            // ✅ 5. CONFIRMADO: El SnackBar ya muestra la página correcta
                            'Marcador guardado en la página ${_currentPage + 1}',
                          ),
                           duration: const Duration(seconds: 1), // Más corta
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.bookmark_border,
                      size: 36,
                      color: primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _safeTotalPages - 1
                        ? _goToNextPage
                        : null,
                    icon: Icon(
                      Icons.arrow_forward,
                      size: 40,
                      color: _currentPage < _safeTotalPages - 1
                          ? primaryColor
                          : Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ir a Evaluación (No implementado)',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('FUNCIONALIDAD PENDIENTE: Evaluación del Libro'),
                           backgroundColor: Colors.blueGrey,
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt, size: 36),
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}