import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../main.dart';
import '../widgets/formulario_transacao.dart';
import 'tela_categorias.dart';

class PaginaInicial extends StatefulWidget {
  final String codigoGrupo;
  final VoidCallback onSair;
  const PaginaInicial({super.key, required this.codigoGrupo, required this.onSair});

  @override
  State<PaginaInicial> createState() => _PaginaInicialState();
}

class _PaginaInicialState extends State<PaginaInicial> {
  final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  CollectionReference get _transacoesRef => FirebaseFirestore.instance
      .collection('grupos')
      .doc(widget.codigoGrupo)
      .collection('transacoes');

  void _salvarTransacao(
      {String? id,
      required double valor,
      required TipoTransacao tipo,
      required String categoria,
      required DateTime data,
      required String observacao}) {
    
    final transacaoMap = {
      'valor': valor,
      'categoria': categoria,
      'tipo': tipo.name,
      'data': DateFormat('yyyy-MM-dd').format(data),
      'observacao': observacao,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      _transacoesRef.add(transacaoMap);
    } else {
      _transacoesRef.doc(id).update(transacaoMap);
    }
  }

  void _abrirModalDeTransacao(BuildContext ctx, [DocumentSnapshot? transacaoDoc]) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return FormularioTransacao(
          onSalvar: _salvarTransacao,
          transacaoParaEditar: transacaoDoc,
          codigoGrupo: widget.codigoGrupo,
        );
      },
    );
  }

  Widget _buildResumoCard(double valorAtual, double cofrinho) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Text('Valor Atual',
              style: TextStyle(fontSize: 20, color: AppColors.textoSecundario)),
          const SizedBox(height: 8.0),
          Text(
            formatadorMoeda.format(valorAtual),
            style: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 20.0),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(children: [
              const Text('Cofrinho',
                  style: TextStyle(color: AppColors.textoSecundario)),
              Text(formatadorMoeda.format(cofrinho),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
            ]),
            Column(children: [
              const Text('Investido',
                  style: TextStyle(color: AppColors.textoSecundario)),
              Text(formatadorMoeda.format(0.0),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
            ]),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gerenciar Categorias',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) =>
                      TelaGerenciarCategorias(codigoGrupo: widget.codigoGrupo),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair do Grupo',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('codigo_grupo');
              widget.onSair();
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _transacoesRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          double totalEntradas = 0, totalSaidas = 0, cofrinho = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['tipo'] == 'Entrada') {
              totalEntradas += data['valor'];
            } else {
              totalSaidas += data['valor'];
            }
            if (data['categoria'] == 'Cofrinho') cofrinho += data['valor'];
          }
          final valorAtual = totalEntradas - totalSaidas;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildResumoCard(valorAtual, cofrinho),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Center(
                  child: Text('Histórico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('Nenhuma transação encontrada.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90.0),
                        itemCount: docs.length,
                        itemBuilder: (ctx, index) {
                          final transacaoDoc = docs[index];
                          final transacaoData = transacaoDoc.data() as Map<String, dynamic>;
                          final tipo = transacaoData['tipo'] == 'Entrada'
                              ? TipoTransacao.Entrada
                              : TipoTransacao.Saida;
                          final data = DateTime.parse(transacaoData['data']);
                          final observacao = transacaoData['observacao'] ?? '';
                          final docId = transacaoDoc.id;
                          final cor = tipo == TipoTransacao.Entrada
                              ? AppColors.entrada
                              : AppColors.saida;

                          return Dismissible(
                            key: Key(docId),
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
                                backgroundColor: cor.withOpacity(0.15),
                                child: Icon(
                                  tipo == TipoTransacao.Entrada ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: cor,
                                ),
                              ),
                              title: Text(transacaoData['categoria'],
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (observacao.isNotEmpty) Text(observacao),
                                  Text(DateFormat('dd/MM/y', 'pt_BR').format(data)),
                                ],
                              ),
                              trailing: Text(
                                formatadorMoeda.format(transacaoData['valor']),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cor,
                                    fontSize: 18),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _abrirModalDeTransacao(context),
      ),
    );
  }
}