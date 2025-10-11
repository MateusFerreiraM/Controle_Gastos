import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
      final valor = transacao['valor'] as double;
      final tipo = transacao['tipo'] as String;
      final isParcelaFutura = transacao['eParcelaFutura'] == true;
      
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
      BuildContext context, List<QueryDocumentSnapshot> saidas) {
    if (saidas.isEmpty) return const SizedBox.shrink();

    final Map<String, double> gastosPorCategoria = {};
    double totalSaidas = 0;

    for (var doc in saidas) {
      final data = doc.data() as Map<String, dynamic>;
      final categoria = data['categoria'] as String;
      final valor = (data['valor'] as num).toDouble();
      gastosPorCategoria[categoria] =
          (gastosPorCategoria[categoria] ?? 0) + valor;
      totalSaidas += valor;
    }

    final List<Color> cores = [
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[300]!,
      Colors.amber[600]!,
    ];

    int corIndex = 0;
    final sections = gastosPorCategoria.entries.map((entry) {
      final cor = cores[corIndex++ % cores.length];
      final porcentagem = (entry.value / totalSaidas) * 100;

      return PieChartSectionData(
        color: cor,
        value: entry.value,
        radius: 100,
        title: entry.key,
        titlePositionPercentageOffset: 0.6,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        badgeWidget: Text(
          '${porcentagem.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cor.withBlue(50).withGreen(50),
            shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Para onde seu dinheiro está indo?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoLinha(
      BuildContext context, List<QueryDocumentSnapshot> transacoes) {
    if (transacoes.length < 2) return const SizedBox.shrink();

    transacoes.sort((a, b) => DateTime.parse((a.data() as Map)['data'])
        .compareTo(DateTime.parse((b.data() as Map)['data'])));

    double saldoAcumulado = 0;
    final Map<String, double> saldoPorMes = {};

    for (var doc in transacoes) {
      final data = doc.data() as Map<String, dynamic>;
      final valor = (data['valor'] as num).toDouble();
      final tipo = data['tipo'] as String;
      final dataTransacao = DateTime.parse(data['data']);

      final chaveMes = DateFormat('yyyy-MM').format(dataTransacao);

      saldoAcumulado += (tipo == 'Entrada' ? valor : -valor);
      saldoPorMes[chaveMes] = saldoAcumulado;
    }

    final mesesOrdenados = saldoPorMes.keys.toList()..sort();

    final List<FlSpot> spots = [];
    for (var mes in mesesOrdenados) {
      final data = DateFormat('yyyy-MM').parse(mes);
      spots.add(FlSpot(
          data.millisecondsSinceEpoch.toDouble(), saldoPorMes[mes]!));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Evolução do Saldo Total (Mensal)',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          final formatador = NumberFormat.compactCurrency(
                            locale: 'pt_BR',
                            symbol: 'R\$',
                          );
                          return Text(formatador.format(value),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval:
                            const Duration(days: 30).inMilliseconds.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final date =
                              DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/yy').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primaria,
                      barWidth: 4,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primaria.withOpacity(0.3)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoBarras(
      BuildContext context, List<QueryDocumentSnapshot> saidas) {
    if (saidas.isEmpty) return const SizedBox.shrink();

    final Map<String, double> gastosPorMes = {};
    for (var doc in saidas) {
      final data = doc.data() as Map<String, dynamic>;
      final dataTransacao = DateTime.parse(data['data']);
      final chaveMes = DateFormat('yyyy-MM').format(dataTransacao);
      final valor = (data['valor'] as num).toDouble();
      gastosPorMes[chaveMes] = (gastosPorMes[chaveMes] ?? 0) + valor;
    }

    final mesesOrdenados = gastosPorMes.keys.toList()..sort();

    final dadosGrafico = mesesOrdenados.asMap().entries.map((entry) {
      final index = entry.key;
      final mes = entry.value;
      final valor = gastosPorMes[mes]!;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: valor,
            width: 28,
            color: AppColors.saida,
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: gastosPorMes.values.reduce((a, b) => a > b ? a : b),
              color: Colors.grey.shade200,
            ),
          ),
        ],
      );
    }).toList();

    if (dadosGrafico.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Comparativo de Despesas Mensais',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: dadosGrafico,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < mesesOrdenados.length) {
                            final mesAno = mesesOrdenados[index];
                            final data = DateFormat('yyyy-MM').parse(mesAno);
                            return Text(DateFormat('MMM/yy').format(data));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: gastosPorMes.values.reduce((a, b) => a > b ? a : b) / 5,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          final formatador = NumberFormat.compactCurrency(
                            locale: 'pt_BR',
                            symbol: 'R\$',
                          );
                          return Text(formatador.format(value),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: mesesOrdenados.asMap().entries.map((entry) {
                final mes = entry.value;
                final valor = gastosPorMes[mes]!;
                return Text(
                  "R\$ ${valor.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
