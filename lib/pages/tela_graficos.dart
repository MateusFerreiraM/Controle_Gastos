import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/transacao_model.dart';
import '../app_config.dart';
import '../app_colors.dart';

class TelaGraficos extends StatefulWidget {
  final String codigoGrupo;
  const TelaGraficos({super.key, required this.codigoGrupo});

  @override
  State<TelaGraficos> createState() => _TelaGraficosState();
}

class _TelaGraficosState extends State<TelaGraficos> {
  DateTime _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final NumberFormat formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  void _mudarMes(int delta) {
    setState(() {
      _mesSelecionado = DateTime(_mesSelecionado.year, _mesSelecionado.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Financeira'),
        backgroundColor: AppColors.primaria,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('grupos')
            .doc(widget.codigoGrupo)
            .collection('transacoes')
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final todasTransacoes = snapshot.data!.docs.map((doc) => TransacaoModel.fromDocument(doc)).toList();
          
          final transacoesMes = todasTransacoes.where((t) => 
            t.data.year == _mesSelecionado.year && 
            t.data.month == _mesSelecionado.month &&
            !t.eParcelaFutura
          ).toList();

          return Column(
            children: [
              _buildSeletorMes(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildKardex(transacoesMes),
                      const SizedBox(height: 24),
                      _buildGastosEGanhos('Análise do Mês', transacoesMes),
                      const SizedBox(height: 24),
                      _buildFluxoDeCaixa6Meses(todasTransacoes),
                      const SizedBox(height: 24),
                      _buildGastosEGanhos('Histórico Geral', todasTransacoes),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Não há dados suficientes.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSeletorMes() {
    final mesFormatado = DateFormat('MMMM yyyy', 'pt_BR').format(_mesSelecionado);
    final isMesAtual = _mesSelecionado.year == DateTime.now().year && _mesSelecionado.month == DateTime.now().month;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 32),
            onPressed: () => _mudarMes(-1),
            color: AppColors.primaria,
          ),
          Text(
            mesFormatado[0].toUpperCase() + mesFormatado.substring(1),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaria),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 32),
            onPressed: isMesAtual ? null : () => _mudarMes(1),
            color: isMesAtual ? Colors.grey : AppColors.primaria,
          ),
        ],
      ),
    );
  }

  Widget _buildKardex(List<TransacaoModel> transacoesMes) {
    double receitas = 0;
    double despesas = 0;
    double investimentos = 0;

    for (var t in transacoesMes) {
      if (t.tipo == TipoTransacao.Entrada) {
        receitas += t.valor;
      } else if (t.tipo == TipoTransacao.Saida) {
        despesas += t.valor;
      } else if (t.tipo == TipoTransacao.Investido) {
        investimentos += t.valor;
      }
    }

    final balanco = receitas - despesas;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildResumoCard('Receitas', receitas, AppColors.entrada, Icons.arrow_upward)),
            const SizedBox(width: 12),
            Expanded(child: _buildResumoCard('Despesas', despesas, AppColors.saida, Icons.arrow_downward)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildResumoCard('Investimentos', investimentos, Colors.purple, Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _buildResumoCard('Balanço', balanco, balanco >= 0 ? AppColors.entrada : AppColors.saida, Icons.account_balance_wallet)),
          ],
        ),
      ],
    );
  }

  Widget _buildResumoCard(String titulo, double valor, Color cor, IconData icone) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 16, color: cor),
                const SizedBox(width: 4),
                Text(titulo, style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatadorMoeda.format(valor),
              style: TextStyle(color: cor, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGastosEGanhos(String titulo, List<TransacaoModel> transacoes) {
    return DefaultTabController(
      length: 2,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaria)),
            ),
            const TabBar(
              labelColor: AppColors.primaria,
              indicatorColor: AppColors.primaria,
              tabs: [
                Tab(text: 'Onde Gastei'),
                Tab(text: 'De Onde Veio'),
              ],
            ),
            SizedBox(
              height: 350,
              child: TabBarView(
                children: [
                  _buildBarChartPorCategoria(transacoes, TipoTransacao.Saida, AppColors.saida),
                  _buildBarChartPorCategoria(transacoes, TipoTransacao.Entrada, AppColors.entrada),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartPorCategoria(List<TransacaoModel> transacoes, TipoTransacao tipo, Color corPadrao) {
    final filtrados = transacoes.where((t) => t.tipo == tipo && t.eParcelaFutura == false).toList();
    if (filtrados.isEmpty) return const Center(child: Text('Sem dados nesta categoria.'));

    final Map<String, double> soma = {};
    for (var t in filtrados) {
      soma[t.categoria] = (soma[t.categoria] ?? 0) + t.valor;
    }

    final ordenados = soma.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top10 = ordenados.take(10).toList();
    if (top10.isEmpty) return const SizedBox.shrink();
    
    final maxValor = top10.first.value;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: top10.length,
      itemBuilder: (ctx, index) {
        final cat = top10[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cat.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(cat.value), 
                       style: TextStyle(fontSize: 12, color: corPadrao, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (cat.value / maxValor).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(color: corPadrao, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFluxoDeCaixa6Meses(List<TransacaoModel> todasTransacoes) {
    // Generate the last 6 months ending in _mesSelecionado
    final List<DateTime> meses = [];
    for (int i = 5; i >= 0; i--) {
      meses.add(DateTime(_mesSelecionado.year, _mesSelecionado.month - i, 1));
    }

    final Map<String, double> entradas = {};
    final Map<String, double> saidas = {};

    for (var m in meses) {
      final key = DateFormat('MM/yy').format(m);
      entradas[key] = 0;
      saidas[key] = 0;
    }

    for (var t in todasTransacoes) {
      if (t.eParcelaFutura) continue;
      
      final mKey = DateFormat('MM/yy').format(DateTime(t.data.year, t.data.month, 1));
      if (entradas.containsKey(mKey)) {
        if (t.tipo == TipoTransacao.Entrada) {
          entradas[mKey] = entradas[mKey]! + t.valor;
        } else if (t.tipo == TipoTransacao.Saida || t.tipo == TipoTransacao.Investido) {
          saidas[mKey] = saidas[mKey]! + t.valor;
        }
      }
    }

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < meses.length; i++) {
      final key = DateFormat('MM/yy').format(meses[i]);
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: entradas[key]!, color: AppColors.entrada, width: 12, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: saidas[key]!, color: AppColors.saida, width: 12, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fluxo de Caixa (6 Meses)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaria)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 12, height: 12, color: AppColors.entrada),
                const SizedBox(width: 4),
                const Text('Entradas', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: AppColors.saida),
                const SizedBox(width: 4),
                const Text('Saídas/Investido', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 50,
                      getTitlesWidget: (v, m) => Text(v == 0 ? '0' : '${(v/1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 10)),
                    )),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        if (v.toInt() >= 0 && v.toInt() < meses.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('MM/yy').format(meses[v.toInt()]), style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox();
                      }
                    )),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}