import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import 'tela_categorias.dart';
import 'tela_configuracao_seguranca.dart';

class TelaMenuConfiguracoes extends StatelessWidget {
  final String codigoGrupo;
  
  const TelaMenuConfiguracoes({
    super.key,
    required this.codigoGrupo,
  });

  Future<void> _limparTodasTransacoes(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Todas as Transações'),
        content: const Text(
          'Esta ação irá remover TODAS as transações do grupo. '
          'Esta ação não pode ser desfeita.\n\n'
          'Tem certeza que deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.saida,
            ),
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        // Busca todas as transações do grupo
        final transacoesRef = FirebaseFirestore.instance
            .collection('grupos')
            .doc(codigoGrupo)
            .collection('transacoes');

        final snapshot = await transacoesRef.get();
        
        // Remove todas as transações em lote
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todas as transações foram removidas!'),
              backgroundColor: AppColors.saida,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(); // Volta para a página inicial
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao limpar transações. Tente novamente.'),
              backgroundColor: AppColors.saida,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppColors.primaria,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gerenciar Categorias
          Card(
            child: ListTile(
              leading: Icon(
                Icons.category,
                color: AppColors.primaria,
                size: 28,
              ),
              title: const Text(
                'Gerenciar Categorias',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text('Adicionar, editar ou remover categorias'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaGerenciarCategorias(codigoGrupo: codigoGrupo),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Configurações de Segurança
          Card(
            child: ListTile(
              leading: Icon(
                Icons.security,
                color: AppColors.primaria,
                size: 28,
              ),
              title: const Text(
                'Configurações de Segurança',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text('Configurar PIN de proteção'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaConfiguracaoSeguranca(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Limpar Todas as Transações
          Card(
            child: ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: AppColors.saida,
                size: 28,
              ),
              title: Text(
                'Limpar Todas as Transações',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.saida,
                ),
              ),
              subtitle: const Text('Remove todas as transações do grupo'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _limparTodasTransacoes(context),
            ),
          ),

          const SizedBox(height: 32),

          // Informações adicionais
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaria.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaria),
                    const SizedBox(width: 12),
                    Text(
                      'Informações',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaria,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoItem('📊', 'Categorias são compartilhadas com todo o grupo'),
                _buildInfoItem('🔒', 'PIN é individual e fica apenas no seu dispositivo'),
                _buildInfoItem('⚠️', 'Limpeza de transações afeta todo o grupo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primaria,
              ),
            ),
          ),
        ],
      ),
    );
  }
}