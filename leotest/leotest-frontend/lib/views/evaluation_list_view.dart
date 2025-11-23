// lib/views/evaluation_list_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/services/evaluation_service.dart';

class EvaluationListView extends StatefulWidget {
  final int idPerfil;

  const EvaluationListView({super.key, required this.idPerfil});

  @override
  State<EvaluationListView> createState() => _EvaluationListViewState();
}

class _EvaluationListViewState extends State<EvaluationListView> {
  bool _loading = true;
  List<dynamic> _evaluaciones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resp = await EvaluationService.fetchEvaluacionesPerfil(
      widget.idPerfil,
    );

    if (resp['success']) {
      setState(() {
        _evaluaciones = resp['data']['evaluaciones'] ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error cargando evaluaciones")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Evaluaciones")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _evaluaciones.isEmpty
          ? const Center(child: Text("No tienes evaluaciones todavía"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _evaluaciones.length,
              itemBuilder: (context, index) {
                final e = _evaluaciones[index];
                final progreso = (e['test_completados'] / e['total_test'])
                    .toDouble()
                    .clamp(0, 1);
                Color progresoColor = progreso >= 0.8
                    ? Colors.green
                    : (progreso >= 0.5 ? Colors.orange : Colors.red);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['titulo_libro'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progreso,
                          color: progresoColor,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${e['test_completados']}/${e['total_test']} tests completados",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Puntaje: ${e['puntaje_total']}"),
                            Text(
                              e['fecha_actualizacion'].toString().split('.')[0],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
