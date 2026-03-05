class ApiFailure implements Exception {
  const ApiFailure({
    required this.statusCode,
    required this.code,
    required this.message,
    this.requestId,
    this.details = const <String, dynamic>{},
  });

  final int statusCode;
  final String code;
  final String message;
  final String? requestId;
  final Map<String, dynamic> details;

  bool get isUnauthorized => code == 'UNAUTHORIZED' || statusCode == 401;
  bool get isBanned => code == 'BANNED';

  factory ApiFailure.fromResponse({required int statusCode, required dynamic data}) {
    final payload = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final error = payload['error'] is Map<String, dynamic>
        ? payload['error'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ApiFailure(
      statusCode: statusCode,
      code: (error['code'] ?? 'INTERNAL_ERROR').toString(),
      message: (error['message'] ?? 'Не удалось выполнить запрос к API.').toString(),
      requestId: payload['requestId']?.toString(),
      details: error['details'] is Map<String, dynamic>
          ? error['details'] as Map<String, dynamic>
          : const <String, dynamic>{},
    );
  }

  @override
  String toString() => 'ApiFailure($statusCode, $code, $message, requestId: $requestId)';
}
