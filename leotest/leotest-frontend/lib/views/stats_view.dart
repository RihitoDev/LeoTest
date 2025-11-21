// lib/views/stats_view.dart
import 'package:flutter/material.dart';
import 'package:leotest/services/stats_service.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  late Future<GeneralStats> futureStats;

  @override
  void initState() {
    super.initState();
    futureStats = StatsService.fetchGeneralStats();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("Estadísticas")),
      body: FutureBuilder<GeneralStats>(
        future: futureStats,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final stats = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildItem("Racha actual", "${stats.rachaDias} días"),
              _buildItem("Libros leídos", "${stats.librosLeidos ?? 0}"),
              _buildItem(
                "Tests completados",
                "${stats.totalTestCompletados ?? 0}",
              ),
              _buildItem(
                "Velocidad de lectura",
                "${stats.velocidadLectura ?? 0} ppm",
              ),
              _buildItem(
                "Porcentaje de aciertos",
                "${stats.porcentajeAciertos ?? 0}%",
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
