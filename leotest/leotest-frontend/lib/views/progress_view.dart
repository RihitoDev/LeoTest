// lib/views/progress_view.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import necesario para los gráficos
import '../services/progress_service.dart';

class ProgressView extends StatefulWidget {
  final int userId;
  const ProgressView({super.key, required this.userId});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  late Future<List<BookProgress>> _futureProgress;
  int rachaDias = 0; // 🔥 ahora se carga desde la API

  @override
  void initState() {
    super.initState();

    print("🚀 [ProgressView] INIT - USER ID: ${widget.userId}");

    _futureProgress = ProgressService.getUserProgress(widget.userId);

    // 🔥 Obtener racha REAL desde API
    ProgressService.getReadingStreak(widget.userId).then((r) {
      setState(() {
        rachaDias = r;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Progreso de Lectura',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: cardColor,
      ),
      body: FutureBuilder<List<BookProgress>>(
        future: _futureProgress,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay libros en progreso."));
          }

          final progressList = snapshot.data!;
          final totalLibros = progressList.length;
          final totalPaginasLeidas = progressList.fold<int>(
            0,
            (sum, b) => sum + b.paginasLeidas,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Métricas Clave',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                _buildKeyMetricsRow(
                  primaryColor,
                  cardColor,
                  totalLibros,
                  totalPaginasLeidas,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('Racha de Lectura', context),
                _buildStreakCard(primaryColor, cardColor, rachaDias),
                const SizedBox(height: 30),
                _buildSectionTitle('Libros Completados por Mes', context),
                _buildBooksPerMonthChart(cardColor, progressList),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeyMetricsRow(
    Color primaryColor,
    Color cardColor,
    int totalLibros,
    int totalPaginasLeidas,
  ) {
    return Row(
      children: [
        _buildMetricCard(
          cardColor,
          'Total Libros',
          '$totalLibros',
          Icons.menu_book,
          primaryColor,
        ),
        const SizedBox(width: 16),
        _buildMetricCard(
          cardColor,
          'Páginas Leídas',
          '$totalPaginasLeidas',
          Icons.auto_stories,
          Colors.lightBlueAccent,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    Color cardColor,
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Expanded(
      child: Card(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Icon(icon, color: iconColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStreakCard(Color primaryColor, Color cardColor, int rachaDias) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.local_fire_department,
          color: primaryColor,
          size: 40,
        ),
        title: const Text(
          'Racha Actual',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          '¡Mantente leyendo para no romperla!',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          '$rachaDias días',
          style: TextStyle(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBooksPerMonthChart(
    Color cardColor,
    List<BookProgress> progressList,
  ) {
    // Contar libros completados por mes
    Map<String, int> data = {
      "Ene": 0,
      "Feb": 0,
      "Mar": 0,
      "Abr": 0,
      "May": 0,
      "Jun": 0,
      "Jul": 0,
      "Ago": 0,
      "Sep": 0,
      "Oct": 0,
      "Nov": 0,
      "Dic": 0,
    };

    for (var b in progressList) {
      if (b.estado == "Completado" && b.fechaFin != null) {
        DateTime fin = DateTime.parse(b.fechaFin!);
        String mes = [
          "Ene",
          "Feb",
          "Mar",
          "Abr",
          "May",
          "Jun",
          "Jul",
          "Ago",
          "Sep",
          "Oct",
          "Nov",
          "Dic",
        ][fin.month - 1];
        data[mes] = (data[mes] ?? 0) + 1;
      }
    }

    final months = data.keys.toList();
    final values = data.values.toList();

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, horizontalInterval: 1),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, interval: 1),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < 0 || value.toInt() >= months.length) {
                        return const SizedBox();
                      }
                      return Text(
                        months[value.toInt()],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      );
                    },
                    interval: 1,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    values.length,
                    (i) => FlSpot(i.toDouble(), values[i].toDouble()),
                  ),
                  isCurved: true,
                  barWidth: 3,
                  color: Colors.blueAccent,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
