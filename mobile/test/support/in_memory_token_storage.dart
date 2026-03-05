import 'package:subtrack_mobile/core/models/auth_tokens.dart';
import 'package:subtrack_mobile/core/storage/secure_token_storage.dart';

class InMemoryTokenStorage implements TokenStorage {
  AuthTokens? _tokens;

  @override
  Future<void> clear() async {
    _tokens = null;
  }

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async {
    _tokens = tokens;
  }
}
