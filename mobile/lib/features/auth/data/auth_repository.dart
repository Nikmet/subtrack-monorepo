import '../../../api/generated/openapi_client.dart';
import '../../../core/models/auth_tokens.dart';
import '../../../core/models/session_user.dart';
import '../../../core/storage/secure_token_storage.dart';

class AuthRepository {
  AuthRepository({
    required GeneratedApiClient api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final GeneratedApiClient _api;
  final TokenStorage _tokenStorage;

  Future<SessionUser> login({required String email, required String password}) async {
    final data = await _api.authLogin(email: email, password: password);
    return _hydrateSessionFromAuthPayload(data);
  }

  Future<SessionUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _api.authRegister(name: name, email: email, password: password);
    return _hydrateSessionFromAuthPayload(data);
  }

  Future<SessionUser> loadMe() async {
    final data = await _api.authMe();
    if (data is! Map<String, dynamic> || data['user'] is! Map<String, dynamic>) {
      throw StateError('Invalid /auth/me response');
    }
    return SessionUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<SessionUser> refreshSession() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null || tokens.refreshToken.isEmpty) {
      throw StateError('No refresh token');
    }

    final data = await _api.authRefresh(refreshToken: tokens.refreshToken);
    return _hydrateSessionFromAuthPayload(data);
  }

  Future<void> logout() async {
    final tokens = await _tokenStorage.read();
    if (tokens != null && tokens.refreshToken.isNotEmpty) {
      await _api.authLogout(refreshToken: tokens.refreshToken);
    }
    await _tokenStorage.clear();
  }

  Future<AuthTokens?> readTokens() => _tokenStorage.read();

  Future<void> clearTokens() => _tokenStorage.clear();

  Future<SessionUser> _hydrateSessionFromAuthPayload(dynamic data) async {
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid auth response payload');
    }

    final userRaw = data['user'];
    if (userRaw is! Map<String, dynamic>) {
      throw StateError('Missing user in auth response');
    }

    final tokenRaw = data['tokenPair'];
    if (tokenRaw is Map<String, dynamic>) {
      await _tokenStorage.write(AuthTokens.fromJson(tokenRaw));
    }

    return SessionUser.fromJson(userRaw);
  }
}
