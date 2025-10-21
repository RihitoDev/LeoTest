import 'package:flutter/material.dart';
import 'package:leotest/models/book.dart';

class BookDetailView extends StatelessWidget {
  final Book book;

  const BookDetailView({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.titulo, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Portada y Título ---
            Center(
              child: Column(
                children: [
                  _buildCoverImage(book.portada),
                  const SizedBox(height: 15),
                  Text(
                    book.titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Por ${book.autor}',
                    style: TextStyle(fontSize: 18, color: primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. Progreso de Lectura ---
            _buildProgressCard(book, cardColor, primaryColor),
            const SizedBox(height: 30),

            // --- 3. Sinopsis ---
            _buildSectionTitle('Sinopsis', context),
            Text(
              book.descripcion,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // --- 4. Botón de acción ---
            _buildActionButton(context, primaryColor, book.pagesRead),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(String portada) {
    return Container(
      width: 150,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        image: portada.isNotEmpty
            ? DecorationImage(
                image: portada.startsWith('http')
                    ? NetworkImage(portada)
                    : AssetImage(portada) as ImageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: portada.isEmpty
          ? const Icon(Icons.book, color: Colors.white70, size: 40)
          : null,
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressCard(Book book, Color cardColor, Color primaryColor) {
    final progress = (book.progressPercentage * 100).toInt();
    final pagesLeft = book.totalPaginas - book.pagesRead;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso: $progress%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${book.pagesRead} / ${book.totalPaginas} págs.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: book.progressPercentage,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            if (pagesLeft > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Te faltan $pagesLeft páginas para terminar.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Color primaryColor,
    int pagesRead,
  ) {
    final buttonText = pagesRead > 0 ? 'CONTINUAR LEYENDO' : 'INICIAR LECTURA';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Simulando la apertura del libro: ${book.titulo}'),
            ),
          );
        },
        icon: Icon(
          pagesRead > 0 ? Icons.import_contacts : Icons.book_online,
          color: Colors.black,
        ),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
