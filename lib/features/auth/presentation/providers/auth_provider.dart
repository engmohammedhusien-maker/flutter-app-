import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/network/api_client.dart';
import 'package:laravel_flutter_app/core/security/biometric_auth_service.dart';
import 'package:laravel_flutter_app/core/security/secure_storage_helper.dart';
import 'package:laravel_flutter_app/features/auth/data/models/user_model.dart';
import 'package:laravel_flutter_app/features/auth/data/repositories/auth_repository.dart';

const _keyBiometricEmail = 'biometric_email';
const _keyBiometricPassword = 'biometric_password';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final List<String> permissionNames;
  final bool isBiometricAvailable; // هل يدعم الجهاز البصمة؟
  final String? biometricOwnerEmail; // البريد المفعل له البصمة (إن وجد)

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    List<String>? permissionNames,
    this.isBiometricAvailable = false,
    this.biometricOwnerEmail,
  }) : permissionNames = permissionNames ?? [];

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    List<String>? permissionNames,
    bool? isBiometricAvailable,
    String? biometricOwnerEmail,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionNames: permissionNames ?? this.permissionNames,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      biometricOwnerEmail: biometricOwnerEmail ?? this.biometricOwnerEmail,
    );
  }

  /// هل الحساب الحالي هو صاحب البصمة؟
  bool get isCurrentUserBiometricOwner =>
      user != null && user!.email == biometricOwnerEmail;
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
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    final ownerEmail = await _storage.read(_keyBiometricEmail);
    state = state.copyWith(
      isBiometricAvailable: biometricAvailable,
      biometricOwnerEmail: ownerEmail,
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

  // --- تفعيل البصمة للحساب الحالي (يتحقق من كلمة المرور) ---
  Future<String?> enableBiometricWithPassword(
      String email, String password) async {
    // إذا كان هناك مالك سابق غير هذا الحساب، نمنع التفعيل ما لم يتم التعطيل أولاً
    final owner = state.biometricOwnerEmail;
    if (owner != null && owner != email) {
      return 'البصمة مفعلة لحساب آخر. الرجاء تعطيلها أولاً.';
    }

    try {
      await _authRepository.login(email, password);
      // حفظ بيانات البصمة
      await _storage.write(_keyBiometricEmail, email);
      await _storage.write(_keyBiometricPassword, password);
      state = state.copyWith(biometricOwnerEmail: email);
      return null; // نجاح
    } on DioException catch (e) {
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

  // --- تعطيل البصمة (يحذف بيانات المالك) ---
  Future<void> disableBiometric() async {
    await _storage.delete(_keyBiometricEmail);
    await _storage.delete(_keyBiometricPassword);
    state = state.copyWith(biometricOwnerEmail: null);
  }

  // --- استبدال البصمة: يستبدل الحساب السابق بالحساب الحالي ---
  Future<String?> replaceBiometricOwner(String email, String password) async {
    try {
      await _authRepository.login(email, password);
      await _storage.write(_keyBiometricEmail, email);
      await _storage.write(_keyBiometricPassword, password);
      state = state.copyWith(biometricOwnerEmail: email);
      return null;
    } on DioException catch (e) {
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

  // --- الدخول بالبصمة (يقرأ البريد المحفوظ الوحيد) ---
  Future<void> biometricLogin() async {
    final email = await _storage.read(_keyBiometricEmail);
    final password = await _storage.read(_keyBiometricPassword);

    if (email == null || password == null) {
      state = state.copyWith(error: 'لا توجد بصمة محفوظة');
      return;
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'استخدم بصمتك لتسجيل الدخول كـ $email',
    );
    if (!authenticated) {
      state = state.copyWith(error: 'فشل التحقق من البصمة');
      return;
    }

    await login(email, password);
  }

  // --- تسجيل الخروج ---
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {}
    await _storage.delete('access_token');
    await _storage.delete('refresh_token');
    final ownerEmail = await _storage.read(_keyBiometricEmail);
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    state = AuthState(
      biometricOwnerEmail: ownerEmail,
      isBiometricAvailable: biometricAvailable,
    );
  }

  // --- التحقق من الجلسة عند بدء التشغيل ---
  Future<void> checkAuth() async {
    final token = await _storage.read('access_token');
    if (token != null) {
      try {
        final user = await _authRepository.getUser();
        final permNames = user.getAllPermissionNames();
        final ownerEmail = state.biometricOwnerEmail;
        state = AuthState(
          user: user,
          permissionNames: permNames,
          biometricOwnerEmail: ownerEmail,
        );
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
