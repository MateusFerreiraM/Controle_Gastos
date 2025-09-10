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
        title: const Text('Análise Gráfica'),
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
              child: Text('Não há dados suficientes para gerar gráficos.'),
            );
          }

          final docs = snapshot.data!.docs;
          final saidas = docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['tipo'] == 'Saida')
              .toList();

          final transacoesHistorico = docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['eParcelaFutura'] == false)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGraficoPizza(context, saidas),
                const SizedBox(height: 24),
                _buildGraficoLinha(context, transacoesHistorico),
                const SizedBox(height: 24),
                _buildGraficoBarras(context, saidas),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGraficoPizza(
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
