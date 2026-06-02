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

enum AuthError {
  invalidCredentials,
  emailRequired,
  emailInvalid,
  passwordRequired,
  passwordTooShort,
  serverError,
  networkError,
  unknown,
  serverUnavailable,
}

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final AuthError? error;
  final List<String> permissionNames;
  final bool isBiometricAvailable;
  final String? biometricOwnerEmail;
  final bool isBiometricActive;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    List<String>? permissionNames,
    this.isBiometricAvailable = false,
    this.biometricOwnerEmail,
    this.isBiometricActive = false,
  }) : permissionNames = permissionNames ?? [];

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    AuthError? error,
    List<String>? permissionNames,
    bool? isBiometricAvailable,
    String? biometricOwnerEmail,
    bool? isBiometricActive,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionNames: permissionNames ?? this.permissionNames,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      biometricOwnerEmail: biometricOwnerEmail ?? this.biometricOwnerEmail,
      isBiometricActive: isBiometricActive ?? this.isBiometricActive,
    );
  }

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
      isBiometricActive: ownerEmail != null,
    );
  }

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
      debugPrint('❌ DioException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: _mapDioErrorToAuthError(e),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error during login: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: AuthError
            .invalidCredentials, // نتركه unknown ليتم التعامل معه في الشاشة
      );
    }
  }

  // AuthError _mapDioErrorToAuthError(DioException e) {
  //   final statusCode = e.response?.statusCode;
  //   final responseData = e.response?.data;

  //   // 1. فحص خطأ ngrok
  //   try {
  //     if (statusCode == 404 &&
  //         e.response?.headers.map != null &&
  //         e.response!.headers.map['ngrok-error-code'] != null) {
  //       return AuthError.serverUnavailable;
  //     }
  //   } catch (_) {}

  //   // 2. أخطاء الشبكة
  //   if (e.type == DioExceptionType.connectionError ||
  //       e.type == DioExceptionType.connectionTimeout ||
  //       e.type == DioExceptionType.receiveTimeout) {
  //     return AuthError.serverUnavailable;
  //   }

  //   // 3. أخطاء 422 (تحقق من صحة البيانات)
  //   if (statusCode == 422) {
  //     String? fieldError;
  //     if (responseData is Map<String, dynamic>) {
  //       final errors = responseData['errors'];
  //       if (errors is Map && errors.isNotEmpty) {
  //         final firstValue = errors.values.first;
  //         fieldError = (firstValue is List && firstValue.isNotEmpty)
  //             ? firstValue.first.toString()
  //             : firstValue.toString();
  //       } else if (errors is String && errors.isNotEmpty) {
  //         fieldError = errors;
  //       }
  //     }

  //     // تحقق من رسائل محددة
  //     if (fieldError != null) {
  //       if (fieldError.contains('email field is required') ||
  //           fieldError.contains('email field does not exist')) {
  //         return AuthError.emailRequired;
  //       }
  //       if (fieldError.contains('valid email')) {
  //         return AuthError.emailInvalid;
  //       }
  //       if (fieldError.contains('password')) {
  //         return fieldError.contains('min') ||
  //                 fieldError.contains('8 characters')
  //             ? AuthError.passwordTooShort
  //             : AuthError.passwordRequired;
  //       }
  //     }

  //     // لأي خطأ 422 آخر، نعتبره بيانات دخول خاطئة
  //     return AuthError.invalidCredentials;
  //   }

  //   // 4. أي خطأ 4xx آخر
  //   if (statusCode != null && statusCode >= 400 && statusCode < 500) {
  //     return AuthError.invalidCredentials;
  //   }

  //   // 5. أخطاء الخادم
  //   if (statusCode != null && statusCode >= 500) {
  //     return AuthError.serverError;
  //   }

  //   // 6. غير معروف
  //   return AuthError.unknown;
  // }
  AuthError _mapDioErrorToAuthError(DioException e) {
    final statusCode = e.response?.statusCode;

    // 1. فحص خطأ ngrok
    try {
      if (statusCode == 404 &&
          e.response?.headers.map != null &&
          e.response!.headers.map['ngrok-error-code'] != null) {
        return AuthError.serverUnavailable;
      }
    } catch (_) {}

    // 2. أخطاء الشبكة
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AuthError.serverUnavailable;
    }

    // 3. أي خطأ 4xx (بما في ذلك 422) نعتبره بيانات اعتماد خاطئة
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return AuthError.invalidCredentials;
    }

    // 4. أخطاء الخادم
    if (statusCode != null && statusCode >= 500) {
      return AuthError.serverError;
    }

    // 5. غير معروف
    return AuthError.unknown;
  }

  Future<AuthError?> enableBiometricWithPassword(
      String email, String password) async {
    final owner = state.biometricOwnerEmail;
    if (owner != null && owner != email) {
      return AuthError.unknown;
    }

    try {
      await _authRepository.login(email, password);
      await _storage.write(_keyBiometricEmail, email);
      await _storage.write(_keyBiometricPassword, password);
      state = state.copyWith(
        biometricOwnerEmail: email,
        isBiometricActive: true,
      );
      return null;
    } on DioException catch (e) {
      return _mapDioErrorToAuthError(e);
    } catch (e) {
      return AuthError.unknown;
    }
  }

  Future<void> disableBiometric() async {
    try {
      await _storage.delete(_keyBiometricEmail);
      await _storage.delete(_keyBiometricPassword);
      state = state.copyWith(
        biometricOwnerEmail: null,
        isBiometricActive: false,
      );
    } catch (e) {
      debugPrint('Error disabling biometric: $e');
    }
  }

  Future<AuthError?> replaceBiometricOwner(
      String email, String password) async {
    try {
      await _authRepository.login(email, password);
      await _storage.write(_keyBiometricEmail, email);
      await _storage.write(_keyBiometricPassword, password);
      state = state.copyWith(
        biometricOwnerEmail: email,
        isBiometricActive: true,
      );
      return null;
    } on DioException catch (e) {
      return _mapDioErrorToAuthError(e);
    } catch (e) {
      return AuthError.unknown;
    }
  }

  /// محاولة الدخول بالبصمة.
  /// تُرجع `true` إذا نجح الدخول، و`false` إذا فشلت البصمة أو أُلغيت.
  Future<bool> biometricLogin() async {
    final email = await _storage.read(_keyBiometricEmail);
    final password = await _storage.read(_keyBiometricPassword);

    if (email == null || password == null) {
      // لا نضع خطأ في الحالة حتى لا يظهر SnackBar
      return false;
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'استخدم بصمتك لتسجيل الدخول كـ $email',
    );
    if (!authenticated) {
      // المستخدم ألغى البصمة أو فشلت، لا نضع خطأ
      return false;
    }

    // تسجيل الدخول بالبيانات المخزنة
    await login(email, password);
    // login ستُحدّث الحالة، نتحقق إذا نجح
    return state.user != null;
  }

  // Future<void> logout() async {
  //   try {
  //     await _authRepository.logout();
  //   } catch (_) {}
  //   await _storage.delete('access_token');
  //   await _storage.delete('refresh_token');
  //   final ownerEmail = await _storage.read(_keyBiometricEmail);
  //   final biometricAvailable = await _biometricService.isBiometricAvailable();
  //   state = AuthState(
  //     biometricOwnerEmail: ownerEmail,
  //     isBiometricAvailable: biometricAvailable,
  //     isBiometricActive: ownerEmail != null,
  //   );
  // }
  Future<void> logout() async {
    try {
      await _authRepository.logout().timeout(const Duration(seconds: 3));
    } catch (_) {
      // تجاهل أي خطأ من الخادم
    }
    await _storage.delete('access_token');
    await _storage.delete('refresh_token');
    final ownerEmail = await _storage.read(_keyBiometricEmail);
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    state = AuthState(
      biometricOwnerEmail: ownerEmail,
      isBiometricAvailable: biometricAvailable,
      isBiometricActive: ownerEmail != null,
    );
  }

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
final isBiometricOwnerProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((s) => s.isBiometricActive));
});

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
