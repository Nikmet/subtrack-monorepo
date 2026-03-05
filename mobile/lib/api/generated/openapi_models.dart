import 'package:dio/dio.dart';

import '../../core/models/auth_tokens.dart';
import '../../core/models/session_user.dart';

typedef JsonMap = Map<String, dynamic>;

class ApiEnvelope<T> {
  const ApiEnvelope({required this.data, this.meta = const <String, dynamic>{}});

  final T data;
  final JsonMap meta;

  factory ApiEnvelope.fromJson(JsonMap json, T Function(dynamic raw) mapper) {
    return ApiEnvelope<T>(
      data: mapper(json['data']),
      meta: json['meta'] is JsonMap ? json['meta'] as JsonMap : const <String, dynamic>{},
    );
  }
}

class AuthSessionPayload {
  const AuthSessionPayload({required this.user, required this.tokenPair});

  final SessionUser? user;
  final AuthTokens? tokenPair;

  factory AuthSessionPayload.fromJson(dynamic raw) {
    final data = raw is JsonMap ? raw : <String, dynamic>{};
    final userRaw = data['user'];
    final tokenRaw = data['tokenPair'];

    return AuthSessionPayload(
      user: userRaw is JsonMap ? SessionUser.fromJson(userRaw) : null,
      tokenPair: tokenRaw is JsonMap ? AuthTokens.fromJson(tokenRaw) : null,
    );
  }
}

class ApiResponseException implements Exception {
  const ApiResponseException(this.response);

  final Response<dynamic> response;
}
