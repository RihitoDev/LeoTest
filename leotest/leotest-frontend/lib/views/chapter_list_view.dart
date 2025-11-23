import 'package:flutter/material.dart';
import 'package:leotest/services/evaluation_service.dart';
import 'evaluation_view.dart';

class ChapterListView extends StatefulWidget {
  final int idLibro;
  final int idPerfil;

  const ChapterListView({
    super.key,
    required this.idLibro,
    required this.idPerfil,
  });

  @override
  State<ChapterListView> createState() => _ChapterListViewState();
}

class _ChapterListViewState extends State<ChapterListView> {
  bool _loading = true;
  List<dynamic> _chapters = [];
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final resp = await EvaluationService.fetchChapters(widget.idLibro);

    if (!mounted) return;

    if (resp['success']) {
      setState(() {
        _chapters = resp['data']['capitulos'];
      });
    } else {
      setState(() => _error = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener capítulos')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecciona un Capítulo"),
        backgroundColor: const Color(0xFF0F0F18), // MÁS OSCURO
      ),
      backgroundColor: const Color(0xFF080812), // MÁS OSCURO

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? _buildRetry()
          : _chapters.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final cap = _chapters[index];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131F), // TARJETAS MÁS OSCURAS
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      "Capítulo ${cap['numero_capitulo']}: ${cap['titulo_capitulo']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.indigo.shade300,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EvaluationView(
                            idCapitulo: cap['id_capitulo'],
                            idLibro: widget.idLibro,
                            idPerfil: widget.idPerfil,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        "No hay capítulos disponibles",
        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
      ),
    );
  }

  Widget _buildRetry() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Error al cargar los capítulos",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _fetchChapters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }
}
