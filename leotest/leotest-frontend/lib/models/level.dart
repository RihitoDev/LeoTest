class Level {
  final int id;
  final String name;
  Level({required this.id, required this.name});
  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(id: json['id_nivel_educativo'], name: json['nombre_nivel_educativo']);
  }
}