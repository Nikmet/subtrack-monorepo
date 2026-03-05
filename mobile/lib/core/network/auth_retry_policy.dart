bool shouldAttemptRefresh({
  required int? statusCode,
  required bool retried,
  required String requestPath,
}) {
  final isRefreshRequest = requestPath.contains('/api/v1/auth/refresh');
  return statusCode == 401 && !retried && !isRefreshRequest;
}
