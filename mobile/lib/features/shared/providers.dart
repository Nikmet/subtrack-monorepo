import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/openapi_client.dart';
import '../../core/env/app_env.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/session_events.dart';
import '../../core/storage/secure_token_storage.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_controller.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((_) {
  return AppEnvironment.fromDefines();
});

final sessionEventsProvider = Provider<SessionEvents>((_) => SessionEvents());

final tokenStorageProvider = Provider<TokenStorage>((_) => SecureTokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final sessionEvents = ref.watch(sessionEventsProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: Duration(milliseconds: env.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: env.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: env.connectTimeoutMs),
      headers: const {
        'content-type': 'application/json',
      },
    ),
  );

  final refreshDio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: Duration(milliseconds: env.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: env.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: env.connectTimeoutMs),
      headers: const {
        'content-type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshDio: refreshDio,
      retryDio: dio,
      onSessionExpired: sessionEvents.notifySessionExpired,
    ),
  );

  return dio;
});

final apiClientProvider = Provider<GeneratedApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return GeneratedApiClient(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthViewState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));

  final events = ref.read(sessionEventsProvider);
  events.onSessionExpired = controller.markSessionExpired;

  controller.bootstrap();
  return controller;
});
