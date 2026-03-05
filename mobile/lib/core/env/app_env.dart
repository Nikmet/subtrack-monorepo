class AppEnvironment {
  const AppEnvironment({
    required this.apiBaseUrl,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
  });

  final String apiBaseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  factory AppEnvironment.fromDefines() {
    const defaultApi = 'https://subtrack-server.vercel.app';
    const connectTimeout = int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: 15000,
    );
    const receiveTimeout = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 15000,
    );

    final api = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultApi,
    ).trim();

    return AppEnvironment(
      apiBaseUrl: api.isEmpty ? defaultApi : api,
      connectTimeoutMs: connectTimeout,
      receiveTimeoutMs: receiveTimeout,
    );
  }
}
