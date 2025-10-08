import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';

class TelaConfiguracaoSeguranca extends StatefulWidget {
  const TelaConfiguracaoSeguranca({super.key});

  @override
  State<TelaConfiguracaoSeguranca> createState() => _TelaConfiguracaoSegurancaState();
}

class _TelaConfiguracaoSegurancaState extends State<TelaConfiguracaoSeguranca> {
  bool _securityEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final securityEnabled = await AuthService.isSecurityEnabled();

    setState(() {
      _securityEnabled = securityEnabled;
      _isLoading = false;
    });
  }

  Future<void> _showCreatePinDialog() async {
    String? pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreatePinDialog(),
    );

    if (pin != null) {
      await AuthService.setPin(pin);
      setState(() {
        _securityEnabled = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showChangePinDialog() async {
    String? newPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChangePinDialog(),
    );

    if (newPin != null) {
      await AuthService.setPin(newPin);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN alterado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _toggleSecurity(bool value) async {
    if (value) {
      // Ativar segurança - precisa criar PIN
      await _showCreatePinDialog();
    } else {
      // Desativar segurança - pedir confirmação
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desativar Segurança'),
          content: const Text(
            'Tem certeza que deseja desativar a segurança do aplicativo? '
            'Isso removerá o PIN de acesso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Desativar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await AuthService.setSecurityEnabled(false);
        setState(() {
          _securityEnabled = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Segurança desativada'),
              backgroundColor: Colors.orange,
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
        title: const Text('Configurações de Segurança'),
        backgroundColor: AppColors.primaria,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppColors.primaria,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Segurança do Aplicativo',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaria,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Proteja seus dados financeiros com PIN. '
                          'Quando ativado, será necessário inserir o PIN para acessar o aplicativo.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Ativar/Desativar Segurança
                Card(
                  child: ListTile(
                    leading: Icon(
                      _securityEnabled ? Icons.lock : Icons.lock_open,
                      color: _securityEnabled ? Colors.green : Colors.grey,
                    ),
                    title: const Text('Ativar Segurança'),
                    subtitle: Text(
                      _securityEnabled 
                        ? 'Segurança ativa - PIN necessário para acesso'
                        : 'Segurança desativada - acesso livre ao app',
                    ),
                    trailing: Switch(
                      value: _securityEnabled,
                      onChanged: _toggleSecurity,
                    ),
                  ),
                ),
                
                if (_securityEnabled) ...[
                  const SizedBox(height: 8),
                  
                  // Alterar PIN
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.pin,
                        color: AppColors.primaria,
                      ),
                      title: const Text('Alterar PIN'),
                      subtitle: const Text('Modificar seu PIN de segurança'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showChangePinDialog,
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Informações de segurança
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sobre a Segurança',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Seu PIN é armazenado de forma segura (criptografado)\n'
                          '• Após 5 tentativas incorretas, o app fica bloqueado por 15 minutos\n'
                          '• Você pode desativar a segurança a qualquer momento\n'
                          '• Todos os seus dados ficam armazenados localmente no seu dispositivo',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CreatePinDialog extends StatefulWidget {
  @override
  State<_CreatePinDialog> createState() => _CreatePinDialogState();
}

class _CreatePinDialogState extends State<_CreatePinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isConfirming ? 'Confirmar PIN' : 'Criar PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isConfirming 
              ? 'Digite novamente seu PIN para confirmar'
              : 'Crie um PIN de 4 a 6 dígitos para proteger seu aplicativo',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _isConfirming ? _confirmPinController : _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _isConfirming ? 'Confirmar PIN' : 'PIN',
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_isConfirming) {
              // Confirmar PIN
              if (_pinController.text == _confirmPinController.text) {
                Navigator.of(context).pop(_pinController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PINs não coincidem'),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() {
                  _confirmPinController.clear();
                });
              }
            } else {
              // Primeiro PIN
              if (_pinController.text.length >= 4) {
                setState(() {
                  _isConfirming = true;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN deve ter pelo menos 4 dígitos'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text(_isConfirming ? 'Confirmar' : 'Próximo'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}

class _ChangePinDialog extends StatefulWidget {
  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  int _step = 0; // 0: PIN atual, 1: Novo PIN, 2: Confirmar novo PIN

  @override
  Widget build(BuildContext context) {
    String title = 'PIN Atual';
    String subtitle = 'Digite seu PIN atual';
    TextEditingController controller = _currentPinController;

    if (_step == 1) {
      title = 'Novo PIN';
      subtitle = 'Digite seu novo PIN (4 a 6 dígitos)';
      controller = _newPinController;
    } else if (_step == 2) {
      title = 'Confirmar PIN';
      subtitle = 'Digite novamente seu novo PIN';
      controller = _confirmPinController;
    }

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subtitle),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: title,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            if (_step == 0) {
              // Verificar PIN atual
              final isValid = await AuthService.verifyPin(_currentPinController.text);
              if (isValid) {
                setState(() {
                  _step = 1;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN atual incorreto'),
                    backgroundColor: Colors.red,
                  ),
                );
                _currentPinController.clear();
              }
            } else if (_step == 1) {
              // Validar novo PIN
              if (_newPinController.text.length >= 4) {
                setState(() {
                  _step = 2;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN deve ter pelo menos 4 dígitos'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              // Confirmar novo PIN
              if (_newPinController.text == _confirmPinController.text) {
                Navigator.of(context).pop(_newPinController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PINs não coincidem'),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() {
                  _confirmPinController.clear();
                });
              }
            }
          },
          child: Text(_step == 2 ? 'Confirmar' : 'Próximo'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}