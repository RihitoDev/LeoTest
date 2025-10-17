// lib/models/book.dart

class Book {
  final String title;
  final String author;
  final String coverUrl;

  const Book(this.title, this.author, this.coverUrl);
}

// Datos de ejemplo simulando 2, 3 y 2 libros por clase.
final List<Book> class1Books = const [
  Book('Física de Partículas', 'J. Smith', 'url1'),
  Book('Cálculo Avanzado', 'A. Doe', 'url2'),
];

final List<Book> class2Books = const [
  Book('Química Orgánica', 'L. Chen', 'url3'),
  Book('Termodinámica', 'R. Patil', 'url4'),
  Book('Mecánica Clásica', 'E. Newton', 'url5'),
];

final List<Book> class3Books = const [
  Book('Programación Dart', 'S. Khan', 'url6'),
  Book('Flutter UI', 'J. Lee', 'url7'),
];