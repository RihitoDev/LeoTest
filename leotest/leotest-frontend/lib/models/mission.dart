// lib/models/mission.dart

class Mission {
  final int idUsuarioMision; // ID de la fila en usuario_mision
  final int idMision;
  final String nombreMision;
  final String descripcionMision;
  final String frecuencia; // "Diarias", "Mensuales", "Generales"
  final String tipoObjetivo; // "Paginas Leídas", "Tests Completados"
  final int cantidadObjetivo; // Valor requerido (e.g., 10)
  final double progresoMision; // Progreso actual (e.g., 5.0)
  final bool misionCompleta;
  
  Mission({
    required this.idUsuarioMision,
    required this.idMision,
    required this.nombreMision,
    required this.descripcionMision,
    required this.frecuencia,
    required this.tipoObjetivo,
    required this.cantidadObjetivo,
    required this.progresoMision,
    required this.misionCompleta,
  });

  // Cálculo del porcentaje de progreso
  double get progressPercentage => (progresoMision / cantidadObjetivo).clamp(0.0, 1.0);

  factory Mission.fromJson(Map<String, dynamic> json) {
    // Captura el valor que puede venir como String o como num
    final rawProgress = json['progreso_mision'];
    double parsedProgress;
    
    // ✅ CORRECCIÓN: Manejar String o num de forma segura
    if (rawProgress is String) {
      // Si es String (ej. "0.00" o "5.00"), usar double.parse
      parsedProgress = double.parse(rawProgress);
    } else if (rawProgress is num) {
      // Si es num, convertir directamente a double
      parsedProgress = rawProgress.toDouble();
    } else {
      // Valor por defecto en caso de nulo o tipo inesperado
      parsedProgress = 0.0;
    }

    return Mission(
      idUsuarioMision: json['id_usuario_mision'] as int,
      idMision: json['id_mision'] as int,
      nombreMision: json['nombre_mision'] as String,
      descripcionMision: json['descripcion_mision'] as String,
      frecuencia: json['frecuencia'] as String,
      tipoObjetivo: json['tipo_objetivo'] as String,
      cantidadObjetivo: json['cantidad_objetivo'] as int,
      progresoMision: parsedProgress, // Usar el valor parseado
      misionCompleta: json['mision_completa'] as bool,
    );
  }
}