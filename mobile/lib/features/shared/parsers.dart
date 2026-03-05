import 'package:intl/intl.dart';

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return <Map<String, dynamic>>[];
}

String money(dynamic value) {
  final amount = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
  final formatted = NumberFormat('#,##0', 'ru_RU').format(amount.round());
  return '$formatted ?';
}

String monthParamNow() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  return '${now.year}-$month';
}
