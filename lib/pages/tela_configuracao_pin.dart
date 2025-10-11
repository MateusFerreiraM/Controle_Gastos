import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';

class TelaConfiguracaoPin extends StatefulWidget {
  final VoidCallback onPinConfigured;
  
  const TelaConfiguracaoPin({
    super.key,
    required this.onPinConfigured,
  });

  @override
  State<TelaConfiguracaoPin> createState() => _TelaConfiguracaoPinState();
}

class _TelaConfiguracaoPinState extends State<TelaConfiguracaoPin> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _pinObscured = true;
  bool _confirmPinObscured = true;

  Future<void> _configurarPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    // Validações
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'O PIN deve ter pelo menos 4 dígitos';
      });
      return;
    }

    if (pin.length > 8) {
      setState(() {
        _errorMessage = 'O PIN deve ter no máximo 8 dígitos';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'Os PINs não coincidem';
      });
      return;
    }

    // Verifica se contém apenas números
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() {
        _errorMessage = 'O PIN deve conter apenas números';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.setupPin(pin);
      
      if (success && mounted) {
        // Mostrar feedback de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN configurado com sucesso!'),
            backgroundColor: AppColors.entrada,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Aguardar um pouco e chamar callback
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onPinConfigured();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao configurar PIN. Tente novamente.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro inesperado. Tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                // Ícone e título
                Icon(
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Configurar PIN',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Crie um PIN para proteger seu controle de gastos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                
                const SizedBox(height: 40),
                
                // Campo PIN
                TextField(
                  controller: _pinController,
                  obscureText: _pinObscured,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Criar PIN',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_pinObscured ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _pinObscured = !_pinObscured),
                    ),
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Campo confirmar PIN
                TextField(
                  controller: _confirmPinController,
                  obscureText: _confirmPinObscured,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Confirmar PIN',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_confirmPinObscured ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _confirmPinObscured = !_confirmPinObscured),
                    ),
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Dicas de segurança
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '• Use de 4 a 8 dígitos\n• Evite sequências óbvias (1234, 0000)\n• Lembre-se do seu PIN, ele não pode ser recuperado',
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Mensagem de erro
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Botão configurar
                ElevatedButton(
                  onPressed: _isLoading ? null : _configurarPin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Configurar PIN'),
                ),
                
                const SizedBox(height: 16),
                
                // Informação adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaria.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaria,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seu PIN é criptografado e armazenado com segurança no dispositivo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaria,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}