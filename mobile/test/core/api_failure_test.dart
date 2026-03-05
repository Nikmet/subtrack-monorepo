import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/core/models/api_failure.dart';

void main() {
  test('ApiFailure parses envelope fields', () {
    final failure = ApiFailure.fromResponse(
      statusCode: 401,
      data: {
        'error': {
          'code': 'UNAUTHORIZED',
          'message': 'Unauthorized',
          'details': {'reason': 'token'},
        },
        'requestId': 'abc',
      },
    );

    expect(failure.statusCode, 401);
    expect(failure.code, 'UNAUTHORIZED');
    expect(failure.message, 'Unauthorized');
    expect(failure.requestId, 'abc');
    expect(failure.details['reason'], 'token');
  });

  test('ApiFailure fallback values', () {
    final failure = ApiFailure.fromResponse(statusCode: 500, data: null);

    expect(failure.code, 'INTERNAL_ERROR');
    expect(failure.message, isNotEmpty);
  });
}
