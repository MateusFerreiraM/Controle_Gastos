import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../app_config.dart';

class ResumoCard extends StatelessWidget {
  final double saldoDinheiro;
  final double saldoCartao;
  final double faturaMes;
  final double cofrinho;
  final double investido;
  
  const ResumoCard({
    super.key,
    required this.saldoDinheiro,
    required this.saldoCartao,
    required this.faturaMes,
    required this.cofrinho,
    required this.investido,
  });

  @override
  Widget build(BuildContext context) {
    final valorTotal = saldoDinheiro + saldoCartao;
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Valor Total',
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              formatadorMoeda.format(valorTotal),
              style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoPrincipal),
            ),
            const SizedBox(height: 8),

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
            const SizedBox(height: 8),
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
        Icon(icon, color: cor, size: 16),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textoSecundario)),
        Text(
          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor),
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: cor),
        ),
      ],
    );
  }
}
