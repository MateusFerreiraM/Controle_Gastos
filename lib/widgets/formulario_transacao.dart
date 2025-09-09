import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../app_config.dart';
import '../app_colors.dart';

class FormularioTransacao extends StatefulWidget {
  final Function({ String? id, required double valor, required TipoTransacao tipo, required String categoria, required DateTime data, required String observacao, required MetodoPagamento metodo, required int parcelas }) onSalvar;
  final DocumentSnapshot? transacaoParaEditar;
  final String codigoGrupo;

  const FormularioTransacao({ required this.onSalvar, this.transacaoParaEditar, required this.codigoGrupo, super.key });

  @override
  State<FormularioTransacao> createState() => _FormularioTransacaoState();
}

class _FormularioTransacaoState extends State<FormularioTransacao> {
  final _valorController = TextEditingController();
  final _obsController = TextEditingController();
  final _parcelasController = TextEditingController(text: '1');
  TipoTransacao _tipoSelecionado = TipoTransacao.Saida;
  MetodoPagamento _metodoSelecionado = MetodoPagamento.Dinheiro;
  String? _categoriaSelecionada;
  DateTime _dataSelecionada = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  List<String> _categoriasEntrada = [];
  List<String> _categoriasSaida = [];
  bool _carregandoCategorias = true;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    if (widget.transacaoParaEditar != null) {
      final dados = widget.transacaoParaEditar!.data() as Map<String, dynamic>;
      _valorController.text = dados['valor'].toString();
      _obsController.text = dados['observacao'] ?? '';
      _tipoSelecionado = dados['tipo'] == 'Entrada' ? TipoTransacao.Entrada : TipoTransacao.Saida;
      _metodoSelecionado = MetodoPagamento.values.firstWhere((e) => e.name == dados['metodo'], orElse: () => MetodoPagamento.Dinheiro);
      _categoriaSelecionada = dados['categoria'];
      _dataSelecionada = DateTime.parse(dados['data']);
      _parcelasController.text = (dados['parcelas'] ?? 1).toString();
    }
  }

  Future<void> _carregarCategorias() async {
    final grupoDoc = await FirebaseFirestore.instance.collection('grupos').doc(widget.codigoGrupo).get();
    final dadosGrupo = grupoDoc.data();
    if (mounted && dadosGrupo != null) {
      setState(() {
        _categoriasEntrada = List<String>.from(dadosGrupo['categoriasEntrada'] ?? []);
        _categoriasSaida = List<String>.from(dadosGrupo['categoriasSaida'] ?? []);
        _carregandoCategorias = false;
      });
    } else if (mounted) {
      setState(() => _carregandoCategorias = false);
    }
  }

  void _submeterFormulario() {
    final valor = double.tryParse(_valorController.text) ?? 0.0;
    final observacao = _obsController.text;
    final parcelas = int.tryParse(_parcelasController.text) ?? 1;
    if (valor <= 0 || _categoriaSelecionada == null) return;
    final parcelasFinais = widget.transacaoParaEditar != null ? (widget.transacaoParaEditar!.data() as Map<String, dynamic>)['parcelas'] ?? 1 : parcelas;
    widget.onSalvar(id: widget.transacaoParaEditar?.id, valor: valor, tipo: _tipoSelecionado, categoria: _categoriaSelecionada!, data: _dataSelecionada, observacao: observacao, metodo: _metodoSelecionado, parcelas: parcelasFinais);
    Navigator.of(context).pop();
  }

  void _abrirSeletorDeData() {
    showDatePicker(context: context, initialDate: _dataSelecionada, firstDate: DateTime(2020), lastDate: DateTime(DateTime.now().year + 5)).then((dataEscolhida) {
      if (dataEscolhida == null) return;
      setState(() => _dataSelecionada = dataEscolhida);
    });
  }

  @override
  Widget build(BuildContext context) {
    var categoriasAtuais = _tipoSelecionado == TipoTransacao.Entrada ? _categoriasEntrada : _categoriasSaida;

    if (widget.transacaoParaEditar != null && 
        _categoriaSelecionada == 'Fatura' && 
        !categoriasAtuais.contains('Fatura')) {
      categoriasAtuais = List<String>.from(categoriasAtuais)..add('Fatura');
    }

    if (_carregandoCategorias) return const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator()));
    
    return Padding(
      padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.transacaoParaEditar == null ? 'Nova Transação' : 'Editar Transação', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<TipoTransacao>(
            segments: const <ButtonSegment<TipoTransacao>>[
              ButtonSegment<TipoTransacao>(value: TipoTransacao.Saida, label: Text('Saída'), icon: Icon(Icons.arrow_downward)),
              ButtonSegment<TipoTransacao>(value: TipoTransacao.Entrada, label: Text('Entrada'), icon: Icon(Icons.arrow_upward)),
            ],
            selected: {_tipoSelecionado},
            onSelectionChanged: (Set<TipoTransacao> newSelection) {
              setState(() {
                _tipoSelecionado = newSelection.first;
                _categoriaSelecionada = null;
                if (_tipoSelecionado == TipoTransacao.Entrada) _metodoSelecionado = MetodoPagamento.Dinheiro;
              });
            },
            style: SegmentedButton.styleFrom(
              foregroundColor: AppColors.textoSecundario,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: _tipoSelecionado == TipoTransacao.Entrada ? AppColors.entrada : AppColors.saida,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MetodoPagamento>(
            value: _metodoSelecionado,
            decoration: const InputDecoration(labelText: 'Método de Pagamento', border: OutlineInputBorder()),
            items: MetodoPagamento.values.where((metodo) {
              if (_tipoSelecionado == TipoTransacao.Entrada) return metodo != MetodoPagamento.Credito;
              return true;
            }).map((metodo) {
              String textoExibido = metodo.nomeFormatado;
              if (_tipoSelecionado == TipoTransacao.Entrada && metodo == MetodoPagamento.Debito) {
                textoExibido = 'Cartão';
              }
              return DropdownMenuItem(value: metodo, child: Text(textoExibido));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _metodoSelecionado = value);
            },
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text('Data: ${DateFormat('dd/MM/y', 'pt_BR').format(_dataSelecionada)}')),
            TextButton(onPressed: _abrirSeletorDeData, child: const Text('Alterar', style: TextStyle(fontWeight: FontWeight.bold)))
          ]),
          TextField(controller: _valorController, decoration: const InputDecoration(labelText: 'Valor (R\$)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 16),
          if (_metodoSelecionado == MetodoPagamento.Credito && widget.transacaoParaEditar == null && _tipoSelecionado == TipoTransacao.Saida) ...[
            TextField(
              controller: _parcelasController,
              decoration: const InputDecoration(labelText: 'Número de Parcelas', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<String>(
            value: _categoriaSelecionada,
            hint: const Text('Selecione uma Categoria'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: categoriasAtuais.map((String categoria) => DropdownMenuItem<String>(value: categoria, child: Text(categoria))).toList(),
            onChanged: (String? novoValor) { setState(() => _categoriaSelecionada = novoValor); },
          ),
          const SizedBox(height: 16),
          TextField(controller: _obsController, decoration: const InputDecoration(labelText: 'Observação (opcional)')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _submeterFormulario, child: const Text('Salvar Alterações')),
        ]),
      ),
    );
  }
}