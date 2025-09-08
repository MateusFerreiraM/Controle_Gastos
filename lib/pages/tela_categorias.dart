import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class TelaGerenciarCategorias extends StatefulWidget {
  final String codigoGrupo;
  const TelaGerenciarCategorias({super.key, required this.codigoGrupo});

  @override
  State<TelaGerenciarCategorias> createState() =>
      _TelaGerenciarCategoriasState();
}

class _TelaGerenciarCategoriasState extends State<TelaGerenciarCategorias> {
  late DocumentReference _grupoRef;
  List<String> _categoriasEntrada = [];
  List<String> _categoriasSaida = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _grupoRef = FirebaseFirestore.instance.collection('grupos').doc(widget.codigoGrupo);
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    final snapshot = await _grupoRef.get();
    if (snapshot.exists) {
      final dados = snapshot.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _categoriasEntrada = List<String>.from(dados['categoriasEntrada'] ?? []);
          _categoriasSaida = List<String>.from(dados['categoriasSaida'] ?? []);
          _carregando = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _adicionarCategoria(TipoTransacao tipo) async {
    final controller = TextEditingController();
    final novaCategoria = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da Categoria'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Adicionar'),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
          ),
        ],
      ),
    );

    if (novaCategoria != null) {
      final campo = tipo == TipoTransacao.Entrada ? 'categoriasEntrada' : 'categoriasSaida';
      await _grupoRef.update({
        campo: FieldValue.arrayUnion([novaCategoria])
      });
      _carregarCategorias();
    }
  }

  Future<void> _removerCategoria(TipoTransacao tipo, String categoria) async {
    final campo = tipo == TipoTransacao.Entrada ? 'categoriasEntrada' : 'categoriasSaida';
    await _grupoRef.update({
      campo: FieldValue.arrayRemove([categoria])
    });
    _carregarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Categorias'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Entradas', icon: Icon(Icons.arrow_upward)),
              Tab(text: 'Saídas', icon: Icon(Icons.arrow_downward)),
            ],
          ),
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  ListView.builder(
                    itemCount: _categoriasEntrada.length,
                    itemBuilder: (ctx, index) {
                      final categoria = _categoriasEntrada[index];
                      return ListTile(
                        title: Text(categoria),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removerCategoria(TipoTransacao.Entrada, categoria),
                        ),
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: _categoriasSaida.length,
                    itemBuilder: (ctx, index) {
                      final categoria = _categoriasSaida[index];
                      return ListTile(
                        title: Text(categoria),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removerCategoria(TipoTransacao.Saida, categoria),
                        ),
                      );
                    },
                  ),
                ],
              ),
        floatingActionButton: Builder(
          builder: (BuildContext newContext) {
            return FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                final index = DefaultTabController.of(newContext).index;
                final tipo = index == 0 ? TipoTransacao.Entrada : TipoTransacao.Saida;
                _adicionarCategoria(tipo);
              },
            );
          },
        ),
      ),
    );
  }
}