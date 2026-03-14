import 'package:intl/intl.dart';

final NumberFormat _rubFormatter = NumberFormat('#,##0', 'ru_RU');
final NumberFormat _usdFormatter = NumberFormat('#,##0.00', 'ru_RU');
final NumberFormat _eurFormatter = NumberFormat('#,##0.00', 'ru_RU');
final DateFormat _nextPaymentDateFormatter = DateFormat('d MMM', 'ru_RU');

String formatMoney(num value, String currency) {
  if (currency == 'usd') {
    return '\$${_usdFormatter.format(value)}';
  }

  if (currency == 'eur') {
    return '€${_eurFormatter.format(value)}';
  }

  final rounded = value.round();
  return '${_rubFormatter.format(rounded)} ₽';
}

String formatRub(num value) {
  return formatMoney(value, 'rub');
}

String formatNextPayment(DateTime? value) {
  if (value == null) {
    return 'дата списания не указана';
  }

  return 'следующий платёж ${_nextPaymentDateFormatter.format(value)}';
}

String formatNextPaymentShort(DateTime? value) {
  if (value == null) {
    return 'Не указана';
  }

  return _nextPaymentDateFormatter.format(value);
}

String formatSubscriptionCount(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;

  if (mod10 == 1 && mod100 != 11) {
    return '$count активная подписка';
  }
  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return '$count активные подписки';
  }

  return '$count активных подписок';
}

String formatPeriodLabel(int period) {
  final safePeriod = period < 1 ? 1 : period;

  if (safePeriod == 1) {
    return 'Ежемесячно';
  }
  if (safePeriod == 12) {
    return 'Раз в год';
  }

  return 'Раз в $safePeriod ${_monthsWord(safePeriod)}';
}

String currencyLabel(String currency) {
  if (currency == 'usd') {
    return 'USD';
  }

  if (currency == 'eur') {
    return 'EUR';
  }

  return 'RUB';
}

String _monthsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;

  if (mod10 == 1 && mod100 != 11) {
    return 'месяц';
  }
  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return 'месяца';
  }

  return 'месяцев';
}
