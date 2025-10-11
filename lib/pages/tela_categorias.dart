import 'package:controle_gastos/app_config.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _editarCategoria(TipoTransacao tipo, String categoriaAntiga) async {
    final TextEditingController controller = TextEditingController(text: categoriaAntiga);
    
    final novoNome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Categoria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da categoria',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () {
              final texto = controller.text.trim();
              if (texto.isNotEmpty && texto != categoriaAntiga) {
                Navigator.of(ctx).pop(texto);
              } else {
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );

    if (novoNome != null) {
      final campo = tipo == TipoTransacao.Entrada ? 'categoriasEntrada' : 'categoriasSaida';
      final List<String> categorias = tipo == TipoTransacao.Entrada ? _categoriasEntrada : _categoriasSaida;
      
      if (categorias.contains(novoNome)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta categoria já existe!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Remove a categoria antiga e adiciona a nova
      await _grupoRef.update({
        campo: FieldValue.arrayRemove([categoriaAntiga])
      });
      await _grupoRef.update({
        campo: FieldValue.arrayUnion([novoNome])
      });
      
      _carregarCategorias();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoria editada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removerCategoria(TipoTransacao tipo, String categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Tem certeza que deseja excluir a categoria "$categoria"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final campo = tipo == TipoTransacao.Entrada ? 'categoriasEntrada' : 'categoriasSaida';
      await _grupoRef.update({
        campo: FieldValue.arrayRemove([categoria])
      });
      _carregarCategorias();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoria removida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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
            : Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          itemCount: _categoriasEntrada.length,
                          itemBuilder: (ctx, index) {
                            final categoria = _categoriasEntrada[index];
                            return ListTile(
                              title: Text(categoria),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _editarCategoria(TipoTransacao.Entrada, categoria),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removerCategoria(TipoTransacao.Entrada, categoria),
                                  ),
                                ],
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _editarCategoria(TipoTransacao.Saida, categoria),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removerCategoria(TipoTransacao.Saida, categoria),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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