import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'database_service.dart';
import '../models/account.dart';
import 'dart:async';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static int _failedAttempts = 0;
  static DateTime? _lockoutEndTime;
  static DateTime? _lastActiveTime;
  
  static bool get isLockedOut => _lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!);
  static int get failedAttempts => _failedAttempts;
  static Duration? get remainingLockoutTime => _lockoutEndTime?.difference(DateTime.now());

  static void updateLastActive() {
    _lastActiveTime = DateTime.now();
  }

  static bool shouldAutoLock(int durationMinutes) {
    if (_lastActiveTime == null) return false;
    final inactiveDuration = DateTime.now().difference(_lastActiveTime!);
    return inactiveDuration.inMinutes >= durationMinutes;
  }

  static Future<bool> canAuthenticateWithBiometrics() async {
    final bool canCheckBiometrics = await _auth.canCheckBiometrics;
    final bool isDeviceSupported = await _auth.isDeviceSupported();
    final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
    
    debugPrint('Hardware support: $canCheckBiometrics');
    debugPrint('Device supported: $isDeviceSupported');
    debugPrint('Enrolled biometrics: $availableBiometrics');

    return (canCheckBiometrics || isDeviceSupported) && availableBiometrics.isNotEmpty;
  }

  static Future<bool> authenticateWithBiometrics({String reason = 'Authenticate to access your wallet'}) async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General auth error: $e');
      return false;
    }
  }

  static Future<AuthResult> verifyPin(String enteredPin, Account account) async {
    if (isLockedOut) return AuthResult.lockedOut;

    if (enteredPin == account.pin) {
      _resetAttempts();
      return AuthResult.success;
    }

    if (account.fakePin != null && enteredPin == account.fakePin) {
      _resetAttempts();
      return AuthResult.fakeSuccess;
    }

    _failedAttempts++;
    if (_failedAttempts >= account.maxFailedAttempts) {
      _lockoutEndTime = DateTime.now().add(const Duration(minutes: 5)); // 5 min lockout
      if (account.isWipeEnabled) {
        // Optional: Trigger wipe here or handle in UI
      }
      return AuthResult.lockedOut;
    }

    return AuthResult.fail;
  }

  static void _resetAttempts() {
    _failedAttempts = 0;
    _lockoutEndTime = null;
  }
  
  static Future<void> wipeData() async {
    await DatabaseService.wipeAllData();
  }
}

enum AuthResult {
  success,
  fakeSuccess,
  fail,
  lockedOut
}
