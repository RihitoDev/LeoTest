import 'package:flutter/material.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Progreso de Lectura', style: TextStyle(color: Colors.white)),
        backgroundColor: cardColor, // Color oscuro para la AppBar
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Resumen de Métricas Clave
            const Text(
              'Métricas Clave',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            _buildKeyMetricsRow(primaryColor, cardColor),

            const SizedBox(height: 30),

            // Sección de Racha Diaria
            _buildSectionTitle('Racha de Lectura', context),
            _buildStreakCard(primaryColor, cardColor),

            const SizedBox(height: 30),

            // Sección de Gráfico (Simulado)
            _buildSectionTitle('Libros Completados por Mes', context),
            _buildSimulatedChart(cardColor),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white70, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildKeyMetricsRow(Color primaryColor, Color cardColor) {
    return Row(
      children: [
        _buildMetricCard(
          cardColor, 
          'Total Libros', 
          '35', 
          Icons.menu_book, 
          primaryColor
        ),
        const SizedBox(width: 16),
        _buildMetricCard(
          cardColor, 
          'Páginas Leídas', 
          '15,200', 
          Icons.auto_stories, 
          Colors.lightBlueAccent
        ),
      ],
    );
  }

  Widget _buildMetricCard(Color cardColor, String title, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Card(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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

  Widget _buildStreakCard(Color primaryColor, Color cardColor) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.local_fire_department, color: primaryColor, size: 40),
        title: const Text('Racha Actual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text('¡Mantente leyendo para no romperla!', style: TextStyle(color: Colors.grey)),
        trailing: Text(
          '5 días',
          style: TextStyle(
            color: primaryColor, 
            fontSize: 24, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedChart(Color cardColor) {
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
            offset: const Offset(0, 3)
          )
        ]
      ),
      alignment: Alignment.center,
      child: const Text(
        'Gráfico de Progreso Simulado',
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }
}