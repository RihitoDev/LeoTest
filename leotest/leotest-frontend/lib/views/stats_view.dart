// lib/views/stats_view.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔹 Racha de lectura
                Card(
                  color: primaryColor.withOpacity(0.1),
                  child: ListTile(
                    leading: Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 40,
                    ),
                    title: const Text("Racha de lectura"),
                    trailing: Text(
                      stats.rachaDias != null && stats.rachaDias! > 0
                          ? "${stats.rachaDias} días"
                          : "Sin racha",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Libros leídos (con gráfico de progreso y progreso total)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Libros leídos",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value:
                              (stats.librosLeidos ?? 0) /
                              ((stats.totalLibros ?? 1).toDouble()),
                          color: Colors.blueAccent,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${stats.librosLeidos ?? 0} de ${stats.totalLibros ?? 0}",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Tests completados
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tests completados",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value:
                              (stats.totalTestCompletados ?? 0) /
                              ((stats.totalTests ?? 1).toDouble()),
                          color: Colors.greenAccent,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${stats.totalTestCompletados ?? 0} de ${stats.totalTests ?? 0}",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Gráfico de Tests y Aciertos en porcentaje
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Progreso Tests y Aciertos",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100, // eje Y en porcentaje
                              barGroups: [
                                // Tests completados
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY:
                                          ((stats.totalTestCompletados ?? 0) /
                                                  ((stats.totalTests ?? 1)
                                                      .toDouble()) *
                                                  100)
                                              .clamp(0, 100), // porcentaje
                                      color: Colors.greenAccent,
                                      width: 30,
                                      borderRadius: BorderRadius.circular(6),
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                            show: true,
                                            toY: 100,
                                            color: Colors.greenAccent
                                                .withOpacity(0.2),
                                          ),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0],
                                ),
                                // Aciertos
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (stats.porcentajeAciertos ?? 0)
                                          .toDouble(),
                                      color: Colors.teal,
                                      width: 30,
                                      borderRadius: BorderRadius.circular(6),
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                            show: true,
                                            toY: 100,
                                            color: Colors.teal.withOpacity(0.2),
                                          ),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0],
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 20, // marcas cada 20%
                                    getTitlesWidget: (value, meta) {
                                      return Text("${value.toInt()}%");
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text("Tests");
                                        case 1:
                                          return const Text("Aciertos");
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 20,
                              ),
                              borderData: FlBorderData(show: false),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        String label = groupIndex == 0
                                            ? "Tests"
                                            : "Aciertos";
                                        return BarTooltipItem(
                                          "$label: ${rod.toY.toInt()}%",
                                          const TextStyle(color: Colors.white),
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Velocidad de lectura y porcentaje de aciertos
                Column(
                  children: [
                    _metricCard(
                      "Velocidad",
                      "${stats.velocidadLectura ?? 0} ppm",
                      Colors.purple,
                      Icons.speed,
                    ),
                    const SizedBox(height: 12),
                    _metricCard(
                      "Aciertos",
                      "${stats.porcentajeAciertos ?? 0}%",
                      Colors.teal,
                      Icons.check_circle,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

String pluralizeText(String singular, String plural, int count) {
  return count == 1 ? singular : plural;
}
