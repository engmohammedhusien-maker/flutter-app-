import 'package:flutter/foundation.dart';
import 'package:laravel_flutter_app/core/network/api_client.dart';
import 'package:laravel_flutter_app/features/auth/data/models/token_model.dart';
import 'package:laravel_flutter_app/features/auth/data/models/user_model.dart';

abstract class IAuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<UserModel> getUser();
  Future<void> logout();
  Future<TokenModel> refreshToken(String refreshToken);
}

class AuthResult {
  final UserModel user;
  final TokenModel token;
  AuthResult({required this.user, required this.token});
}

class AuthRepository implements IAuthRepository {
  final IApiClient _apiClient;

  AuthRepository(this._apiClient);

  @override
  @override
  Future<AuthResult> login(String email, String password) async {
    final response = await _apiClient.post('login', data: {
      'email': email,
      'password': password,
    });

    debugPrint('✅ Login response data: ${response.data}');

    final Map<String, dynamic> responseData = response.data;
    final Map<String, dynamic> data = responseData['data'];
    final Map<String, dynamic> userJson = data['user'];

    // محاولة قراءة 'token' أولاً، ثم 'tokens'
    Map<String, dynamic>? tokenJson;
    if (data['token'] is Map<String, dynamic>) {
      tokenJson = data['token'];
    } else if (data['tokens'] is Map<String, dynamic>) {
      tokenJson = data['tokens'];
    } else {
      throw Exception('Response missing token field');
    }

    final user = UserModel.fromJson(userJson);
    final token = TokenModel.fromJson(tokenJson!);

    return AuthResult(user: user, token: token);
  }

  @override
  Future<UserModel> getUser() async {
    final response = await _apiClient.get('user');
    final data = response.data['data'];
    return UserModel.fromJson(data);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post('logout');
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    final response = await _apiClient.post('refresh-token', data: {
      'refresh_token': refreshToken,
    });
    final data = response.data['data'];
    return TokenModel.fromJson(data);
  }
}
