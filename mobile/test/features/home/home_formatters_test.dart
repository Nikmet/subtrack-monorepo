import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/features/home/presentation/home_formatters.dart';

void main() {
  test('formats money for rub', () {
    expect(formatMoney(1504, 'rub'), '1 504 ₽');
    expect(formatMoney(1504.75, 'rub'), '1 505 ₽');
  });

  test('formats money for usd and eur', () {
    expect(formatMoney(16.5, 'usd'), r'$16,50');
    expect(formatMoney(17.25, 'eur'), '€17,25');
  });

  test('formats subscription count and period labels', () {
    expect(formatSubscriptionCount(1), '1 активная подписка');
    expect(formatSubscriptionCount(3), '3 активные подписки');
    expect(formatSubscriptionCount(8), '8 активных подписок');
    expect(formatPeriodLabel(1), 'Ежемесячно');
    expect(formatPeriodLabel(3), 'Раз в 3 месяца');
    expect(formatPeriodLabel(12), 'Раз в год');
  });
}
