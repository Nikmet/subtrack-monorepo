import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_tokens.dart';

abstract class TokenStorage {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'subtrack_access_token';
  static const _refreshKey = 'subtrack_refresh_token';
  static const _accessTtlKey = 'subtrack_access_token_ttl';
  static const _refreshTtlKey = 'subtrack_refresh_token_ttl';

  @override
  Future<AuthTokens?> read() async {
    final values = await _storage.readAll();
    final access = values[_accessKey];
    final refresh = values[_refreshKey];

    if (access == null || refresh == null || access.isEmpty || refresh.isEmpty) {
      return null;
    }

    return AuthTokens.fromStorageMap({
      'accessToken': access,
      'refreshToken': refresh,
      'accessTokenExpiresInSec': values[_accessTtlKey] ?? '0',
      'refreshTokenExpiresInSec': values[_refreshTtlKey] ?? '0',
    });
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    final mapped = tokens.toStorageMap();
    await _storage.write(key: _accessKey, value: mapped['accessToken']);
    await _storage.write(key: _refreshKey, value: mapped['refreshToken']);
    await _storage.write(key: _accessTtlKey, value: mapped['accessTokenExpiresInSec']);
    await _storage.write(key: _refreshTtlKey, value: mapped['refreshTokenExpiresInSec']);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _accessTtlKey);
    await _storage.delete(key: _refreshTtlKey);
  }
}
