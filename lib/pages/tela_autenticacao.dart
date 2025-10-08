import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../app_colors.dart';

class TelaAutenticacao extends StatefulWidget {
  const TelaAutenticacao({super.key});

  @override
  State<TelaAutenticacao> createState() => _TelaAutenticacaoState();
}

class _TelaAutenticacaoState extends State<TelaAutenticacao> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isLockedOut = false;
  Duration _lockoutTimeRemaining = Duration.zero;
  int _remainingAttempts = 5;
  String _biometricDescription = 'Biometria';

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _updateLockoutStatus();
    await _updateBiometricInfo();
    
    if (!_isLockedOut) {
      // Tentar autenticação automática com biometria
      final isBiometricEnabled = await AuthService.isBiometricEnabled();
      if (isBiometricEnabled) {
        _authenticateWithBiometric();
      }
    }
  }

  Future<void> _updateLockoutStatus() async {
    final isLockedOut = await AuthService.isLockedOut();
    final remaining = await AuthService.getRemainingAttempts();
    
    setState(() {
      _isLockedOut = isLockedOut;
      _remainingAttempts = remaining;
    });

    if (isLockedOut) {
      _startLockoutTimer();
    }
  }

  Future<void> _updateBiometricInfo() async {
    final description = await AuthService.getBiometricDescription();
    setState(() {
      _biometricDescription = description;
    });
  }

  void _startLockoutTimer() async {
    final lockoutTime = await AuthService.getRemainingLockoutTime();
    setState(() {
      _lockoutTimeRemaining = lockoutTime;
    });

    // Atualizar o timer a cada segundo
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      final remaining = await AuthService.getRemainingLockoutTime();
      
      if (mounted) {
        setState(() {
          _lockoutTimeRemaining = remaining;
        });
      }

      if (remaining.inSeconds <= 0) {
        await _updateLockoutStatus();
        return false;
      }
      return true;
    });
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isLockedOut) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.authenticateWithBiometric();
      
      if (success) {
        await AuthService.clearFailedAttempts();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      // Falha silenciosa na biometria - usuário pode usar PIN
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithPin() async {
    if (_isLockedOut || _pinController.text.length < 4) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.verifyPin(_pinController.text);
      
      if (success) {
        await AuthService.clearFailedAttempts();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        await AuthService.recordFailedAttempt();
        await _updateLockoutStatus();
        
        _pinController.clear();
        
        if (mounted) {
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isLockedOut 
                  ? 'Muitas tentativas incorretas. Tente novamente em ${_lockoutTimeRemaining.inMinutes} minutos.'
                  : 'PIN incorreto. $_remainingAttempts tentativas restantes.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao verificar PIN. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPinDot(int index) {
    final isFilled = index < _pinController.text.length;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? AppColors.primaria : Colors.transparent,
        border: Border.all(
          color: AppColors.primaria,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: Container(
        height: 80,
        margin: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: _isLockedOut || _isLoading 
            ? null 
            : () {
                if (_pinController.text.length < 6) {
                  setState(() {
                    _pinController.text += number;
                  });
                  HapticFeedback.lightImpact();
                }
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.textoPrincipal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            elevation: 2,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback? onPressed) {
    return Expanded(
      child: Container(
        height: 80,
        margin: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: _isLockedOut || _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.primaria,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            elevation: 2,
          ),
          child: Icon(icon, size: 28),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Ícone e título
              Icon(
                Icons.security,
                size: 80,
                color: AppColors.primaria,
              ),
              const SizedBox(height: 24),
              Text(
                'Controle de Gastos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaria,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLockedOut
                  ? 'App bloqueado por ${_lockoutTimeRemaining.inMinutes}m ${_lockoutTimeRemaining.inSeconds % 60}s'
                  : 'Digite seu PIN para continuar',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _isLockedOut ? Colors.red : AppColors.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Indicadores do PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) => _buildPinDot(index)),
              ),
              
              const SizedBox(height: 32),
              
              // Botão de biometria
              FutureBuilder<bool>(
                future: AuthService.isBiometricEnabled(),
                builder: (context, snapshot) {
                  if (snapshot.data == true && !_isLockedOut) {
                    return Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _authenticateWithBiometric,
                          icon: const Icon(Icons.fingerprint),
                          label: Text('Usar $_biometricDescription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaria,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ou digite seu PIN',
                          style: TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox(height: 16);
                },
              ),
              
              const Spacer(),
              
              // Teclado numérico
              Column(
                children: [
                  // Linha 1-2-3
                  Row(
                    children: [
                      _buildNumberButton('1'),
                      _buildNumberButton('2'),
                      _buildNumberButton('3'),
                    ],
                  ),
                  // Linha 4-5-6
                  Row(
                    children: [
                      _buildNumberButton('4'),
                      _buildNumberButton('5'),
                      _buildNumberButton('6'),
                    ],
                  ),
                  // Linha 7-8-9
                  Row(
                    children: [
                      _buildNumberButton('7'),
                      _buildNumberButton('8'),
                      _buildNumberButton('9'),
                    ],
                  ),
                  // Linha backspace-0-confirm
                  Row(
                    children: [
                      _buildActionButton(
                        Icons.backspace_outlined,
                        () {
                          if (_pinController.text.isNotEmpty) {
                            setState(() {
                              _pinController.text = _pinController.text
                                  .substring(0, _pinController.text.length - 1);
                            });
                            HapticFeedback.lightImpact();
                          }
                        },
                      ),
                      _buildNumberButton('0'),
                      _buildActionButton(
                        Icons.check,
                        _pinController.text.length >= 4 ? _authenticateWithPin : null,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Indicador de carregamento
              if (_isLoading)
                const CircularProgressIndicator(),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}