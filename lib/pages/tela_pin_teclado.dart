import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';

class TelaPinTeclado extends StatefulWidget {
  final VoidCallback onPinVerified;
  final bool isConfiguring;
  final String? title;
  
  const TelaPinTeclado({
    super.key,
    required this.onPinVerified,
    this.isConfiguring = false,
    this.title,
  });

  @override
  State<TelaPinTeclado> createState() => _TelaPinTecladoState();
}

class _TelaPinTecladoState extends State<TelaPinTeclado> with TickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmingPin = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _tentativasErradas = 0;
  static const int _maxTentativas = 5;
  static const int _pinLength = 4;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _errorController;
  late Animation<Color?> _errorColorAnimation;

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

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _errorColorAnimation = ColorTween(
      begin: AppColors.textoPrincipal,
      end: AppColors.saida,
    ).animate(_errorController);
  }

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += number;
        _errorMessage = null;
      });
      
      if (_pin.length == _pinLength) {
        _processPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _processPin() async {
    if (widget.isConfiguring) {
      if (!_isConfirmingPin) {
        // Primeira vez digitando o PIN
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirmingPin = true;
        });
      } else {
        // Confirmando o PIN
        if (_pin == _confirmPin) {
          await _configurarPin();
        } else {
          _showError('PINs não coincidem. Tente novamente.');
          setState(() {
            _pin = '';
            _confirmPin = '';
            _isConfirmingPin = false;
          });
        }
      }
    } else {
      await _verificarPin();
    }
  }

  Future<void> _configurarPin() async {
    setState(() => _isLoading = true);

    try {
      final success = await AuthService.setupPin(_pin);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN configurado com sucesso!'),
            backgroundColor: AppColors.entrada,
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onPinVerified();
      } else if (mounted) {
        _showError('Erro ao configurar PIN. Tente novamente.');
        setState(() {
          _pin = '';
          _confirmPin = '';
          _isConfirmingPin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro inesperado. Tente novamente.');
        setState(() {
          _pin = '';
          _confirmPin = '';
          _isConfirmingPin = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verificarPin() async {
    setState(() => _isLoading = true);

    try {
      final isValid = await AuthService.verifyPin(_pin);
      
      if (isValid && mounted) {
        _tentativasErradas = 0;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN correto!'),
            backgroundColor: AppColors.entrada,
            duration: Duration(seconds: 1),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onPinVerified();
        
      } else if (mounted) {
        _tentativasErradas++;
        
        if (_tentativasErradas >= _maxTentativas) {
          _showError('Muitas tentativas incorretas. Reinicie o app.');
        } else {
          final tentativasRestantes = _maxTentativas - _tentativasErradas;
          _showError('PIN incorreto. $tentativasRestantes tentativa(s) restante(s)');
        }
        
        setState(() => _pin = '');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao verificar PIN. Tente novamente.');
        setState(() => _pin = '');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
    _errorController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _errorController.reverse();
        }
      });
    });
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        bool isFilled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primaria : Colors.transparent,
            border: Border.all(
              color: _errorMessage != null ? AppColors.saida : AppColors.primaria,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumpadButton(String text, {VoidCallback? onPressed, IconData? icon}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: AspectRatio(
          aspectRatio: 1.1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaria.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, size: 20, color: AppColors.primaria)
                      : Text(
                          text,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaria,
                            fontWeight: FontWeight.w500,
                            fontSize: 22,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        // Linha 1-2-3
        Row(
          children: [
            _buildNumpadButton('1', onPressed: () => _onNumberPressed('1')),
            _buildNumpadButton('2', onPressed: () => _onNumberPressed('2')),
            _buildNumpadButton('3', onPressed: () => _onNumberPressed('3')),
          ],
        ),
        // Linha 4-5-6
        Row(
          children: [
            _buildNumpadButton('4', onPressed: () => _onNumberPressed('4')),
            _buildNumpadButton('5', onPressed: () => _onNumberPressed('5')),
            _buildNumpadButton('6', onPressed: () => _onNumberPressed('6')),
          ],
        ),
        // Linha 7-8-9
        Row(
          children: [
            _buildNumpadButton('7', onPressed: () => _onNumberPressed('7')),
            _buildNumpadButton('8', onPressed: () => _onNumberPressed('8')),
            _buildNumpadButton('9', onPressed: () => _onNumberPressed('9')),
          ],
        ),
        // Linha vazio-0-backspace
        Row(
          children: [
            const Expanded(child: SizedBox()), // Espaço vazio
            _buildNumpadButton('0', onPressed: () => _onNumberPressed('0')),
            _buildNumpadButton('', 
              icon: Icons.backspace_outlined, 
              onPressed: _onBackspacePressed,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.title ?? 
        (widget.isConfiguring 
            ? (_isConfirmingPin ? 'Repita seu PIN' : 'Crie seu PIN')
            : 'Digite seu PIN');

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    // Ícone
                    Icon(
                      Icons.security,
                      size: 60,
                      color: AppColors.primaria,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Título
                    AnimatedBuilder(
                      animation: _errorColorAnimation,
                      builder: (context, child) {
                        return Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _errorColorAnimation.value ?? AppColors.primaria,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      widget.isConfiguring 
                          ? (_isConfirmingPin 
                              ? 'Digite o mesmo PIN novamente para confirmar'
                              : 'Digite 4 números para seu PIN de segurança')
                          : 'Insira seu PIN para acessar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // PIN Dots
                    _buildPinDots(),
                    
                    const SizedBox(height: 16),
                    
                    // Mensagem de erro
                    SizedBox(
                      height: 35,
                      child: _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.saida,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    
                    const Spacer(),
                    
                    // Loading indicator
                    if (_isLoading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Teclado numérico
                    _buildNumpad(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _errorController.dispose();
    super.dispose();
  }
}