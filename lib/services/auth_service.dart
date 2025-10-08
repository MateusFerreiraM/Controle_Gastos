import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static const String _pinKey = 'user_pin';
  static const String _securityEnabledKey = 'security_enabled';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lastFailedAttemptKey = 'last_failed_attempt';
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  // Verificar se a segurança está habilitada
  static Future<bool> isSecurityEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_securityEnabledKey) ?? false;
  }

  // Habilitar/desabilitar segurança
  static Future<void> setSecurityEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_securityEnabledKey, enabled);
    if (!enabled) {
      // Se desabilitou, limpar dados de segurança
      await prefs.remove(_pinKey);
      await prefs.remove(_failedAttemptsKey);
      await prefs.remove(_lastFailedAttemptKey);
    }
  }

  // Verificar se o PIN está configurado
  static Future<bool> isPinConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  // Definir PIN (com hash para segurança)
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = _hashPin(pin);
    await prefs.setString(_pinKey, hashedPin);
    await prefs.setBool(_securityEnabledKey, true);
  }

  // Verificar PIN
  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  // Hash do PIN para segurança
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verificar se está bloqueado por tentativas falhadas
  static Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    final lastFailedAttempt = prefs.getInt(_lastFailedAttemptKey) ?? 0;
    
    if (failedAttempts >= maxFailedAttempts) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastFailedAttempt;
      final lockoutDuration = lockoutDurationMinutes * 60 * 1000; // em milliseconds
      
      if (timeDifference < lockoutDuration) {
        return true;
      } else {
        // Limpar tentativas após o período de bloqueio
        await prefs.remove(_failedAttemptsKey);
        await prefs.remove(_lastFailedAttemptKey);
        return false;
      }
    }
    
    return false;
  }

  // Registrar tentativa falhada
  static Future<void> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final currentAttempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    await prefs.setInt(_failedAttemptsKey, currentAttempts + 1);
    await prefs.setInt(_lastFailedAttemptKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Limpar tentativas falhadas (após sucesso)
  static Future<void> clearFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lastFailedAttemptKey);
  }

  // Obter número de tentativas restantes
  static Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    return maxFailedAttempts - failedAttempts;
  }

  // Obter tempo restante de bloqueio
  static Future<Duration> getRemainingLockoutTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFailedAttempt = prefs.getInt(_lastFailedAttemptKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastFailedAttempt;
    final lockoutDuration = lockoutDurationMinutes * 60 * 1000;
    
    final remainingTime = lockoutDuration - timeDifference;
    return Duration(milliseconds: remainingTime > 0 ? remainingTime : 0);
  }
}