import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'pagina_inicial.dart';
import 'tela_login.dart';
import 'tela_pin_teclado.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _codigoGrupo;
  bool _verificando = true;
  bool _pinEnabled = false;
  bool _pinVerificado = false;

  @override
  void initState() {
    super.initState();
    _verificarEstadoAutenticacao();
  }

  void _verificarEstadoAutenticacao() async {
    try {
      // Verifica se PIN está ativado
      final pinEnabled = await AuthService.isPinEnabled();
      
      // Verifica se tem código de grupo salvo
      final codigoSalvo = await AuthService.getCodigoGrupo();
      
      if (mounted) {
        setState(() {
          _pinEnabled = pinEnabled;
          _codigoGrupo = codigoSalvo;
          _verificando = false;
          // Se PIN não está ativado, considera como "verificado" para pular a tela
          _pinVerificado = !pinEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verificando = false;
          _pinVerificado = true; // Em caso de erro, pula o PIN
        });
      }
    }
  }

  void _onPinVerificado() {
    setState(() {
      _pinVerificado = true;
    });
  }

  void _onConectar(String codigo) async {
    // Salva o código do grupo
    await AuthService.saveCodigoGrupo(codigo);
    setState(() {
      _codigoGrupo = codigo;
    });
  }

  void _onSair() async {
    // Remove apenas o código do grupo, mantém configurações de PIN
    await AuthService.logout();
    setState(() {
      _codigoGrupo = null;
      // Se PIN está ativado, força nova verificação
      if (_pinEnabled) {
        _pinVerificado = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 1. Se PIN está ativado mas não foi verificado, mostra tela de PIN
    if (_pinEnabled && !_pinVerificado) {
      return TelaPinTeclado(
        onPinVerified: _onPinVerificado,
        isConfiguring: false,
      );
    }

    // 2. Se não tem código de grupo, mostra tela de login do grupo
    if (_codigoGrupo == null || _codigoGrupo!.isEmpty) {
      return TelaDeLogin(onConectar: _onConectar);
    }

    // 3. Se tudo está OK, mostra a página inicial
    return PaginaInicial(
      codigoGrupo: _codigoGrupo!,
      onSair: _onSair,
    );
  }
}