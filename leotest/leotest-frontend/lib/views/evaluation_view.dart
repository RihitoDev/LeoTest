import 'package:flutter/material.dart';
import 'package:leotest/services/evaluation_service.dart';

class EvaluationView extends StatefulWidget {
  final int idCapitulo;
  final int idLibro;
  final int idPerfil;

  const EvaluationView({
    super.key,
    required this.idCapitulo,
    required this.idLibro,
    required this.idPerfil,
  });

  @override
  State<EvaluationView> createState() => _EvaluationViewState();
}

class _EvaluationViewState extends State<EvaluationView> {
  bool _loading = true;
  bool _submitted = false; // <- Nuevo flag
  List<dynamic> _preguntas = [];
  Map<int, int?> _selectedOption = {}; // id_pregunta -> id_opcion_multiple
  Map<int, bool> _correctAnswers = {}; // id_pregunta -> si acertó
  Map<int, int> _correctOption =
      {}; // id_pregunta -> id_opcion_multiple correcta
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
    });

    // Generar preguntas si no existen
    final gen = await EvaluationService.generarPreguntas(widget.idCapitulo);
    if (!gen['success']) {
      print("❌ Generar preguntas error: ${gen['message']}");
    } else {
      print("✅ Preguntas generadas correctamente (si era necesario).");
    }

    // Traer preguntas
    final resp = await EvaluationService.fetchPreguntas(widget.idCapitulo);
    if (resp['success']) {
      setState(() {
        _preguntas = resp['data']['preguntas'] ?? [];
        for (var p in _preguntas) {
          _selectedOption[p['id_pregunta']] = null;
        }
      });
      print("✅ Preguntas cargadas: ${_preguntas.length}");
    } else {
      print("❌ Error al cargar preguntas");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar preguntas')),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  void _select(int idPregunta, int idOpcion) {
    if (!_correctAnswers.containsKey(idPregunta)) {
      setState(() {
        _selectedOption[idPregunta] = idOpcion;
      });
      print("➡️ Pregunta $idPregunta seleccionada opción $idOpcion");
    }
  }

  Future<void> _submit() async {
    final endTime = DateTime.now();
    final minutosLeidos = endTime.difference(_startTime).inMinutes;

    final respuestas = _selectedOption.entries
        .map((e) => {"id_pregunta": e.key, "id_opcion_multiple": e.value})
        .toList();

    print("🔹 Enviando respuestas al backend:");
    for (var r in respuestas) {
      print(
        "Pregunta ${r['id_pregunta']} -> Opción seleccionada: ${r['id_opcion_multiple']}",
      );
    }

    final resp = await EvaluationService.submitEvaluation(
      idLibro: widget.idLibro,
      idPerfil: widget.idPerfil,
      respuestas: respuestas,
      minutosLeidos: minutosLeidos,
    );

    print("🔹 Respuesta del backend:");
    print(resp);

    if (resp['success'] == true) {
      final resultados = (resp['data']['resultados'] as List<dynamic>?) ?? [];

      print("🔹 Procesando resultados recibidos:");
      for (var r in resultados) {
        print(
          "Pregunta ${r['id_pregunta']} -> seleccion_usuario: ${r['seleccion_usuario']}, opcion_correcta: ${r['opcion_correcta']}, correcta: ${r['correcta']}",
        );
      }

      // Guardar los resultados en los estados locales
      setState(() {
        for (var r in resultados) {
          final idPregunta = r['id_pregunta'] as int;
          _correctAnswers[idPregunta] = r['correcta'] == true;
          _selectedOption[idPregunta] = r['seleccion_usuario'] as int?;
          _correctOption[idPregunta] = r['opcion_correcta'] as int;
        }

        _submitted = true; // <- Marcar como enviado
      });
    } else {
      print("❌ Error enviando evaluación");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error enviando evaluación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Evaluación", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _preguntas.isEmpty
          ? const Center(
              child: Text(
                "No hay preguntas para este capítulo",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _preguntas.length,
              itemBuilder: (context, index) {
                final p = _preguntas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pregunta ${index + 1}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p['enunciado'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...p['opciones'].map<Widget>((o) {
                          final idPregunta = p['id_pregunta'] as int;
                          final isSelected =
                              _selectedOption[idPregunta] ==
                              o['id_opcion_multiple'];
                          final isCorrect =
                              _correctOption[idPregunta] ==
                              o['id_opcion_multiple'];

                          Color borderColor = isSelected
                              ? primaryColor
                              : Colors.grey.shade700;
                          Color bgColor = isSelected
                              ? primaryColor.withOpacity(0.25)
                              : backgroundColor.withOpacity(0.4);

                          if (_correctAnswers.containsKey(idPregunta)) {
                            if (isCorrect) {
                              borderColor = Colors.green;
                              bgColor = Colors.green.withOpacity(0.25);
                            } else if (isSelected && !isCorrect) {
                              borderColor = Colors.red;
                              bgColor = Colors.red.withOpacity(0.25);
                            }
                          }

                          return GestureDetector(
                            onTap: _submitted
                                ? null
                                : () => _select(
                                    idPregunta,
                                    o['id_opcion_multiple'],
                                  ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: 2,
                                ),
                                color: bgColor,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: borderColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      o['texto_opcion'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: backgroundColor,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: primaryColor,
          ),
          onPressed:
              (_selectedOption.values.any((v) => v != null) && !_submitted)
              ? _submit
              : null,
          child: const Text(
            "Enviar evaluación",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
