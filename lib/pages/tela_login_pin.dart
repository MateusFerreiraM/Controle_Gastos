import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';

class TelaLoginPin extends StatefulWidget {
  final VoidCallback onPinVerified;
  
  const TelaLoginPin({
    super.key,
    required this.onPinVerified,
  });

  @override
  State<TelaLoginPin> createState() => _TelaLoginPinState();
}

class _TelaLoginPinState extends State<TelaLoginPin> with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _pinObscured = true;
  int _tentativasErradas = 0;
  static const int _maxTentativas = 5;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  Future<void> _verificarPin() async {
    final pin = _pinController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    if (pin.isEmpty) {
      setState(() {
        _errorMessage = 'Digite seu PIN';
      });
      _shakeError();
      return;
    }

    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN deve ter pelo menos 4 dígitos';
      });
      _shakeError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await AuthService.verifyPin(pin);
      
      if (isValid && mounted) {
        // PIN correto - resetar tentativas e prosseguir
        _tentativasErradas = 0;
        
        // Feedback visual de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN correto!'),
            backgroundColor: AppColors.entrada,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Aguardar um pouco e chamar callback
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onPinVerified();
        
      } else if (mounted) {
        // PIN incorreto
        _tentativasErradas++;
        _pinController.clear();
        
        if (_tentativasErradas >= _maxTentativas) {
          setState(() {
            _errorMessage = 'Muitas tentativas incorretas. Reinicie o app.';
          });
        } else {
          final tentativasRestantes = _maxTentativas - _tentativasErradas;
          setState(() {
            _errorMessage = 'PIN incorreto. $tentativasRestantes tentativa(s) restante(s)';
          });
        }
        
        _shakeError();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao verificar PIN. Tente novamente.';
        });
        _shakeError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shakeError() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  Future<void> _resetarPin() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar PIN'),
        content: const Text(
          'Esta ação irá remover o PIN atual e você precisará configurar um novo. '
          'Também será desconectado do grupo atual.\n\n'
          'Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      await AuthService.resetAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN resetado. Configure um novo PIN.'),
            backgroundColor: AppColors.primaria,
          ),
        );
        // Aqui você pode navegar para a tela de configuração
        // ou reiniciar o app
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ícone e título
                      Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'Digite seu PIN',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Insira seu PIN para acessar o controle de gastos',
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
                        enabled: _tentativasErradas < _maxTentativas && !_isLoading,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'PIN',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_pinObscured ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _pinObscured = !_pinObscured),
                          ),
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                        onSubmitted: (_) => _verificarPin(),
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
                      
                      // Botão entrar
                      ElevatedButton(
                        onPressed: (_isLoading || _tentativasErradas >= _maxTentativas) 
                            ? null 
                            : _verificarPin,
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
                            : const Text('Entrar'),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Botão de resetar PIN (só aparece se muitas tentativas erradas)
                      if (_tentativasErradas >= _maxTentativas) ...[
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: _resetarPin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          child: const Text('Esqueci meu PIN'),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Informação de segurança
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaria.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppColors.primaria,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Seus dados estão protegidos por criptografia',
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
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
}