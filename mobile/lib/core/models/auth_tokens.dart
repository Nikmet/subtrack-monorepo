class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSec,
    required this.refreshTokenExpiresInSec,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSec;
  final int refreshTokenExpiresInSec;

  Map<String, String> toStorageMap() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessTokenExpiresInSec': accessTokenExpiresInSec.toString(),
        'refreshTokenExpiresInSec': refreshTokenExpiresInSec.toString(),
      };

  factory AuthTokens.fromStorageMap(Map<String, String> values) {
    return AuthTokens(
      accessToken: values['accessToken'] ?? '',
      refreshToken: values['refreshToken'] ?? '',
      accessTokenExpiresInSec: int.tryParse(values['accessTokenExpiresInSec'] ?? '') ?? 0,
      refreshTokenExpiresInSec: int.tryParse(values['refreshTokenExpiresInSec'] ?? '') ?? 0,
    );
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      accessTokenExpiresInSec: ((json['accessTokenExpiresInSec'] as num?) ?? 0).toInt(),
      refreshTokenExpiresInSec: ((json['refreshTokenExpiresInSec'] as num?) ?? 0).toInt(),
    );
  }
}
