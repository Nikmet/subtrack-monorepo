import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/features/notifications/presentation/notifications_formatters.dart';

void main() {
  test('formats relative notification time for minutes, hours and days', () {
    final now = DateTime(2026, 3, 14, 12, 0);

    expect(
      formatNotificationRelative(now.subtract(const Duration(seconds: 20)), now: now),
      'только что',
    );
    expect(
      formatNotificationRelative(now.subtract(const Duration(minutes: 5)), now: now),
      '5 минут назад',
    );
    expect(
      formatNotificationRelative(now.subtract(const Duration(hours: 3)), now: now),
      '3 часа назад',
    );
    expect(
      formatNotificationRelative(now.subtract(const Duration(days: 8)), now: now),
      '8 дней назад',
    );
  });
}
