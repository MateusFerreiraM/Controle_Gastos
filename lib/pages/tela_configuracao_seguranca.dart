import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';
import 'tela_pin_teclado.dart';

class TelaConfiguracaoSeguranca extends StatefulWidget {
  const TelaConfiguracaoSeguranca({super.key});

  @override
  State<TelaConfiguracaoSeguranca> createState() => _TelaConfiguracaoSegurancaState();
}

class _TelaConfiguracaoSegurancaState extends State<TelaConfiguracaoSeguranca> {
  bool _pinEnabled = false;
  bool _pinConfigured = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarEstadoPin();
  }

  Future<void> _carregarEstadoPin() async {
    try {
      final enabled = await AuthService.isPinEnabled();
      final configured = await AuthService.isPinConfigured();
      
      if (mounted) {
        setState(() {
          _pinEnabled = enabled;
          _pinConfigured = configured;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _alternarPin(bool novoValor) async {
    if (novoValor && !_pinConfigured) {
      // Precisa configurar o PIN primeiro
      _navegarParaConfigurarPin();
    } else if (novoValor && _pinConfigured) {
      // PIN já configurado, apenas ativar
      await AuthService.setPinEnabled(true);
      setState(() {
        _pinEnabled = true;
      });
      _mostrarMensagem('PIN ativado com sucesso!', isSuccess: true);
    } else {
      // Desativar PIN
      await _confirmarDesativarPin();
    }
  }

  Future<void> _confirmarDesativarPin() async {
    final shouldDisable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar PIN'),
        content: const Text(
          'Tem certeza que deseja desativar o PIN? '
          'Seu app ficará menos seguro.',
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
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (shouldDisable == true) {
      await AuthService.setPinEnabled(false);
      setState(() {
        _pinEnabled = false;
      });
      _mostrarMensagem('PIN desativado.', isSuccess: false);
    }
  }

  void _navegarParaConfigurarPin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TelaPinTeclado(
          isConfiguring: true,
          title: 'Configure seu PIN',
          onPinVerified: () {
            Navigator.of(context).pop();
            _carregarEstadoPin(); // Recarrega o estado
            _mostrarMensagem('PIN configurado e ativado!', isSuccess: true);
          },
        ),
      ),
    );
  }

  void _navegarParaAlterarPin() {
    if (!_pinConfigured) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TelaPinTeclado(
          isConfiguring: true,
          title: 'Novo PIN',
          onPinVerified: () {
            Navigator.of(context).pop();
            _mostrarMensagem('PIN alterado com sucesso!', isSuccess: true);
          },
        ),
      ),
    );
  }

  Future<void> _removerPin() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover PIN'),
        content: const Text(
          'Esta ação irá remover completamente o PIN do aplicativo. '
          'Você precisará configurar um novo PIN se quiser usar novamente.\n\n'
          'Deseja continuar?',
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
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      await AuthService.resetPinSetup();
      setState(() {
        _pinEnabled = false;
        _pinConfigured = false;
      });
      _mostrarMensagem('PIN removido completamente.', isSuccess: false);
    }
  }

  void _mostrarMensagem(String mensagem, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isSuccess ? AppColors.entrada : AppColors.saida,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Segurança'),
        backgroundColor: AppColors.primaria,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Seção PIN
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: AppColors.primaria),
                            const SizedBox(width: 12),
                            Text(
                              'Proteção por PIN',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Proteja seu aplicativo com um PIN de 4 dígitos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Toggle PIN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ativar PIN'),
                            Switch(
                              value: _pinEnabled,
                              onChanged: _alternarPin,
                              activeColor: AppColors.primaria,
                            ),
                          ],
                        ),
                        
                        if (_pinConfigured) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // Alterar PIN
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit, color: AppColors.primaria),
                            title: const Text('Alterar PIN'),
                            subtitle: const Text('Defina um novo PIN'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _navegarParaAlterarPin,
                          ),
                          
                          // Remover PIN
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_forever, color: AppColors.saida),
                            title: Text(
                              'Remover PIN',
                              style: TextStyle(color: AppColors.saida),
                            ),
                            subtitle: const Text('Remove completamente o PIN'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _removerPin,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informações de segurança
                Card(
                  color: AppColors.primaria.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaria),
                            const SizedBox(width: 12),
                            Text(
                              'Informações de Segurança',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaria,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem('🔒', 'Seu PIN é criptografado com SHA-256'),
                        _buildInfoItem('📱', 'O PIN é armazenado apenas no seu dispositivo'),
                        _buildInfoItem('🔄', 'Você pode ativar/desativar quando quiser'),
                        _buildInfoItem('⚠️', 'Se esquecer o PIN, precisará removê-lo'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Status atual
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _pinEnabled ? AppColors.entrada.withOpacity(0.1) : AppColors.textoSecundario.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _pinEnabled ? AppColors.entrada : AppColors.textoSecundario,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pinEnabled ? Icons.security : Icons.security_outlined,
                        color: _pinEnabled ? AppColors.entrada : AppColors.textoSecundario,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${_pinEnabled ? 'PIN Ativado' : 'PIN Desativado'}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _pinEnabled ? AppColors.entrada : AppColors.textoSecundario,
                              ),
                            ),
                            Text(
                              _pinEnabled 
                                  ? 'Seu app está protegido por PIN'
                                  : 'Seu app não está protegido',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _pinEnabled ? AppColors.entrada : AppColors.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaria,
              ),
            ),
          ),
        ],
      ),
    );
  }
}