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
  List<dynamic> _preguntas = [];
  Map<int, int?> _selectedOption = {}; // id_pregunta -> id_opcion_multiple

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
    });

    // 1) Generar preguntas (si aún no existe en DB)
    final gen = await EvaluationService.generarPreguntas(widget.idCapitulo);
    if (!gen['success']) {
      // Puede que ya estén generadas; ignoramos error y seguimos a fetch
      print("Generar preguntas error: ${gen['message']}");
    }

    // 2) Obtener preguntas en DB
    final resp = await EvaluationService.fetchPreguntas(widget.idCapitulo);
    if (resp['success']) {
      setState(() {
        _preguntas = resp['data']['preguntas'] ?? [];
        for (var p in _preguntas) {
          _selectedOption[p['id_pregunta']] = null;
        }
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar preguntas')));
    }

    setState(() {
      _loading = false;
    });
  }

  void _select(int idPregunta, int idOpcion) {
    setState(() {
      _selectedOption[idPregunta] = idOpcion;
    });
  }

  Future<void> _submit() async {
    // Construir respuestas
    final respuestas = <Map<String, dynamic>>[];
    _selectedOption.forEach((idPregunta, idOpcion) {
      respuestas.add({
        "id_pregunta": idPregunta,
        "id_opcion_multiple": idOpcion,
      });
    });

    final resp = await EvaluationService.submitEvaluation(
      idLibro: widget.idLibro,
      idPerfil: widget.idPerfil,
      respuestas: respuestas,
    );

    if (resp['success']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Evaluación enviada')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error enviando evaluación')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Evaluación")),
      body: _preguntas.isEmpty
          ? const Center(child: Text("No hay preguntas para este capítulo"))
          : ListView.builder(
              itemCount: _preguntas.length,
              itemBuilder: (context, index) {
                final p = _preguntas[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Q${index + 1}. ${p['enunciado']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...p['opciones'].map<Widget>((o) {
                          return RadioListTile<int>(
                            value: o['id_opcion_multiple'],
                            groupValue: _selectedOption[p['id_pregunta']],
                            onChanged: (val) {
                              if (val != null) _select(p['id_pregunta'], val);
                            },
                            title: Text(o['texto_opcion'] ?? ""),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _selectedOption.values.any((v) => v != null)
              ? _submit
              : null,
          child: const Text("Enviar evaluación"),
        ),
      ),
    );
  }
}
