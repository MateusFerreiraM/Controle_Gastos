import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_config.dart';
import '../app_colors.dart';
import '../widgets/formulario_transacao.dart';
import '../services/database_service.dart';
import 'tela_categorias.dart';
import 'tela_graficos.dart';
import 'tela_configuracao_seguranca.dart';

class PaginaInicial extends StatefulWidget {
  const PaginaInicial({super.key});

  @override
  State<PaginaInicial> createState() => _PaginaInicialState();
}

class _PaginaInicialState extends State<PaginaInicial> {
  final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _transacoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSeMostraTutorial();
    });
  }

  Future<void> _carregarTransacoes() async {
    setState(() => _carregando = true);
    final transacoes = await DatabaseService.obterTransacoes();
    setState(() {
      _transacoes = transacoes;
      _carregando = false;
    });
  }

  List<Map<String, dynamic>> _getTransacoesHistoricoOrdenadas() {
    final historico = _transacoes.where((t) => t['eParcelaFutura'] == 0).toList();
    
    // Ordenar por data (mais recente primeiro) e depois por timestamp (mais recente primeiro)
    historico.sort((a, b) {
      final dataA = DateTime.parse(a['data']);
      final dataB = DateTime.parse(b['data']);
      
      // Primeiro compara as datas (mais recente primeiro)
      final dateComparison = dataB.compareTo(dataA);
      if (dateComparison != 0) {
        return dateComparison;
      }
      
      // Se as datas são iguais, compara os timestamps (mais recente primeiro)
      final timestampA = a['timestamp'] as int? ?? 0;
      final timestampB = b['timestamp'] as int? ?? 0;
      return timestampB.compareTo(timestampA);
    });
    
    return historico;
  }

  List<Map<String, dynamic>> _getTransacoesFaturasOrdenadas() {
    final faturas = _transacoes.where((t) => t['eParcelaFutura'] == 1).toList();
    
    // Para faturas, ordenar por data (mais próxima primeiro)
    faturas.sort((a, b) {
      final dataA = DateTime.parse(a['data']);
      final dataB = DateTime.parse(b['data']);
      return dataA.compareTo(dataB);
    });
    
    return faturas;
  }

  void _verificarSeMostraTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialVisto = prefs.getBool('tutorial_visto') ?? false;
    if (!tutorialVisto && mounted) {
      _mostrarDialogoDeBoasVindas(context);
    }
  }

  void _mostrarDialogoDeBoasVindas(BuildContext context) {
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) => p.setBool('tutorial_visto', true));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('👋 Bem-vindo!'),
        content: const SingleChildScrollView(
          child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aqui estão algumas dicas para começar:'),
            SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.swipe_left_outlined, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Deslize um item da lista para a esquerda para excluí-lo.')),
            ]),
            SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.touch_app_outlined, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Toque em um item da lista para editá-lo.')),
            ]),
            SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.credit_card_outlined, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Compras no crédito vão para a aba "Faturas" com vencimento no mês seguinte. Toque em uma parcela para pagá-la.')),
            ]),
            SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Use o ícone de engrenagem ⚙️ para acessar configurações: gerenciar categorias, configurar segurança e limpar dados.')),
            ]),
          ]),
        ),
        actions: [TextButton(child: const Text('Entendi!'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  void _mostrarDialogoLimparTransacoes() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Limpar Todas as Transações'),
        content: const Text(
          'Esta ação irá apagar TODAS as suas transações e faturas permanentemente.\n\nEsta ação não pode ser desfeita. Tem certeza?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, Limpar Tudo'),
            onPressed: () async {
              await DatabaseService.limparTodasTransacoes();
              await _carregarTransacoes();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas as transações foram removidas'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _salvarTransacao(
      {int? id,
      required double valor,
      required TipoTransacao tipo,
      required String categoria,
      required DateTime data,
      required String observacao,
      required MetodoPagamento metodo,
      required int parcelas}) async {
    
    if (metodo == MetodoPagamento.Credito && tipo == TipoTransacao.Saida && id == null) {
      final numParcelas = parcelas > 0 ? parcelas : 1;
      final valorParcela = valor / numParcelas;
      
      for (int i = 0; i < numParcelas; i++) {
        int year = data.year;
        int month = data.month + i + 1;
        if (month > 12) {
            year += (month - 1) ~/ 12;
            month = (month - 1) % 12 + 1;
        }
        final dataParcela = DateTime(year, month, data.day);

        final obsParcela = observacao.isEmpty
            ? 'Parcela ${i + 1}/$numParcelas'
            : '$observacao (Parcela ${i + 1}/$numParcelas)';
            
        await DatabaseService.inserirTransacao({
          'valor': valorParcela,
          'categoria': categoria,
          'tipo': tipo.name,
          'data': DateFormat('yyyy-MM-dd').format(dataParcela),
          'observacao': obsParcela,
          'metodo': metodo.name,
          'eParcelaFutura': 1,
          'parcelas': numParcelas,
          'timestamp': dataParcela.millisecondsSinceEpoch,
        });
      }
    } else {
      final transacaoMap = {
        'valor': valor,
        'categoria': categoria,
        'tipo': tipo.name,
        'data': DateFormat('yyyy-MM-dd').format(data),
        'observacao': observacao,
        'metodo': metodo.name,
        'eParcelaFutura': 0,
        'parcelas': parcelas,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (id == null) {
        await DatabaseService.inserirTransacao(transacaoMap);
      } else {
        await DatabaseService.atualizarTransacao(id, transacaoMap);
      }
    }
    
    await _carregarTransacoes();
  }

  void _abrirModalDeTransacao(BuildContext ctx, [Map<String, dynamic>? transacaoParaEditar]) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (_) {
        return FormularioTransacao(
            onSalvar: _salvarTransacao,
            transacaoParaEditar: transacaoParaEditar);
      },
    );
  }



Widget _miniResumoItem(
    {required IconData icon,
    required String label,
    required double valor,
    required Color cor}) {
  return Column(
    children: [
      Icon(icon, color: cor, size: 20),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textoSecundario)),
      Text(
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor),
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: cor),
      ),
    ],
  );
}

  Widget _buildListaHistorico(List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) return const Center(child: Text('Nenhuma transação no histórico.'));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90.0),
      itemCount: docs.length,
      itemBuilder: (ctx, index) {
        final transacao = docs[index];
        final tipo = transacao['tipo'] == 'Entrada' ? TipoTransacao.Entrada : TipoTransacao.Saida;
        final data = DateTime.parse(transacao['data']);
        final observacao = transacao['observacao'] ?? '';
        final id = transacao['id'];
        final cor = tipo == TipoTransacao.Entrada ? AppColors.entrada : AppColors.saida;
        final metodo = MetodoPagamento.values.firstWhere((e) => e.name == transacao['metodo'],
            orElse: () => MetodoPagamento.Dinheiro);
        
        String metodoFormatado = metodo.nomeFormatado;
        if (tipo == TipoTransacao.Entrada && metodo == MetodoPagamento.Debito) {
          metodoFormatado = 'Cartão';
        }

        return Dismissible(
          key: Key(id.toString()),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Confirmar Exclusão"),
                  content: const Text("Você tem certeza que deseja apagar esta transação?"),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.saida),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Apagar"),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) async {
            await DatabaseService.excluirTransacao(id);
            await _carregarTransacoes();
          },
          background: Container(
            color: AppColors.saida,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          child: ListTile(
            onTap: () => _abrirModalDeTransacao(context, transacao),
            leading: CircleAvatar(
              backgroundColor: cor,
              child: Icon(
                  tipo == TipoTransacao.Entrada ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white),
            ),
            title: Text(transacao['categoria'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (observacao.isNotEmpty) Text(observacao),
                Text('${DateFormat('dd/MM/y', 'pt_BR').format(data)} • $metodoFormatado'),
              ],
            ),
            trailing: Text(
              formatadorMoeda.format(transacao['valor']),
              style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaFaturas(List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) return const Center(child: Text('Nenhuma fatura futura.'));

    final Map<String, List<Map<String, dynamic>>> faturasPorMes = {};
    for (var doc in docs) {
      final data = DateTime.parse(doc['data']);
      final chaveMes = DateFormat('yyyy-MM').format(data);
      if (faturasPorMes[chaveMes] == null) {
        faturasPorMes[chaveMes] = [];
      }
      faturasPorMes[chaveMes]!.add(doc);
    }
    final meses = faturasPorMes.keys.toList()..sort();

    return PageView.builder(
      controller: PageController(viewportFraction: 0.9),
      itemCount: meses.length,
      itemBuilder: (ctx, pageIndex) {
        final mes = meses[pageIndex];
        final faturasDoMes = faturasPorMes[mes]!;
        final dataMes = DateTime.parse('$mes-01');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Card(
            elevation: 4,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  color: AppColors.primaria,
                  child: Text(
                    DateFormat('MMMM/yyyy', 'pt_BR').format(dataMes),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: faturasDoMes.length,
                    itemBuilder: (ctx, index) {
                      final transacao = faturasDoMes[index];
                      
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.credit_card)),
                        title: Text(transacao['categoria']),
                        subtitle: Text(transacao['observacao'] ?? ''),
                        trailing: Text(
                          formatadorMoeda.format(transacao['valor']),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saida, fontSize: 16),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Confirmar Pagamento'),
                              content: const Text(
                                  'Deseja marcar esta parcela como paga? Uma nova transação de saída será criada no seu histórico.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('Cancelar')),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _salvarTransacao(
                                      valor: transacao['valor'],
                                      tipo: TipoTransacao.Saida,
                                      categoria: 'Fatura',
                                      data: DateTime.now(),
                                      observacao: 'Pagamento: ${transacao['categoria']} (${transacao['observacao']})',
                                      metodo: MetodoPagamento.Debito,
                                      parcelas: 1,
                                    );
                                    await DatabaseService.excluirTransacao(transacao['id']);
                                    await _carregarTransacoes();
                                    Navigator.of(dCtx).pop();
                                  },
                                  child: const Text('Pagar'),
                                )
                              ],
                            )
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Ver Gráficos',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (ctx) => const TelaGraficos())),
          ),
          IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Ajuda',
              onPressed: () => _mostrarDialogoDeBoasVindas(context)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onSelected: (String result) {
              if (result == 'categorias') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (ctx) => const TelaGerenciarCategorias()));
              } else if (result == 'seguranca') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (ctx) => const TelaConfiguracaoSeguranca()));
              } else if (result == 'limpar') {
                _mostrarDialogoLimparTransacoes();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'categorias',
                child: ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Gerenciar Categorias'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'seguranca',
                child: ListTile(
                  leading: Icon(Icons.security, color: Colors.blue),
                  title: Text('Configurar Segurança'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'limpar',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep, color: Colors.red),
                  title: Text('Limpar Todas as Transações', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Card de resumo
            _buildResumoCard(),
            const TabBar(tabs: [Tab(text: 'Histórico'), Tab(text: 'Faturas')]),
            Expanded(
              child: _carregando 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildListaHistorico(_getTransacoesHistoricoOrdenadas()),
                      _buildListaFaturas(_getTransacoesFaturasOrdenadas()),
                    ],
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _abrirModalDeTransacao(context),
      ),
    );
  }

  Widget _buildResumoCard() {
    double entradasDinheiro = 0, saidasDinheiro = 0;
    double entradasCartao = 0, saidasCartaoDebito = 0;
    double cofrinho = 0, investido = 0, faturaMesAtual = 0;
    
    final hoje = DateTime.now();

    for (var transacao in _transacoes) {
      final metodo = MetodoPagamento.values.firstWhere((e) => e.name == transacao['metodo'], 
          orElse: () => MetodoPagamento.Dinheiro);
      final valor = transacao['valor'] as num;
      final categoria = transacao['categoria'] as String;
      final tipo = transacao['tipo'] == 'Entrada' ? TipoTransacao.Entrada : TipoTransacao.Saida;
      final isParcelaFutura = transacao['eParcelaFutura'] == 1;
      
      if (tipo == TipoTransacao.Entrada) {
        if (categoria != 'Cofrinho') {
          if (metodo == MetodoPagamento.Dinheiro) {
            entradasDinheiro += valor;
          } else {
            entradasCartao += valor;
          }
        }
      } else {
        if (metodo == MetodoPagamento.Dinheiro) {
          saidasDinheiro += valor;
        } else if (metodo == MetodoPagamento.Debito) saidasCartaoDebito += valor;
      }

      if (isParcelaFutura) {
        final dataParcela = DateTime.parse(transacao['data']);
        if (dataParcela.month == hoje.month && dataParcela.year == hoje.year) {
          faturaMesAtual += valor;
        }
      }
      
      if (categoria == 'Cofrinho') cofrinho += valor;
      if (categoria == 'Investido') investido += valor;
    }
    
    final saldoDinheiro = entradasDinheiro - saidasDinheiro;
    final saldoCartao = entradasCartao - saidasCartaoDebito;
    final valorTotal = saldoDinheiro + saldoCartao;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Valor Total',
                style: GoogleFonts.montserrat(
                    fontSize: 22,
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              formatadorMoeda.format(valorTotal),
              style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoPrincipal),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniResumoItem(
                    icon: Icons.attach_money,
                    label: 'Dinheiro',
                    valor: saldoDinheiro,
                    cor: Colors.green),
                _miniResumoItem(
                    icon: Icons.credit_card,
                    label: 'Cartão',
                    valor: saldoCartao,
                    cor: Colors.orange),
                _miniResumoItem(
                    icon: Icons.receipt_long,
                    label: 'Fatura (Mês)',
                    valor: faturaMesAtual,
                    cor: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            if (versaoPessoal)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _miniResumoItem(
                      icon: Icons.savings,
                      label: 'Cofrinho',
                      valor: cofrinho,
                      cor: Colors.blue),
                  _miniResumoItem(
                      icon: Icons.trending_up,
                      label: 'Investido',
                      valor: investido,
                      cor: Colors.purple),
                ],
              ),
          ],
        ),
      ),
    );
  }
}