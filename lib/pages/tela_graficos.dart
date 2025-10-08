import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../services/database_service.dart';

class TelaGraficos extends StatelessWidget {
  const TelaGraficos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Financeira'),
        backgroundColor: AppColors.primaria,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.obterTransacoes(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

          final transacoes = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildResumoFinanceiro(context, transacoes),
                const SizedBox(height: 24),
                _buildGraficoGastosPorCategoria(context, transacoes),
                const SizedBox(height: 24),
                _buildGraficoEvolucaoMensal(context, transacoes),
                const SizedBox(height: 24),
                _buildGraficoComparacaoEntradaSaida(context, transacoes),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumoFinanceiro(BuildContext context, List<Map<String, dynamic>> transacoes) {
    final hoje = DateTime.now();
    final inicioMes = DateTime(hoje.year, hoje.month, 1);
    final fimMes = DateTime(hoje.year, hoje.month + 1, 0);
    
    double entradaMes = 0, saidaMes = 0, faturaPendente = 0;
    double totalEntradas = 0, totalSaidas = 0;
    int totalTransacoes = transacoes.length;
    
    for (var transacao in transacoes) {
      final data = DateTime.parse(transacao['data']);
      final valor = (transacao['valor'] as num).toDouble();
      final tipo = transacao['tipo'] as String;
      final isParcelaFutura = transacao['eParcelaFutura'] == 1;
      
      if (tipo == 'Entrada') {
        totalEntradas += valor;
        if (data.isAfter(inicioMes.subtract(const Duration(days: 1))) && 
            data.isBefore(fimMes.add(const Duration(days: 1))) && !isParcelaFutura) {
          entradaMes += valor;
        }
      } else {
        totalSaidas += valor;
        if (isParcelaFutura) {
          faturaPendente += valor;
        } else if (data.isAfter(inicioMes.subtract(const Duration(days: 1))) && 
                   data.isBefore(fimMes.add(const Duration(days: 1)))) {
          saidaMes += valor;
        }
      }
    }
    
    final saldoMes = entradaMes - saidaMes;
    final saldoTotal = totalEntradas - totalSaidas;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: AppColors.primaria),
                const SizedBox(width: 8),
                Text(
                  'Resumo Financeiro',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaria,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResumoItem(
                    'Este Mês',
                    saldoMes,
                    saldoMes >= 0 ? Colors.green : Colors.red,
                    Icons.calendar_month,
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    'Saldo Total',
                    saldoTotal,
                    saldoTotal >= 0 ? Colors.green : Colors.red,
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildResumoItem(
                    'Faturas Pendentes',
                    faturaPendente,
                    Colors.orange,
                    Icons.credit_card,
                  ),
                ),
                Expanded(
                  child: _buildResumoItem(
                    'Total Transações',
                    totalTransacoes.toDouble(),
                    Colors.blue,
                    Icons.receipt_long,
                    isQuantidade: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(String label, double valor, Color cor, IconData icone, {bool isQuantidade = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isQuantidade 
                ? valor.toInt().toString()
                : NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoGastosPorCategoria(BuildContext context, List<Map<String, dynamic>> transacoes) {
    final saidas = transacoes.where((t) => t['tipo'] == 'Saida' && t['eParcelaFutura'] == 0).toList();
    
    if (saidas.isEmpty) return const SizedBox.shrink();

    final Map<String, double> gastosPorCategoria = {};
    for (var transacao in saidas) {
      final categoria = transacao['categoria'] as String;
      final valor = (transacao['valor'] as num).toDouble();
      gastosPorCategoria[categoria] = (gastosPorCategoria[categoria] ?? 0) + valor;
    }

    final categoriasOrdenadas = gastosPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Mostrar apenas as top 6 categorias para melhor visualização horizontal
    final topCategorias = categoriasOrdenadas.take(6).toList();

    final cores = [
      AppColors.saida,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.teal,
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: AppColors.primaria),
                const SizedBox(width: 8),
                Text(
                  'Gastos por Categoria',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaria,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Gráfico horizontal com barras deitadas
            ...topCategorias.asMap().entries.map((entry) {
              final index = entry.key;
              final categoria = entry.value;
              final valor = categoria.value;
              final maxValor = topCategorias.first.value;
              final largura = (valor / maxValor) * 1.0; // Porcentagem da largura máxima
              final cor = cores[index % cores.length];
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoria.key,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor),
                          style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: largura,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoEvolucaoMensal(BuildContext context, List<Map<String, dynamic>> transacoes) {
    final transacoesHistorico = transacoes.where((t) => t['eParcelaFutura'] == 0).toList();
    
    if (transacoesHistorico.isEmpty) return const SizedBox.shrink();

    transacoesHistorico.sort((a, b) => DateTime.parse(a['data']).compareTo(DateTime.parse(b['data'])));

    final Map<String, double> saldoPorMes = {};
    double saldoAcumulado = 0;

    for (var transacao in transacoesHistorico) {
      final data = DateTime.parse(transacao['data']);
      final chaveMes = DateFormat('yyyy-MM').format(data);
      final valor = (transacao['valor'] as num).toDouble();
      final tipo = transacao['tipo'] as String;

      if (tipo == 'Entrada') {
        saldoAcumulado += valor;
      } else {
        saldoAcumulado -= valor;
      }

      saldoPorMes[chaveMes] = saldoAcumulado;
    }

    if (saldoPorMes.isEmpty) return const SizedBox.shrink();

    final List<FlSpot> spots = [];
    final meses = saldoPorMes.keys.toList()..sort();

    for (int i = 0; i < meses.length; i++) {
      spots.add(FlSpot(i.toDouble(), saldoPorMes[meses[i]]!));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.primaria),
                const SizedBox(width: 8),
                Text(
                  'Evolução do Saldo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaria,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primaria, AppColors.entrada],
                      ),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primaria,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaria.withOpacity(0.3),
                            AppColors.primaria.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'R\$ ${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < meses.length) {
                            final mes = meses[value.toInt()];
                            final data = DateTime.parse('$mes-01');
                            return Text(
                              DateFormat('MM/yy').format(data),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoComparacaoEntradaSaida(BuildContext context, List<Map<String, dynamic>> transacoes) {
    final transacoesHistorico = transacoes.where((t) => t['eParcelaFutura'] == 0).toList();
    
    if (transacoesHistorico.isEmpty) return const SizedBox.shrink();

    final Map<String, Map<String, double>> dadosPorMes = {};

    for (var transacao in transacoesHistorico) {
      final data = DateTime.parse(transacao['data']);
      final chaveMes = DateFormat('yyyy-MM').format(data);
      final valor = (transacao['valor'] as num).toDouble();
      final tipo = transacao['tipo'] as String;

      if (dadosPorMes[chaveMes] == null) {
        dadosPorMes[chaveMes] = {'Entrada': 0, 'Saida': 0};
      }

      dadosPorMes[chaveMes]![tipo] = (dadosPorMes[chaveMes]![tipo] ?? 0) + valor;
    }

    final meses = dadosPorMes.keys.toList()..sort();
    // Mostrar apenas os últimos 6 meses
    final mesesRecentes = meses.length > 6 ? meses.sublist(meses.length - 6) : meses;

    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < mesesRecentes.length; i++) {
      final mes = mesesRecentes[i];
      final entradas = dadosPorMes[mes]!['Entrada']!;
      final saidas = dadosPorMes[mes]!['Saida']!;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entradas,
              color: AppColors.entrada,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: saidas,
              color: AppColors.saida,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
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
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: AppColors.primaria),
                const SizedBox(width: 8),
                Text(
                  'Entradas vs Saídas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaria,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: AppColors.entrada,
                ),
                const SizedBox(width: 4),
                const Text('Entradas', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  color: AppColors.saida,
                ),
                const SizedBox(width: 4),
                const Text('Saídas', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  groupsSpace: 12,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'R\$ ${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < mesesRecentes.length) {
                            final mes = mesesRecentes[value.toInt()];
                            final data = DateTime.parse('$mes-01');
                            return Text(
                              DateFormat('MM/yy').format(data),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
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