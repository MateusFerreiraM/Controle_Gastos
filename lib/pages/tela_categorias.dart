import 'package:controle_gastos/app_config.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TelaGerenciarCategorias extends StatefulWidget {
  const TelaGerenciarCategorias({super.key});

  @override
  State<TelaGerenciarCategorias> createState() =>
      _TelaGerenciarCategoriasState();
}

class _TelaGerenciarCategoriasState extends State<TelaGerenciarCategorias> {
  List<Map<String, dynamic>> _categoriasEntrada = [];
  List<Map<String, dynamic>> _categoriasSaida = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    setState(() => _carregando = true);
    final categoriasEntrada = await DatabaseService.obterCategorias('Entrada');
    final categoriasSaida = await DatabaseService.obterCategorias('Saida');
    
    if (mounted) {
      setState(() {
        _categoriasEntrada = categoriasEntrada;
        _categoriasSaida = categoriasSaida;
        _carregando = false;
      });
    }
  }

  Future<void> _mostrarDialogoAdicionarCategoria(String tipo) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adicionar Categoria de $tipo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome da categoria'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = controller.text.trim();
              if (nome.isNotEmpty) {
                await DatabaseService.inserirCategoria(nome, tipo);
                await _carregarCategorias();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _removerCategoria(Map<String, dynamic> categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir a categoria "${categoria['nome']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseService.excluirCategoria(categoria['id']);
      await _carregarCategorias();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoria "${categoria['nome']}" removida')),
        );
      }
    }
  }

  Future<void> _editarCategoria(Map<String, dynamic> categoria) async {
    final controller = TextEditingController(text: categoria['nome']);
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Categoria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome da categoria'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novoNome = controller.text.trim();
              if (novoNome.isNotEmpty && novoNome != categoria['nome']) {
                await DatabaseService.atualizarCategoriaEmTransacoes(
                  categoria['nome'], novoNome);
                await DatabaseService.atualizarCategoria(categoria['id'], novoNome);
                await _carregarCategorias();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCategorias(List<Map<String, dynamic>> categorias, String tipo) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categorias.length,
      itemBuilder: (ctx, index) {
        final categoria = categorias[index];
        return ListTile(
          title: Text(categoria['nome']),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editarCategoria(categoria),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removerCategoria(categoria),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Categorias'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção Categorias de Entrada
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categorias de Entrada',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _mostrarDialogoAdicionarCategoria('Entrada'),
                      ),
                    ],
                  ),
                  Card(
                    child: _buildListaCategorias(_categoriasEntrada, 'Entrada'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Seção Categorias de Saída
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categorias de Saída',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _mostrarDialogoAdicionarCategoria('Saida'),
                      ),
                    ],
                  ),
                  Card(
                    child: _buildListaCategorias(_categoriasSaida, 'Saida'),
                  ),
                  
                  if (versaoPessoal) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categorias Especiais',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text('• Cofrinho: Para guardar dinheiro'),
                            const Text('• Investido: Para aplicações e investimentos'),
                            const SizedBox(height: 8),
                            const Text(
                              'Essas categorias são contabilizadas separadamente no resumo.',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}