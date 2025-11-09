// lib/models/perfil.dart

class Perfil {
  final int id;
  final String nombre;
  final int edad;
  final String nivelEducativo;
  final String? imagen;

  Perfil({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.nivelEducativo,
    this.imagen,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id_perfil'],
      nombre: json['nombre_perfil'],
      edad: json['edad'],
      nivelEducativo: json['nivel_educativo'],
      imagen: json['imagen_perfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_perfil': id,
      'nombre_perfil': nombre,
      'edad': edad,
      'nivel_educativo': nivelEducativo,
      'imagen_perfil': imagen,
    };
  }
}
