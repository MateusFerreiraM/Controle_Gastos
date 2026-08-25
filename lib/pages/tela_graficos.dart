import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../app_colors.dart';

class TelaGraficos extends StatelessWidget {
  final String codigoGrupo;
  const TelaGraficos({super.key, required this.codigoGrupo});

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
            .doc(codigoGrupo)
            .collection('transacoes')
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Não há dados suficientes para gerar gráficos.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Adicione algumas transações para ver a análise.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final transacoes = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'valor': (data['valor'] as num).toDouble(),
              'categoria': data['categoria'] as String,
              'tipo': data['tipo'] as String,
              'data': data['data'] as String,
              'eParcelaFutura': data['eParcelaFutura'] ?? false,
              'metodo': data['metodo'] ?? 'Dinheiro',
              'observacao': data['observacao'] ?? '',
            };
          }).toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildResumoHorizontal(context, transacoes),
                const SizedBox(height: 24),
                _buildGastosEGanhos(context, transacoes),
                const SizedBox(height: 24),
                _buildEvolucaoMensalScrollavel(context, transacoes),
                const SizedBox(height: 24),
                _buildInsightsFinanceiros(context, transacoes),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumoHorizontal(BuildContext context, List<Map<String, dynamic>> transacoes) {
    final hoje = DateTime.now();
    double entradaMes = 0, saidaMes = 0, faturaPendente = 0;
    double totalEntradas = 0, totalSaidas = 0;
    
    for (var t in transacoes) {
      final data = DateTime.parse(t['data'] as String);
      final valor = t['valor'] as double;
      final tipo = t['tipo'] as String;
      final isParcelaFutura = t['eParcelaFutura'] == true;
      
      if (tipo == 'Entrada') {
        totalEntradas += valor;
        if (data.month == hoje.month && data.year == hoje.year && !isParcelaFutura) entradaMes += valor;
      } else {
        totalSaidas += valor;
        if (isParcelaFutura) {
          faturaPendente += valor;
        } else if (data.month == hoje.month && data.year == hoje.year) {
          saidaMes += valor;
        }
      }
    }
    
    final saldoMes = entradaMes - saidaMes;

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMiniCard('Saldo do Mês', saldoMes, saldoMes >= 0 ? Colors.green : Colors.red, Icons.calendar_today),
          _buildMiniCard('Faturas Futuras', faturaPendente, Colors.orange, Icons.credit_card),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String label, double valor, Color cor, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cor, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cor)),
        ],
      ),
    );
  }

  Widget _buildGastosEGanhos(BuildContext context, List<Map<String, dynamic>> transacoes) {
    return DefaultTabController(
      length: 2,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
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
                  _buildBarChartPorCategoria(transacoes, 'Saida', AppColors.saida),
                  _buildBarChartPorCategoria(transacoes, 'Entrada', AppColors.entrada),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartPorCategoria(List<Map<String, dynamic>> transacoes, String tipo, Color corPadrao) {
    final filtrados = transacoes.where((t) => t['tipo'] == tipo && t['eParcelaFutura'] == false).toList();
    if (filtrados.isEmpty) return const Center(child: Text('Sem dados nesta categoria.'));

    final Map<String, double> soma = {};
    for (var t in filtrados) {
      soma[t['categoria']] = (soma[t['categoria']] ?? 0) + (t['valor'] as double);
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

  Widget _buildEvolucaoMensalScrollavel(BuildContext context, List<Map<String, dynamic>> transacoes) {
    final transacoesHistorico = transacoes.where((t) => t['eParcelaFutura'] == false).toList();
    if (transacoesHistorico.isEmpty) return const SizedBox.shrink();

    transacoesHistorico.sort((a, b) => DateTime.parse(a['data'] as String).compareTo(DateTime.parse(b['data'] as String)));
    
    final Map<String, double> saldoPorMes = {};
    double saldoAcumulado = 0;
    for (var t in transacoesHistorico) {
      final chave = DateFormat('yyyy-MM').format(DateTime.parse(t['data'] as String));
      saldoAcumulado += (t['tipo'] == 'Entrada' ? 1 : -1) * (t['valor'] as double);
      saldoPorMes[chave] = saldoAcumulado;
    }

    if (saldoPorMes.isEmpty) return const SizedBox.shrink();

    final meses = saldoPorMes.keys.toList()..sort();
    final spots = List.generate(meses.length, (i) => FlSpot(i.toDouble(), saldoPorMes[meses[i]]!));
    
    final chartWidth = max(MediaQuery.of(context).size.width - 64, meses.length * 60.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppColors.primaria),
                const SizedBox(width: 8),
                Text('Evolução do Saldo', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaria)),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primaria,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true, 
                            color: AppColors.primaria.withOpacity(0.2),
                          ),
                        )
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 60,
                          getTitlesWidget: (v, m) => Text('R\$ ${v.toInt()}', style: const TextStyle(fontSize: 10)),
                        )),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, 
                          getTitlesWidget: (v, m) {
                            if (v.toInt() >= 0 && v.toInt() < meses.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(DateFormat('MM/yy').format(DateTime.parse('${meses[v.toInt()]}-01')), style: const TextStyle(fontSize: 10)),
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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.blueGrey,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final mes = meses[spot.x.toInt()];
                              final data = DateTime.parse('$mes-01');
                              final valor = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(spot.y);
                              return LineTooltipItem(
                                '${DateFormat('MMM/yy', 'pt_BR').format(data)}\n$valor',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    )
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsFinanceiros(BuildContext context, List<Map<String, dynamic>> transacoes) {
    final hoje = DateTime.now();
    
    double entradaMes = 0, saidaMes = 0;
    final Map<String, double> gastosPorCategoria = {};
    
    for (var t in transacoes) {
      if (t['eParcelaFutura'] == true) continue;
      final data = DateTime.parse(t['data'] as String);
      
      if (data.month == hoje.month && data.year == hoje.year) {
        final valor = t['valor'] as double;
        if (t['tipo'] == 'Entrada') {
          entradaMes += valor;
        } else {
          saidaMes += valor;
          gastosPorCategoria[t['categoria'] as String] = (gastosPorCategoria[t['categoria'] as String] ?? 0) + valor;
        }
      }
    }
    
    double taxaEconomia = entradaMes > 0 ? ((entradaMes - saidaMes) / entradaMes) * 100 : 0;
    if(taxaEconomia < 0) taxaEconomia = 0;
    
    final gastoDiario = saidaMes / max(1, hoje.day);
    
    String categoriaVilao = "Nenhuma";
    if (gastosPorCategoria.isNotEmpty) {
      var entry = gastosPorCategoria.entries.reduce((a, b) => a.value > b.value ? a : b);
      categoriaVilao = entry.key;
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Insights do Mês', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaria)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightItem(Icons.savings, 'Taxa de Poupança', '${taxaEconomia.toStringAsFixed(1)}% de economia neste mês.', Colors.green),
            const Divider(),
            _buildInsightItem(Icons.calendar_today, 'Gasto Médio Diário', '${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(gastoDiario)} por dia.', Colors.blue),
            const Divider(),
            _buildInsightItem(Icons.warning_amber_rounded, 'Maior Despesa', 'A categoria "$categoriaVilao" é onde você mais gastou.', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textoSecundario, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}