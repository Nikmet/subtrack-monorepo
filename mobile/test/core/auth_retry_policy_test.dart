import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/core/network/auth_retry_policy.dart';

void main() {
  test('retry policy: refresh only for first 401 non-refresh request', () {
    expect(
      shouldAttemptRefresh(statusCode: 401, retried: false, requestPath: '/api/v1/home'),
      isTrue,
    );

    expect(
      shouldAttemptRefresh(statusCode: 401, retried: true, requestPath: '/api/v1/home'),
      isFalse,
    );

    expect(
      shouldAttemptRefresh(statusCode: 401, retried: false, requestPath: '/api/v1/auth/refresh'),
      isFalse,
    );

    expect(
      shouldAttemptRefresh(statusCode: 500, retried: false, requestPath: '/api/v1/home'),
      isFalse,
    );
  });
}
