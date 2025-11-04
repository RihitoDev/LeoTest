// lib/views/book_reader_view.dart (Ajustar este archivo en el frontend)

import 'package:flutter/material.dart';
import 'package:leotest/main.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/my_books_service.dart';
import 'package:leotest/services/stats_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

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
  final int _notifications = 4;
  late int _maxPageRead;
  bool _progressWasSaved = false;
  final NumberFormat _percentFormat = NumberFormat('##0%');
  late Future<int> _futureCurrentStreak;

  int get _safeTotalPages =>
      widget.book.totalPaginas > 0 ? widget.book.totalPaginas : 1;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _currentPage = widget.initialPage.clamp(0, _safeTotalPages - 1);
    _maxPageRead = _currentPage;
    _futureCurrentStreak = StatsService.fetchCurrentStreak();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pdfController.jumpToPage(_currentPage + 1);
    });
  }

  // ✅ CORRECCIÓN 1: El método dispose ya NO es async.
  // Llama a la función asíncrona de guardado pero no espera por ella aquí.
  @override
  void dispose() {
    // Llamada sin await, pero la función _saveProgress es la que maneja la asyncronía
    _saveProgress(); 
    _pdfController.dispose();
    super.dispose(); // ✅ Asegura que se llama a super.dispose()
  }

  // ✅ CORRECCIÓN 2: _saveProgress ahora se encarga de la asyncronía y usa el result del push.
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

  // ✅ CORRECCIÓN 3: El exitReader ahora sí es async para asegurar el guardado
  Future<void> _exitReaderAndSignal() async {
    // 1. Espera a que el guardado termine ANTES de cerrar la pantalla
    await _saveProgress(); 

    if (mounted) {
      // 2. Devuelve si se guardó progreso o no
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
    final String progressPercent = _percentFormat.format(progressValue);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 12),
      body: SafeArea(
        child: Column(
          children: [
            // ... (Header sin cambios) ...
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Notificaciones
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
                      // Título del Libro
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
                      // Integración: Racha
                      FutureBuilder<int>(
                        future: _futureCurrentStreak,
                        builder: (context, snapshot) {
                          final currentStreak = snapshot.data ?? 0;
                          return Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 28,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$currentStreak',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Barra de Progreso
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 5),
                  // Indicador de Porcentaje
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      progressPercent, 
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                  // ... (Resto de botones sin cambios) ...
                  IconButton(
                    onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                    icon: Icon(
                      Icons.arrow_back,
                      size: 40,
                      color: _currentPage > 0 ? primaryColor : Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Guardar marcador', 
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Marcador guardado en la página ${_currentPage + 1}',
                          ),
                           duration: const Duration(seconds: 1), 
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