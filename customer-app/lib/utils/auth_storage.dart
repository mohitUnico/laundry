import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  static Future<String?> getAuthToken() async {
    return _storage.read(key: _authTokenKey);
  }

  static Future<void> setAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<void> clearAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  static Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> clearSession() async {
    await Future.wait([
      clearAuthToken(),
      clearRefreshToken(),
    ]);
  }
}


