import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class ProgressView extends StatefulWidget {
  final int userId;
  const ProgressView({super.key, required this.userId});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  late Future<List<BookProgress>> _futureProgress;

  @override
  void initState() {
    super.initState();

    print("🚀 [ProgressView] INIT - USER ID: ${widget.userId}");

    _futureProgress = ProgressService.getUserProgress(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    print("🔄 [ProgressView] BUILD ejecutado");

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
          print(
            "📌 [FutureBuilder] connectionState = ${snapshot.connectionState}",
          );
          print("📌 [FutureBuilder] hasData = ${snapshot.hasData}");
          print("📌 [FutureBuilder] hasError = ${snapshot.hasError}");
          print("📌 [FutureBuilder] DATA = ${snapshot.data}");
          print("📌 [FutureBuilder] ERROR = ${snapshot.error}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            print("⏳ Esperando datos...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("❌ ERROR: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            print("⚠️ NO HAY DATOS (snapshot.hasData = false)");
            return const Center(child: Text("No hay libros en progreso."));
          }

          if (snapshot.data!.isEmpty) {
            print("⚠️ LISTA VACÍA (snapshot.data!.isEmpty = true)");
            return const Center(child: Text("No hay libros en progreso."));
          }

          final progressList = snapshot.data!;
          print("🎉 Se recibieron ${progressList.length} elementos");

          final totalLibros = progressList.length;
          final totalPaginasLeidas = progressList.fold<int>(
            0,
            (sum, b) => sum + b.paginasLeidas,
          );
          final rachaDias = 5;

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
                _buildSimulatedChart(cardColor),
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
    print(
      "📊 Construyendo métricas: libros=$totalLibros páginas=$totalPaginasLeidas",
    );

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
    print("📌 Construyendo card: $title = $value");

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
    print("📌 Construyendo sección: $title");

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
    print("🔥 Construyendo racha: $rachaDias");

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

  Widget _buildSimulatedChart(Color cardColor) {
    print("📈 Construyendo gráfico simulado");

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Gráfico de Progreso Simulado',
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }
}
