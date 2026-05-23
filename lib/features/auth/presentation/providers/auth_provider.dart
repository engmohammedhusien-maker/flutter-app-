import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/network/api_client.dart';
import 'package:laravel_flutter_app/core/security/biometric_auth_service.dart';
import 'package:laravel_flutter_app/core/security/secure_storage_helper.dart';
import 'package:laravel_flutter_app/features/auth/data/models/user_model.dart';
import 'package:laravel_flutter_app/features/auth/data/repositories/auth_repository.dart';

// مفاتيح التخزين الآمن
const _keyEmail = 'saved_email';
const _keyPassword = 'saved_password';
const _keyBiometricEnabled = 'biometric_enabled';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final List<String> permissionNames;
  final bool isBiometricAvailable;
  final bool hasSavedCredentials;
  final bool isBiometricEnabled;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    List<String>? permissionNames,
    this.isBiometricAvailable = false,
    this.hasSavedCredentials = false,
    this.isBiometricEnabled = false,
  }) : permissionNames = permissionNames ?? [];

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    List<String>? permissionNames,
    bool? isBiometricAvailable,
    bool? hasSavedCredentials,
    bool? isBiometricEnabled,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionNames: permissionNames ?? this.permissionNames,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      hasSavedCredentials: hasSavedCredentials ?? this.hasSavedCredentials,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  final ISecureStorageHelper _storage;
  final BiometricAuthService _biometricService;

  AuthNotifier(
    this._authRepository,
    this._storage,
    this._biometricService,
  ) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    // قراءة حالة البصمة والتخزين
    final email = await _storage.read(_keyEmail);
    final hasCreds = email != null && email.isNotEmpty;
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    final biometricEnabled =
        (await _storage.read(_keyBiometricEnabled)) == 'true';

    state = state.copyWith(
      isBiometricAvailable: biometricAvailable && hasCreds,
      hasSavedCredentials: hasCreds,
      isBiometricEnabled: biometricEnabled,
    );
  }

  // --- تسجيل الدخول العادي ---
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.login(email, password);
      await _storage.write('access_token', result.token.accessToken);
      if (result.token.refreshToken != null) {
        await _storage.write('refresh_token', result.token.refreshToken!);
      }
      final permNames = result.user.getAllPermissionNames();
      state = state.copyWith(
        user: result.user,
        isLoading: false,
        permissionNames: permNames,
      );
    } on DioException catch (e) {
      String message = 'حدث خطأ في الاتصال';
      if (e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        debugPrint('❌ Error response: $data');
        if (data['errors'] is String && (data['errors'] as String).isNotEmpty) {
          message = data['errors'];
        } else if (data['errors'] is Map) {
          final errorsMap = data['errors'] as Map;
          if (errorsMap.isNotEmpty) {
            final firstValue = errorsMap.values.first;
            if (firstValue is List && firstValue.isNotEmpty) {
              message = firstValue.first.toString();
            } else {
              message = firstValue.toString();
            }
          }
        } else if (data['message'] is String &&
            (data['message'] as String).isNotEmpty) {
          message = data['message'];
        }
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'حدث خطأ غير متوقع');
    }
  }

  // --- تفعيل البصمة بعد التحقق من كلمة المرور ---
  Future<String?> enableBiometricWithPassword(
      String email, String password) async {
    // نحاول تسجيل الدخول بهذه البيانات (بدون التأثير على الحالة الحالية)
    try {
      final result = await _authRepository.login(email, password);
      // إذا نجح الدخول، فالبيانات صحيحة، احفظها للبصمة
      await _storage.write(_keyEmail, email);
      await _storage.write(_keyPassword, password);
      await _storage.write(_keyBiometricEnabled, 'true');
      final biometricAvailable = await _biometricService.isBiometricAvailable();
      state = state.copyWith(
        isBiometricAvailable: biometricAvailable,
        hasSavedCredentials: true,
        isBiometricEnabled: true,
      );
      return null; // لا خطأ
    } on DioException catch (e) {
      // استخراج رسالة الخطأ
      String message = 'كلمة المرور غير صحيحة';
      if (e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['errors'] is String && (data['errors'] as String).isNotEmpty) {
          message = data['errors'];
        } else if (data['message'] is String &&
            (data['message'] as String).isNotEmpty) {
          message = data['message'];
        }
      }
      return message;
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  // --- تعطيل البصمة من الإعدادات ---
  Future<void> disableBiometric() async {
    await _storage.delete(_keyBiometricEnabled);
    state = state.copyWith(isBiometricEnabled: false);
  }

  // --- الدخول بالبصمة ---
  Future<void> biometricLogin() async {
    if (!state.isBiometricEnabled) {
      state =
          state.copyWith(error: 'الدخول بالبصمة غير مفعل. فعّله من الإعدادات.');
      return;
    }

    final email = await _storage.read(_keyEmail);
    final password = await _storage.read(_keyPassword);

    if (email == null || password == null) {
      state = state.copyWith(error: 'لا توجد بيانات محفوظة');
      return;
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'استخدم بصمتك لتسجيل الدخول',
    );
    if (!authenticated) {
      state = state.copyWith(error: 'فشل التحقق من البصمة');
      return;
    }

    await login(email, password);
  }

  // --- حذف كل بيانات البصمة ---
  Future<void> clearSavedCredentials() async {
    await _storage.delete(_keyEmail);
    await _storage.delete(_keyPassword);
    await _storage.delete(_keyBiometricEnabled);
    state = state.copyWith(
      isBiometricAvailable: false,
      hasSavedCredentials: false,
      isBiometricEnabled: false,
    );
  }

  // --- تسجيل الخروج ---
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {}
    await _storage.delete('access_token');
    await _storage.delete('refresh_token');
    // إعادة الحالة الأساسية
    state = AuthState();
    // إعادة استعلام حالة البصمة بعد الخروج
    await _init();
  }

  // --- التحقق من الجلسة عند بدء التشغيل ---
  Future<void> checkAuth() async {
    final token = await _storage.read('access_token');
    if (token != null) {
      try {
        final user = await _authRepository.getUser();
        final permNames = user.getAllPermissionNames();
        state = AuthState(user: user, permissionNames: permNames);
      } catch (e) {
        await _storage.delete('access_token');
        state = AuthState();
      }
    }
  }
}

// --- Providers ---
final biometricServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  final biometric = ref.watch(biometricServiceProvider);
  return AuthNotifier(repo, storage, biometric);
});
