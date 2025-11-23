import 'package:flutter/material.dart';
import 'package:leotest/models/mission.dart';
import 'package:leotest/services/mission_service.dart';

class MissionsView extends StatefulWidget {
  final int? profileId;

  const MissionsView({super.key, this.profileId});

  @override
  State<MissionsView> createState() => _MissionsViewState();
}

class _MissionsViewState extends State<MissionsView>
    with SingleTickerProviderStateMixin {
  late Future<List<Mission>> _futureMissions;
  late TabController _tabController;
  final List<String> _tabs = const ['Diarias', 'Mensuales', 'Generales'];
  late int idPerfil;

  @override
  void initState() {
    super.initState();
    idPerfil = widget.profileId ?? 0;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadMissions();
  }

  void _loadMissions() {
    setState(() {
      _futureMissions = MissionService.fetchActiveMissions(idPerfil);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Muestra el diálogo de confirmación y marca la misión como completada
  Future<void> _handleCompleteMission(Mission mission) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Completar Misión'),
          content: Text(
            '¿Marcar la misión "${mission.nombreMision}" como completada?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Confirmar',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completando misión "${mission.nombreMision}"...'),
        ),
      );

      final success = await MissionService.completeMission(
        mission.idUsuarioMision,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success && mounted) {
        setState(() {
          _futureMissions = MissionService.fetchActiveMissions(idPerfil);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Misión completada: ${mission.nombreMision}!'),
            backgroundColor: Colors.green[700],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al completar la misión. Verifique su progreso.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Misiones',
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 4, 8),
        elevation: 1,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((name) => Tab(text: name)).toList(),
        ),
      ),
      body: FutureBuilder<List<Mission>>(
        future: _futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allMissions = snapshot.data ?? [];

          final dailyMissions = allMissions
              .where((m) => m.frecuencia.toLowerCase() == 'diarias')
              .toList();
          final monthlyMissions = allMissions
              .where((m) => m.frecuencia.toLowerCase() == 'mensuales')
              .toList();
          final generalMissions = allMissions
              .where((m) => m.frecuencia.toLowerCase() == 'generales')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMissionList(context, dailyMissions),
              _buildMissionList(context, monthlyMissions),
              _buildMissionList(context, generalMissions),
            ],
          );
        },
      ),
    );
  }

  /// Widget auxiliar para construir la lista de misiones
  Widget _buildMissionList(BuildContext context, List<Mission> missions) {
    if (missions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No hay misiones activas en esta categoría.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        final isComplete =
            mission.misionCompleta || mission.progressPercentage >= 1.0;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Card(
          color: const Color.fromARGB(255, 15, 10, 30),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.task_alt,
              color: isComplete ? Colors.green : primaryColor,
            ),
            title: Text(
              mission.nombreMision,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.descripcionMision,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: mission.progressPercentage,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? Colors.green : primaryColor,
                  ),
                  minHeight: 5,
                ),
                const SizedBox(height: 3),
                Text(
                  'Progreso: ${mission.progresoMision.toStringAsFixed(1)} / ${mission.cantidadObjetivo} '
                  '(${(mission.progressPercentage * 100).toInt()}%)',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
            trailing: isComplete
                ? const Icon(Icons.star, color: Colors.amber, size: 30)
                : IconButton(
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white70,
                    ),
                    onPressed: mission.progressPercentage >= 1.0
                        ? () => _handleCompleteMission(mission)
                        : null,
                    tooltip: mission.progressPercentage >= 1.0
                        ? 'Marcar como Completada'
                        : 'Progreso insuficiente',
                  ),
          ),
        );
      },
    );
  }
}
