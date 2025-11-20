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

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    setState(() {
      _loading = true;
    });
    final resp = await EvaluationService.fetchChapters(widget.idLibro);
    if (resp['success']) {
      setState(() {
        _chapters = resp['data']['capitulos'];
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener capítulos')));
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Seleccionar Capítulo")),
      body: ListView.builder(
        itemCount: _chapters.length,
        itemBuilder: (context, index) {
          final cap = _chapters[index];
          return ListTile(
            title: Text("Capítulo ${cap['numero_capitulo']}: ${cap['titulo']}"),
            trailing: const Icon(Icons.arrow_forward),
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
          );
        },
      ),
    );
  }
}
