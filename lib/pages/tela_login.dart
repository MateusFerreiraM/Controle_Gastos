import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';

class TelaDeLogin extends StatefulWidget {
  final Function(String) onConectar;
  const TelaDeLogin({super.key, required this.onConectar});

  @override
  State<TelaDeLogin> createState() => _TelaDeLoginState();
}

class _TelaDeLoginState extends State<TelaDeLogin> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _conectar() async {
    final codigo = _controller.text.trim();
    if (codigo.isEmpty) return;

    setState(() => _isLoading = true);

    final grupoRef = FirebaseFirestore.instance.collection('grupos').doc(codigo);
    final doc = await grupoRef.get();

    final dados = doc.data();
    if (!doc.exists || dados == null || !dados.containsKey('categoriasEntrada')) {
      List<String> categoriasEntradaPadrao = ['Salário', 'IC', 'Ajuda', 'Cofrinho', 'Outro'];
      List<String> categoriasSaidaPadrao = [
        'Aluguel', 'Mercado', 'Farmácia', 'Transporte', 'Compras', 'Gás',
        'Lazer', 'Investido', 'Cofrinho', 'Aposta', 'Tarifa', 'Conta', 'Outro'
      ];

      await grupoRef.set({
        'categoriasEntrada': versaoPessoal ? categoriasEntradaPadrao : ['Salário', 'Renda Extra', 'Presente'],
        'categoriasSaida': versaoPessoal ? categoriasSaidaPadrao : [
          'Moradia', 'Alimentação', 'Transporte', 'Saúde', 
          'Lazer', 'Contas', 'Outros'
        ],
      }, SetOptions(merge: true));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codigo_grupo', codigo);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) widget.onConectar(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.wallet_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text('Controle de Gastos', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Simples, compartilhado e sempre sincronizado.', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 40),
                const Text('Insira um código para criar um novo grupo ou conectar-se a um existente:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Código do Grupo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Dica: Crie um código único com letras e números para maior segurança.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _conectar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : const Text('Conectar ou Criar Grupo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}