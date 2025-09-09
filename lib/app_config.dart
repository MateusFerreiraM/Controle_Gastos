const bool versaoPessoal = false;

enum TipoTransacao { Entrada, Saida }

enum MetodoPagamento { Dinheiro, Debito, Credito }

extension MetodoPagamentoExtension on MetodoPagamento {
  String get nomeFormatado {
    switch (this) {
      case MetodoPagamento.Debito:
        return 'Débito';
      case MetodoPagamento.Credito:
        return 'Crédito';
      default:
        return name;
    }
  }
}