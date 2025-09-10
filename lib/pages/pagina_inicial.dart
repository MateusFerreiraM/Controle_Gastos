import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_config.dart';
import '../app_colors.dart';
import '../widgets/formulario_transacao.dart';
import 'tela_categorias.dart';
import 'tela_graficos.dart';

class PaginaInicial extends StatefulWidget {
  final String codigoGrupo;
  final VoidCallback onSair;
  const PaginaInicial({super.key, required this.codigoGrupo, required this.onSair});

  @override
  State<PaginaInicial> createState() => _PaginaInicialState();
}

class _PaginaInicialState extends State<PaginaInicial> {
  final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSeMostraTutorial();
    });
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
              Expanded(child: Text('Use o ícone de engrenagem ⚙️ para gerenciar suas categorias.')),
            ]),
          ]),
        ),
        actions: [TextButton(child: const Text('Entendi!'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  CollectionReference get _transacoesRef =>
      FirebaseFirestore.instance.collection('grupos').doc(widget.codigoGrupo).collection('transacoes');

  void _salvarTransacao(
      {String? id,
      required double valor,
      required TipoTransacao tipo,
      required String categoria,
      required DateTime data,
      required String observacao,
      required MetodoPagamento metodo,
      required int parcelas}) {
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
            
        _transacoesRef.add({
          'valor': valorParcela, 'categoria': categoria, 'tipo': tipo.name,
          'data': DateFormat('yyyy-MM-dd').format(dataParcela),
          'observacao': obsParcela, 'metodo': metodo.name, 'eParcelaFutura': true,
          'timestamp': Timestamp.fromDate(dataParcela), 'parcelas': numParcelas,
        });
      }
    } else {
      final transacaoMap = {
        'valor': valor, 'categoria': categoria, 'tipo': tipo.name,
        'data': DateFormat('yyyy-MM-dd').format(data),
        'observacao': observacao, 'metodo': metodo.name, 'eParcelaFutura': false,
        'parcelas': parcelas,
      };
      if (id == null) {
        transacaoMap['timestamp'] = FieldValue.serverTimestamp();
        _transacoesRef.add(transacaoMap);
      } else {
        _transacoesRef.doc(id).update(transacaoMap);
      }
    }
  }

  void _abrirModalDeTransacao(BuildContext ctx, [DocumentSnapshot? transacaoDoc]) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (_) {
        return FormularioTransacao(
            onSalvar: _salvarTransacao,
            transacaoParaEditar: transacaoDoc,
            codigoGrupo: widget.codigoGrupo);
      },
    );
  }

  Widget _buildResumoCard(double saldoDinheiro, double saldoCartao, double faturaMes, double cofrinho, double investido) {
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
                    valor: faturaMes,
                    cor: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (versaoPessoal)
                  _miniResumoItem(
                      icon: Icons.savings,
                      label: 'Cofrinho',
                      valor: cofrinho,
                      cor: Colors.blue),
                if (versaoPessoal)
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

  Widget _buildListaHistorico(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const Center(child: Text('Nenhuma transação no histórico.'));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90.0),
      itemCount: docs.length,
      itemBuilder: (ctx, index) {
        final transacaoDoc = docs[index];
        final transacaoData = transacaoDoc.data() as Map<String, dynamic>;
        final tipo =
            transacaoData['tipo'] == 'Entrada' ? TipoTransacao.Entrada : TipoTransacao.Saida;
        final data = DateTime.parse(transacaoData['data']);
        final observacao = transacaoData['observacao'] ?? '';
        final docId = transacaoDoc.id;
        final cor = tipo == TipoTransacao.Entrada ? AppColors.entrada : AppColors.saida;
        final metodo = MetodoPagamento.values.firstWhere((e) => e.name == transacaoData['metodo'],
            orElse: () => MetodoPagamento.Dinheiro);
        
        String metodoFormatado = metodo.nomeFormatado;
        if (tipo == TipoTransacao.Entrada && metodo == MetodoPagamento.Debito) {
          metodoFormatado = 'Cartão';
        }

        return Dismissible(
          key: Key(docId),
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
          onDismissed: (direction) {
            _transacoesRef.doc(docId).delete();
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
            onTap: () => _abrirModalDeTransacao(context, transacaoDoc),
            leading: CircleAvatar(
              backgroundColor: cor,
              child: Icon(
                  tipo == TipoTransacao.Entrada ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white),
            ),
            title: Text(transacaoData['categoria'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (observacao.isNotEmpty) Text(observacao),
                Text('${DateFormat('dd/MM/y', 'pt_BR').format(data)} • $metodoFormatado'),
              ],
            ),
            trailing: Text(
              formatadorMoeda.format(transacaoData['valor']),
              style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaFaturas(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return const Center(child: Text('Nenhuma fatura futura.'));

    final Map<String, List<QueryDocumentSnapshot>> faturasPorMes = {};
    for (var doc in docs) {
      final data = DateTime.parse((doc.data() as Map)['data']);
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
                      final transacaoDoc = faturasDoMes[index];
                      final transacaoData = transacaoDoc.data() as Map<String, dynamic>;
                      
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.credit_card)),
                        title: Text(transacaoData['categoria']),
                        subtitle: Text(transacaoData['observacao'] ?? ''),
                        trailing: Text(
                          formatadorMoeda.format(transacaoData['valor']),
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
                                  onPressed: (){
                                    _salvarTransacao(
                                      valor: transacaoData['valor'],
                                      tipo: TipoTransacao.Saida,
                                      categoria: 'Fatura',
                                      data: DateTime.now(),
                                      observacao: 'Pagamento: ${transacaoData['categoria']} (${transacaoData['observacao']})',
                                      metodo: MetodoPagamento.Debito,
                                      parcelas: 1,
                                    );
                                    _transacoesRef.doc(transacaoDoc.id).delete();
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
                  MaterialPageRoute(builder: (ctx) => TelaGraficos(codigoGrupo: widget.codigoGrupo))),
          ),
          IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Ajuda',
              onPressed: () => _mostrarDialogoDeBoasVindas(context)),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gerenciar Categorias',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (ctx) => TelaGerenciarCategorias(codigoGrupo: widget.codigoGrupo))),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair do Grupo',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('codigo_grupo');
              await prefs.remove('tutorial_visto');
              widget.onSair();
            },
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _transacoesRef.snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return _buildResumoCard(0, 0, 0, 0, 0);
                final docs = snapshot.data?.docs ?? [];
                
                double entradasDinheiro = 0, saidasDinheiro = 0;
                double entradasCartao = 0, saidasCartaoDebito = 0;
                double cofrinho = 0, investido = 0, faturaMesAtual = 0;
                
                final hoje = DateTime.now();

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final metodo = MetodoPagamento.values.firstWhere((e) => e.name == data['metodo'], orElse: () => MetodoPagamento.Dinheiro);
                  final valor = data['valor'] as num;
                  final categoria = data['categoria'] as String;
                  final tipo = data['tipo'] == 'Entrada' ? TipoTransacao.Entrada : TipoTransacao.Saida;
                  final isParcelaFutura = data['eParcelaFutura'] as bool? ?? false;
                  
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
                    final dataParcela = DateTime.parse(data['data']);
                    if (dataParcela.month == hoje.month && dataParcela.year == hoje.year) {
                      faturaMesAtual += valor;
                    }
                  }
                  
                  if (categoria == 'Cofrinho') cofrinho += valor;
                  if (categoria == 'Investido') investido += valor;
                }
                
                final saldoDinheiro = entradasDinheiro - saidasDinheiro;
                final saldoCartao = entradasCartao - saidasCartaoDebito;
                
                return _buildResumoCard(saldoDinheiro, saldoCartao, faturaMesAtual, cofrinho, investido);
              },
            ),
            const TabBar(tabs: [Tab(text: 'Histórico'), Tab(text: 'Faturas')]),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _transacoesRef.snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data?.docs ?? [];
                  List<QueryDocumentSnapshot> historicoDocs = docs.where((doc) => (doc.data() as Map)['eParcelaFutura'] == false).toList();
                  List<QueryDocumentSnapshot> faturaDocs = docs.where((doc) => (doc.data() as Map)['eParcelaFutura'] == true).toList();

                  historicoDocs.sort((a, b) {
                    final dataMapA = a.data() as Map<String, dynamic>;
                    final dataMapB = b.data() as Map<String, dynamic>;
                    final dateComparison = (dataMapB['data'] as String).compareTo(dataMapA['data'] as String);
                    if (dateComparison == 0) {
                      final timestampA = dataMapA['timestamp'] as Timestamp?;
                      final timestampB = dataMapB['timestamp'] as Timestamp?;
                      if (timestampB == null) return 1;
                      if (timestampA == null) return -1;
                      return timestampB.compareTo(timestampA);
                    }
                    return dateComparison;
                  });
                  faturaDocs.sort((a, b) => (a.data() as Map)['data'].compareTo((b.data() as Map)['data']));

                  return TabBarView(
                    children: [
                      _buildListaHistorico(historicoDocs),
                      _buildListaFaturas(faturaDocs),
                    ],
                  );
                },
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
}