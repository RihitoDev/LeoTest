import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  final int _currentStreak = 17;
  final int _notifications = 4;

  int get _safeTotalPages =>
      widget.book.totalPaginas > 0 ? widget.book.totalPaginas : 1;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _currentPage = widget.initialPage.clamp(0, _safeTotalPages - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pdfController.jumpToPage(_currentPage + 1);
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _pdfController.previousPage();
      setState(() {});
    }
  }

  void _goToNextPage() {
    if (_currentPage < _safeTotalPages - 1) {
      _currentPage++;
      _pdfController.nextPage();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Escapar la URL para que no falle por espacios
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

    final progressValue = (_currentPage + 1) / _safeTotalPages;

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
                    child: Text(
                      '${_currentPage + 1}/$_safeTotalPages',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
                      setState(() {
                        _currentPage = details.newPageNumber - 1;
                      });
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
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Marcador guardado en la página ${_currentPage + 1}',
                          ),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navegando a la Evaluación del Libro'),
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
