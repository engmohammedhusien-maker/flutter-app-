import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// واجهة مجردة لخدمة التخزين الآمن
abstract class ISecureStorageHelper {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

/// تنفيذ خدمة التخزين باستخدام flutter_secure_storage
class SecureStorageHelper implements ISecureStorageHelper {
  final FlutterSecureStorage _storage;

  SecureStorageHelper()
      : _storage = const FlutterSecureStorage(
          // إعدادات الأمان لأنظمة أندرويد و iOS
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions:
              IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
