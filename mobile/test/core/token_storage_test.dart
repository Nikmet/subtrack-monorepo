import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/core/models/auth_tokens.dart';

import '../support/in_memory_token_storage.dart';

void main() {
  test('TokenStorage write/read/clear', () async {
    final storage = InMemoryTokenStorage();

    const tokens = AuthTokens(
      accessToken: 'a',
      refreshToken: 'r',
      accessTokenExpiresInSec: 15,
      refreshTokenExpiresInSec: 30,
    );

    await storage.write(tokens);
    final read = await storage.read();

    expect(read, isNotNull);
    expect(read!.accessToken, 'a');
    expect(read.refreshToken, 'r');

    await storage.clear();
    final afterClear = await storage.read();
    expect(afterClear, isNull);
  });
}
