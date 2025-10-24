import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';
// 🚨 Importa el paquete de visor de PDF
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class BookReaderView extends StatefulWidget {
  final Book book;
  final int initialPage;

  const BookReaderView({
    super.key, 
    required this.book,
    this.initialPage = 0, // La página desde donde comienza a leer
  });

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  late int _currentPage;
  // late final PdfViewerController _pdfViewerController; // Si usas controlador
  
  // Valores estáticos simulados para los iconos del header
  final int _currentStreak = 17; 
  final int _notifications = 4; 
  
  // Getter para calcular las páginas totales de forma segura.
  int get _safeTotalPages {
    // Si usas el controlador del PDF, debes obtener el número real de páginas de él,
    // pero por ahora usamos el del modelo.
    final total = widget.book.totalPaginas ?? 1; 
    return total > 0 ? total : 1;
  }

  @override
  void initState() {
    super.initState();
    // _pdfViewerController = PdfViewerController(); // Inicializar controlador
    _currentPage = widget.initialPage.clamp(0, _safeTotalPages - 1);
  }

  void _goToPreviousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
        // _pdfViewerController.previousPage(); // Mover página en el PDF
      }
    });
  }

  void _goToNextPage() {
    setState(() {
      if (_currentPage < _safeTotalPages - 1) {
        _currentPage++;
        // _pdfViewerController.nextPage(); // Mover página en el PDF
      }
    });
  }

  // WIDGET PRINCIPAL
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 🚨 Obtener la URL del PDF del modelo
    final pdfUrl = widget.book.urlPdf;
    
    // Manejo de error si la URL no está
    if (pdfUrl == null || pdfUrl.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.book.titulo ?? "Error"), 
          backgroundColor: Colors.transparent,
        ),
        backgroundColor: const Color.fromARGB(255, 3, 0, 12),
        body: const Center(
          child: Text("❌ Error: Ruta del PDF no especificada en el modelo.", style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 0, 12),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header de Progreso y Gamificación 
            _buildHeader(context, primaryColor, _safeTotalPages),

            // 2. Contenedor del Lector PDF
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
                child: Container(
                  width: double.infinity,
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
                  child: 
                    // 🚨 WIDGET DEL VISOR DE PDF REAL 🚨
                    SfPdfViewer.network(
                      pdfUrl, 
                      // controller: _pdfViewerController, // Habilitar si usas un controlador
                      pageSpacing: 0,
                      canShowPaginationDialog: false, // Deshabilitar UI nativa si usas tu propia navegación
                      onPageChanged: (PdfPageChangedDetails details) {
                        // Actualizar _currentPage cuando el usuario arrastra el PDF
                        setState(() {
                           // Asumiendo que las páginas en el PDF empiezan en 1
                           _currentPage = details.newPageNumber - 1; 
                        });
                      },
                    ),
                ),
              ),
            ),

            // 3. Barra de Navegación Inferior
            _buildBottomNavigation(context, primaryColor),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: Construye la cabecera con iconos y barra de progreso
  Widget _buildHeader(BuildContext context, Color primaryColor, int totalPages) {
    final progressValue = (_currentPage + 1) / totalPages;
    
    final bookTitle = widget.book.titulo ?? 'Libro';
    final truncatedTitle = bookTitle.length > 15 
      ? '${bookTitle.substring(0, 15)}...' 
      : bookTitle;
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Notificaciones (Campana)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                  if (_notifications > 0)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('$_notifications', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                    )
                ],
              ),
              
              // 2. Título del Libro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 4),
                  Text(truncatedTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)), 
                ],
              ),
              
              // 3. Racha (Fuego)
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                  const SizedBox(width: 4),
                  Text('$_currentStreak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
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

          // Contador de páginas actual/total
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_currentPage + 1}/$totalPages',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET AUXILIAR: Construye la barra de navegación inferior
  Widget _buildBottomNavigation(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Botón Volver a la Biblioteca (Atrás)
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.home, size: 36),
            color: primaryColor,
          ),

          // 2. Flecha Izquierda (Anterior Página)
          IconButton(
            onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            icon: Icon(Icons.arrow_back, size: 40, color: _currentPage > 0 ? primaryColor : Colors.grey[800]),
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),
          
          // 3. Icono Central (Bookmark/Marcador)
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Marcador guardado en la página ${_currentPage + 1}')),
              );
            },
            icon: Icon(Icons.bookmark_border, size: 36, color: primaryColor),
          ),
          
          // 4. Flecha Derecha (Siguiente Página)
          IconButton(
            onPressed: _currentPage < _safeTotalPages - 1 ? _goToNextPage : null,
            icon: Icon(Icons.arrow_forward, size: 40, color: _currentPage < _safeTotalPages - 1 ? primaryColor : Colors.grey[800]),
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),

          // 5. Botón de Evaluación
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navegando a la Evaluación del Libro')),
              );
            },
            icon: const Icon(Icons.list_alt, size: 36),
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}