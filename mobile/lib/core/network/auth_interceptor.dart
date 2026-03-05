import 'dart:async';

import 'package:dio/dio.dart';

import '../models/auth_tokens.dart';
import 'auth_retry_policy.dart';
import '../storage/secure_token_storage.dart';

typedef SessionExpiredCallback = Future<void> Function();

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
    required Dio retryDio,
    required SessionExpiredCallback onSessionExpired,
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio,
        _retryDio = retryDio,
        _onSessionExpired = onSessionExpired;

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final Dio _retryDio;
  final SessionExpiredCallback _onSessionExpired;

  Completer<void>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _tokenStorage.read();
    final accessToken = tokens?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final retried = err.requestOptions.extra['__retried__'] == true;

    if (!shouldAttemptRefresh(
      statusCode: statusCode,
      retried: retried,
      requestPath: err.requestOptions.path,
    )) {
      handler.next(err);
      return;
    }

    try {
      await _ensureRefreshed();
      final retriedResponse = await _retryRequest(err.requestOptions);
      handler.resolve(retriedResponse);
    } catch (_) {
      await _tokenStorage.clear();
      await _onSessionExpired();
      handler.next(err);
    }
  }

  Future<void> _ensureRefreshed() async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return;
    }

    _refreshCompleter = Completer<void>();

    try {
      final current = await _tokenStorage.read();
      if (current == null || current.refreshToken.isEmpty) {
        throw StateError('No refresh token');
      }

      final response = await _refreshDio.post<dynamic>(
        '/api/v1/auth/refresh',
        data: {
          'refreshToken': current.refreshToken,
          'clientType': 'mobile',
        },
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw StateError('Invalid refresh response');
      }

      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid refresh payload');
      }

      final tokenPair = data['tokenPair'];
      if (tokenPair is! Map<String, dynamic>) {
        throw StateError('No token pair in refresh response');
      }

      await _tokenStorage.write(AuthTokens.fromJson(tokenPair));
      _refreshCompleter!.complete();
    } catch (error, stackTrace) {
      _refreshCompleter!.completeError(error, stackTrace);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final tokens = await _tokenStorage.read();
    final headers = Map<String, dynamic>.from(requestOptions.headers);

    if (tokens != null && tokens.accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }

    final options = requestOptions.copyWith(
      headers: headers,
      extra: <String, dynamic>{
        ...requestOptions.extra,
        '__retried__': true,
      },
    );

    return _retryDio.fetch<dynamic>(options);
  }
}
