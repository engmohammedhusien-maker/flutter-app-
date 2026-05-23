import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    debugPrint(
        '🔍 canCheckBiometrics: $canCheck, isDeviceSupported: $isSupported');
    return canCheck || isSupported;
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      // طباعة أنواع البصمات المتاحة للتشخيص
      final availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint('🔍 Available biometrics: $availableBiometrics');

      // محاولة المصادقة
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: false, // يسمح بالبدائل (نمط، PIN)
        ),
      );
      debugPrint('✅ Biometric result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      debugPrint('❌ Biometric error: $e');
      return false;
    }
  }
}
