import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _pinKey = 'user_pin_hash';
  static const String _isSetupKey = 'pin_setup_completed';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _codigoGrupoKey = 'codigo_grupo';

  // Verifica se o PIN está ativado
  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false; // Desativado por padrão
  }

  // Ativa ou desativa o PIN
  static Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }

  // Verifica se o PIN já foi configurado (diferente de estar ativado)
  static Future<bool> isPinConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSetupKey) ?? false;
  }

  // Criptografa o PIN usando SHA-256
  static String _hashPin(String pin) {
    var bytes = utf8.encode(pin);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Configura um novo PIN e ativa automaticamente
  static Future<bool> setupPin(String pin) async {
    if (pin.length < 4) {
      return false; // PIN deve ter pelo menos 4 dígitos
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final hashedPin = _hashPin(pin);
      
      await prefs.setString(_pinKey, hashedPin);
      await prefs.setBool(_isSetupKey, true);
      await prefs.setBool(_pinEnabledKey, true); // Ativa automaticamente
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verifica se o PIN inserido está correto
  static Future<bool> verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_pinKey);
      
      if (storedHash == null) {
        return false;
      }
      
      final inputHash = _hashPin(pin);
      return inputHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  // Altera o PIN existente (requer PIN atual)
  static Future<bool> changePin(String currentPin, String newPin) async {
    if (newPin.length < 4) {
      return false;
    }

    final isCurrentPinValid = await verifyPin(currentPin);
    if (!isCurrentPinValid) {
      return false;
    }

    return await setupPin(newPin);
  }

  // Remove o PIN e reseta a configuração (para casos extremos)
  static Future<void> resetPinSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_isSetupKey);
    await prefs.remove(_pinEnabledKey);
  }

  // Salva o código do grupo
  static Future<void> saveCodigoGrupo(String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codigoGrupoKey, codigo);
  }

  // Recupera o código do grupo
  static Future<String?> getCodigoGrupo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_codigoGrupoKey);
  }

  // Remove o código do grupo (para logout)
  static Future<void> clearCodigoGrupo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codigoGrupoKey);
  }

  // Faz logout completo (remove grupo mas mantém PIN)
  static Future<void> logout() async {
    await clearCodigoGrupo();
  }

  // Reset completo (remove PIN e grupo - usar com cuidado)
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_isSetupKey);
    await prefs.remove(_pinEnabledKey);
    await prefs.remove(_codigoGrupoKey);
  }
}