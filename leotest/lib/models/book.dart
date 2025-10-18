// lib/models/book.dart

class Book {
  final String id; // Añadido para identificación única
  final String title;
  final String author;
  final String coverUrl; // URL o ruta del asset de la portada
  final String synopsis; // Propiedad necesaria para la ficha
  final int totalPages; // Propiedad necesaria para el progreso
  final int pagesRead; // Propiedad necesaria para el progreso

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.synopsis,
    required this.totalPages,
    required this.pagesRead,
  });

  // Método para calcular el progreso de lectura
  double get progressPercentage => totalPages > 0 ? (pagesRead / totalPages) : 0.0;
}

// Datos de ejemplo simulando 2, 3 y 2 libros por clase con todos los campos.
final List<Book> class1Books = const [
  Book(
    id: 'C1-B1',
    title: 'Física de Partículas',
    author: 'J. Smith',
    coverUrl: 'assets/covers/cover1.jpg',
    synopsis: 'Introducción profunda a la física subatómica y los componentes fundamentales del universo.',
    totalPages: 450,
    pagesRead: 210, // 46% de progreso
  ),
  Book(
    id: 'C1-B2',
    title: 'Cálculo Avanzado',
    author: 'A. Doe',
    coverUrl: 'assets/covers/cover2.jpg',
    synopsis: 'Teoría y aplicaciones de cálculo vectorial, series y transformadas.',
    totalPages: 580,
    pagesRead: 0, // 0% de progreso
  ),
];

final List<Book> class2Books = const [
  Book(
    id: 'C2-B1',
    title: 'Química Orgánica',
    author: 'L. Chen',
    coverUrl: 'assets/covers/cover3.jpg',
    synopsis: 'Estudio de la estructura, propiedades y reacciones de los compuestos orgánicos.',
    totalPages: 720,
    pagesRead: 720, // 100% de progreso (Libro terminado)
  ),
  Book(
    id: 'C2-B2',
    title: 'Termodinámica',
    author: 'R. Patil',
    coverUrl: 'assets/covers/cover4.jpg',
    synopsis: 'Los principios de la energía, el calor y el trabajo, esenciales para la ingeniería.',
    totalPages: 350,
    pagesRead: 100,
  ),
  Book(
    id: 'C2-B3',
    title: 'Mecánica Clásica',
    author: 'E. Newton',
    coverUrl: 'assets/covers/cover5.jpg',
    synopsis: 'Desde las leyes de Newton hasta el formalismo Lagrangiano y Hamiltoniano.',
    totalPages: 410,
    pagesRead: 50,
  ),
];

final List<Book> class3Books = const [
  Book(
    id: 'C3-B1',
    title: 'Programación Dart',
    author: 'S. Khan',
    coverUrl: 'assets/covers/cover6.jpg',
    synopsis: 'Aprende el lenguaje Dart, desde la sintaxis básica hasta la programación asíncrona.',
    totalPages: 300,
    pagesRead: 120,
  ),
  Book(
    id: 'C3-B2',
    title: 'Flutter UI',
    author: 'J. Lee',
    coverUrl: 'assets/covers/cover7.jpg',
    synopsis: 'Guía práctica para construir interfaces de usuario hermosas y nativas con Flutter.',
    totalPages: 380,
    pagesRead: 300,
  ),
];