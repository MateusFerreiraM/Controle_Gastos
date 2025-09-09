import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pagina_inicial.dart';
import 'tela_login.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _codigoGrupo;
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    _verificarLogin();
  }

  void _verificarLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final codigoSalvo = prefs.getString('codigo_grupo');
    if (mounted) {
      setState(() {
        _codigoGrupo = codigoSalvo;
        _verificando = false;
      });
    }
  }

  void _onConectar(String codigo) {
    setState(() {
      _codigoGrupo = codigo;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_codigoGrupo == null || _codigoGrupo!.isEmpty) {
      return TelaDeLogin(onConectar: _onConectar);
    } else {
      return PaginaInicial(
        codigoGrupo: _codigoGrupo!,
        onSair: () {
          setState(() {
            _codigoGrupo = null;
          });
        },
      );
    }
  }
}