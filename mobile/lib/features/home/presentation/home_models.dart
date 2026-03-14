typedef HomeCurrencyVm = String;

class HomeScreenDataVm {
  const HomeScreenDataVm({
    required this.currency,
    required this.currencyFallback,
    required this.userInitials,
    required this.userAvatarLink,
    required this.monthlyTotal,
    required this.subscriptionsCount,
    required this.subscriptions,
    required this.categoryStats,
    required this.categoryTotal,
    required this.cardStats,
    required this.cardTotal,
  });

  final HomeCurrencyVm currency;
  final bool currencyFallback;
  final String userInitials;
  final String? userAvatarLink;
  final double monthlyTotal;
  final int subscriptionsCount;
  final List<SubscriptionItemVm> subscriptions;
  final List<CategoryStatVm> categoryStats;
  final double categoryTotal;
  final List<CardStatVm> cardStats;
  final double cardTotal;

  factory HomeScreenDataVm.fromMap(Map<String, dynamic> map) {
    return HomeScreenDataVm(
      currency: _asCurrency(map['currency']),
      currencyFallback: map['currencyFallback'] == true,
      userInitials: _asString(map['userInitials']),
      userAvatarLink: _asNullableString(map['userAvatarLink']),
      monthlyTotal: _asDouble(map['monthlyTotal']),
      subscriptionsCount: _asInt(map['subscriptionsCount']),
      subscriptions: _asList(map['subscriptions'])
          .map((item) => SubscriptionItemVm.fromMap(item))
          .toList(),
      categoryStats: _asList(map['categoryStats'])
          .map((item) => CategoryStatVm.fromMap(item))
          .toList(),
      categoryTotal: _asDouble(map['categoryTotal']),
      cardStats: _asList(map['cardStats'])
          .map((item) => CardStatVm.fromMap(item))
          .toList(),
      cardTotal: _asDouble(map['cardTotal']),
    );
  }
}

class SubscriptionItemVm {
  const SubscriptionItemVm({
    required this.id,
    required this.price,
    required this.monthlyPrice,
    required this.period,
    required this.nextPaymentAt,
    required this.paymentMethodId,
    required this.paymentCardLabel,
    required this.typeName,
    required this.typeImage,
    required this.categoryName,
  });

  final String id;
  final double price;
  final double monthlyPrice;
  final int period;
  final DateTime? nextPaymentAt;
  final String? paymentMethodId;
  final String paymentCardLabel;
  final String typeName;
  final String typeImage;
  final String categoryName;

  factory SubscriptionItemVm.fromMap(Map<String, dynamic> map) {
    return SubscriptionItemVm(
      id: _asString(map['id']),
      price: _asDouble(map['price']),
      monthlyPrice: _asDouble(map['monthlyPrice']),
      period: _asInt(map['period']),
      nextPaymentAt: _asDateTime(map['nextPaymentAt']),
      paymentMethodId: _asNullableString(map['paymentMethodId']),
      paymentCardLabel:
          _asString(map['paymentCardLabel'], fallback: 'Автосписание'),
      typeName: _asString(map['typeName'], fallback: '-'),
      typeImage: _asString(map['typeImage']),
      categoryName: _asString(map['categoryName'], fallback: 'Прочее'),
    );
  }
}

class CategoryStatVm {
  const CategoryStatVm({
    required this.name,
    required this.amount,
    required this.share,
  });

  final String name;
  final double amount;
  final double share;

  factory CategoryStatVm.fromMap(Map<String, dynamic> map) {
    return CategoryStatVm(
      name: _asString(map['name'], fallback: 'Прочее'),
      amount: _asDouble(map['amount']),
      share: _asDouble(map['share']),
    );
  }
}

class CardStatVm {
  const CardStatVm({
    required this.label,
    required this.amount,
    required this.share,
    required this.subscriptionsCount,
  });

  final String label;
  final double amount;
  final double share;
  final int subscriptionsCount;

  factory CardStatVm.fromMap(Map<String, dynamic> map) {
    return CardStatVm(
      label: _asString(map['label'], fallback: 'Банк • ****'),
      amount: _asDouble(map['amount']),
      share: _asDouble(map['share']),
      subscriptionsCount: _asInt(map['subscriptionsCount']),
    );
  }
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }

  return const <Map<String, dynamic>>[];
}

int _asInt(dynamic value) {
  if (value is num) {
    return value.round();
  }

  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) {
    return fallback;
  }

  return text;
}

String _asCurrency(dynamic value) {
  final normalized = _asString(value, fallback: 'rub').toLowerCase();
  if (normalized == 'usd' || normalized == 'eur') {
    return normalized;
  }

  return 'rub';
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}
