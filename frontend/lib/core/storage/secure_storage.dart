import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage();

  static Future<void> initialize() async {}

  static Future<void> setToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: AppConfig.tokenKey);
  }

  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: AppConfig.refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConfig.refreshTokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
  }
}
