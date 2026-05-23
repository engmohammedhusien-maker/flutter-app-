import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/security/secure_storage_helper.dart';

abstract class IApiClient {
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters});
  Future<Response> post(String path, {dynamic data});
  Future<Response> put(String path, {dynamic data});
  Future<Response> delete(String path);
}

class ApiClient implements IApiClient {
  final Dio _dio;
  final ISecureStorageHelper _storage;

  ApiClient({required ISecureStorageHelper storage})
      : _storage = storage,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://booting-manicure-headpiece.ngrok-free.dev/api/',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )) {
    _dio.interceptors.add(AuthInterceptor(_storage));
    _dio.interceptors.add(NgrokInterceptor());
    // أضف هذا المُعترض لطباعة كل الطلبات والردود
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  @override
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  @override
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  @override
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

class AuthInterceptor extends Interceptor {
  final ISecureStorageHelper _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

final secureStorageProvider = Provider<ISecureStorageHelper>((ref) {
  return SecureStorageHelper();
});

final apiClientProvider = Provider<IApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  // لم نعد نضيف MockInterceptor، الاتصال الحقيقي مباشرة
  return ApiClient(storage: storage);
});

// معترض ngrok
class NgrokInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // هذا السطر يضيف الترويسة المطلوبة لتجاوز صفحة التحذير
    options.headers['ngrok-skip-browser-warning'] = 'true';
    super.onRequest(options, handler); // لا تنسَ استدعاء handler.next(options)
  }
}
