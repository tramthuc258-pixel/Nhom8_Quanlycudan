import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu JWT bằng kho bảo mật của hệ điều hành thay vì giữ trong bộ nhớ.
class AuthSessionStore {
  const AuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'homie_access_token';
  static const _refreshTokenKey = 'homie_refresh_token';
  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) => Future.wait<void>([
    _storage.write(key: _accessTokenKey, value: accessToken),
    _storage.write(key: _refreshTokenKey, value: refreshToken),
  ]);

  Future<void> clear() => Future.wait<void>([
    _storage.delete(key: _accessTokenKey),
    _storage.delete(key: _refreshTokenKey),
  ]);
}
