import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/tela_autenticacao.dart';
import '../pages/pagina_inicial.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthentication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App indo para background
      _lastBackgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // App voltando do background
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    if (_lastBackgroundTime != null) {
      final timeInBackground = DateTime.now().difference(_lastBackgroundTime!);
      
      // Se ficou mais de 1 minuto em background, pedir autenticação novamente
      if (timeInBackground.inMinutes >= 1) {
        final isSecurityEnabled = await AuthService.isSecurityEnabled();
        if (isSecurityEnabled && _isAuthenticated) {
          setState(() {
            _isAuthenticated = false;
          });
        }
      }
    }
  }

  Future<void> _checkAuthentication() async {
    final isSecurityEnabled = await AuthService.isSecurityEnabled();
    
    if (!isSecurityEnabled) {
      // Se segurança não está habilitada, permitir acesso direto
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
      return;
    }

    // Se segurança está habilitada, sempre pedir autenticação
    setState(() {
      _isAuthenticated = false;
      _isLoading = false;
    });
  }

  Future<void> _handleAuthentication() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TelaAutenticacao(),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      // Navegar automaticamente para tela de autenticação
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAuthentication();
      });
      
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const PaginaInicial();
  }
}