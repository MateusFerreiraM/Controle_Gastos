import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_config.dart';

class TransacaoModel {
  final String? id;
  final double valor;
  final TipoTransacao tipo;
  final String categoria;
  final DateTime data;
  final String observacao;
  final MetodoPagamento metodo;
  final bool eParcelaFutura;
  final int parcelas;

  TransacaoModel({
    this.id,
    required this.valor,
    required this.tipo,
    required this.categoria,
    required this.data,
    required this.observacao,
    required this.metodo,
    this.eParcelaFutura = false,
    this.parcelas = 1,
  });

  factory TransacaoModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Tratamento de compatibilidade para antigos investimentos que eram "Saída"
    final tipoRaw = data['tipo'];
    final categoriaRaw = data['categoria'] ?? '';
    
    TipoTransacao tipo;
    if (tipoRaw == 'Investido' || (tipoRaw == 'Saida' && categoriaRaw == 'Investido')) {
      tipo = TipoTransacao.Investido;
    } else if (tipoRaw == 'Entrada') {
      tipo = TipoTransacao.Entrada;
    } else {
      tipo = TipoTransacao.Saida;
    }
    
    // Parser seguro de data garantindo meia-noite local
    DateTime dataParse;
    try {
      final dateString = data['data']?.toString() ?? '';
      if (dateString.length >= 10) {
        final parts = dateString.substring(0, 10).split('-');
        dataParse = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      } else {
        dataParse = DateTime.now();
      }
    } catch (e) {
      dataParse = DateTime.now();
    }

    return TransacaoModel(
      id: doc.id,
      valor: (data['valor'] as num).toDouble(),
      tipo: tipo,
      categoria: categoriaRaw,
      data: dataParse,
      observacao: data['observacao'] ?? '',
      metodo: MetodoPagamento.values.firstWhere(
        (e) => e.name == data['metodo'],
        orElse: () => MetodoPagamento.Dinheiro,
      ),
      eParcelaFutura: data['eParcelaFutura'] as bool? ?? false,
      parcelas: data['parcelas'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'categoria': categoria,
      'tipo': tipo.name,
      'data': DateFormat('yyyy-MM-dd').format(data),
      'observacao': observacao,
      'metodo': metodo.name,
      'eParcelaFutura': eParcelaFutura,
      'parcelas': parcelas,
    };
  }
}
