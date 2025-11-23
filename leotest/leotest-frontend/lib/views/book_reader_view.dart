import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:leotest/services/my_books_service.dart';
import 'package:leotest/services/stats_service.dart';
import 'package:leotest/views/chapter_list_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

class BookReaderView extends StatefulWidget {
  final Book book;
  final int initialPage;
  final int idPerfil; // 🔹 NUEVO PARÁMETRO

  const BookReaderView({
    super.key,
    required this.book,
    this.initialPage = 0,
    required this.idPerfil, // 🔹 requerido
  });

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  late int _currentPage;
  late final PdfViewerController _pdfController;
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

    // 🔹 Corregido: índice máximo = totalPaginas - 1
    _currentPage = widget.initialPage.clamp(0, _safeTotalPages - 1);
    _maxPageRead = _currentPage;

    _futureCurrentStreak = StatsService.fetchCurrentStreak();

    // 🔹 Saltar a la página inicial (PdfViewer cuenta desde 1)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pdfController.jumpToPage(_currentPage + 1);
    });
  }

  @override
  void dispose() {
    // Guardado de progreso sin await
    _saveProgress();
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
          idPerfil: widget.idPerfil,
        );

        // Actualizamos localmente
        if (mounted)
          setState(() {
            _currentPage = _maxPageRead;
          });

        _progressWasSaved = true;
        print("✅ Progreso guardado exitosamente.");
      } catch (e) {
        _progressWasSaved = false;
        print("❌ Error al guardar progreso: $e");
      }
    }
  }

  void _goToPreviousPage() => _pdfController.previousPage();
  void _goToNextPage() => _pdfController.nextPage();

  Future<void> _exitReaderAndSignal() async {
    await _saveProgress();
    if (mounted) Navigator.of(context).pop(_progressWasSaved);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final pdfUrl = widget.book.urlPdf;
    final pdfUrlEscaped = pdfUrl != null ? Uri.encodeFull(pdfUrl) : null;
    final progressValue = _maxPageRead / _safeTotalPages;
    final String progressPercent = _percentFormat.format(progressValue);

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

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 12),
      body: SafeArea(
        child: Column(
          children: [
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
                          // Puedes mantener tus notificaciones aquí si quieres
                        ],
                      ),
                      // Título del libro
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
                      // Racha actual
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
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 5),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                    onPageChanged: (details) {
                      if (mounted) {
                        setState(() {
                          _currentPage = details.newPageNumber - 1;

                          // 🔹 Permitir llegar a 100%
                          if (_currentPage >= _safeTotalPages - 1) {
                            _maxPageRead = _safeTotalPages;
                          } else if (_currentPage > _maxPageRead) {
                            _maxPageRead = _currentPage;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
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
                    tooltip: 'Ir a Evaluación',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChapterListView(
                            idLibro: widget.book.idLibro,
                            idPerfil: widget.idPerfil, // 🔹 PASAMOS idPerfil
                          ),
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
