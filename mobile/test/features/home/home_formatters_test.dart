import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:subtrack_mobile/features/home/presentation/home_formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  test('formatRub formats values without fractional part and with ruble sign',
      () {
    expect(formatRub(1504).replaceAll(RegExp(r'\s'), ' '), '1 504 \u20BD');
    expect(formatRub(399.7), '400 \u20BD');
  });

  test('formatNextPayment formats date and handles null', () {
    final date = DateTime(2026, 3, 9);
    expect(formatNextPayment(date),
        '\u0441\u043B\u0435\u0434\u0443\u044E\u0449\u0438\u0439 \u043F\u043B\u0430\u0442\u0435\u0436 9 \u043C\u0430\u0440.');
    expect(formatNextPayment(null),
        '\u0434\u0430\u0442\u0430 \u0441\u043F\u0438\u0441\u0430\u043D\u0438\u044F \u043D\u0435 \u0443\u043A\u0430\u0437\u0430\u043D\u0430');
  });

  test('formatSubscriptionCount uses correct russian plural form', () {
    expect(formatSubscriptionCount(1),
        '1 \u0430\u043A\u0442\u0438\u0432\u043D\u0430\u044F \u043F\u043E\u0434\u043F\u0438\u0441\u043A\u0430');
    expect(formatSubscriptionCount(2),
        '2 \u0430\u043A\u0442\u0438\u0432\u043D\u044B\u0435 \u043F\u043E\u0434\u043F\u0438\u0441\u043A\u0438');
    expect(formatSubscriptionCount(5),
        '5 \u0430\u043A\u0442\u0438\u0432\u043D\u044B\u0445 \u043F\u043E\u0434\u043F\u0438\u0441\u043E\u043A');
    expect(formatSubscriptionCount(22),
        '22 \u0430\u043A\u0442\u0438\u0432\u043D\u044B\u0435 \u043F\u043E\u0434\u043F\u0438\u0441\u043A\u0438');
  });

  test('formatPeriodLabel maps period values to web-compatible labels', () {
    expect(formatPeriodLabel(1),
        '\u0415\u0436\u0435\u043C\u0435\u0441\u044F\u0447\u043D\u043E');
    expect(
        formatPeriodLabel(12), '\u0420\u0430\u0437 \u0432 \u0433\u043E\u0434');
    expect(formatPeriodLabel(3),
        '\u0420\u0430\u0437 \u0432 3 \u043C\u0435\u0441\u044F\u0446\u0430');
    expect(formatPeriodLabel(5),
        '\u0420\u0430\u0437 \u0432 5 \u043C\u0435\u0441\u044F\u0446\u0435\u0432');
  });
}
