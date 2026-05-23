import 'package:laravel_flutter_app/core/network/api_client.dart';
import 'package:laravel_flutter_app/features/auth/data/models/token_model.dart';
import 'package:laravel_flutter_app/features/auth/data/models/user_model.dart';

abstract class IAuthRepository {
  /// يسجل الدخول ويعيد بيانات المستخدم مع التوكن
  Future<AuthResult> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getUser(); // لفحص صلاحية التوكن عند بدء التشغيل
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
  Future<AuthResult> login(String email, String password) async {
    final response = await _apiClient.post('login', data: {
      // تغيير المسار إلى login
      'email': email,
      'password': password,
    });

    final data = response.data['data']; // الوصول إلى حقل data
    final userJson = data['user'];
    final tokenJson = data['token'];

    final user = UserModel.fromJson(userJson);
    final token = TokenModel.fromJson(tokenJson);

    return AuthResult(user: user, token: token);
  }

  @override
  Future<UserModel> getUser() async {
    final response = await _apiClient.get('user'); // المسار /user
    final data = response.data['data'];
    // بعض إصدارات Laravel ترجع المستخدم مباشرة داخل data، وقد يكون كائن مستخدم
    return UserModel.fromJson(data);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post('logout'); // تغيير المسار إلى logout
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    final response = await _apiClient.post('refresh-token', data: {
      // refresh-token
      'refresh_token': refreshToken,
    });
    final data = response.data['data'];
    return TokenModel.fromJson(data);
  }
}
