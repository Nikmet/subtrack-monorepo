class HomeScreenDataVm {
  const HomeScreenDataVm({
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

  final String userInitials;
  final String? userAvatarLink;
  final int monthlyTotal;
  final int subscriptionsCount;
  final List<SubscriptionItemVm> subscriptions;
  final List<CategoryStatVm> categoryStats;
  final int categoryTotal;
  final List<CardStatVm> cardStats;
  final int cardTotal;

  factory HomeScreenDataVm.fromMap(Map<String, dynamic> map) {
    return HomeScreenDataVm(
      userInitials: _asString(map['userInitials']),
      userAvatarLink: _asNullableString(map['userAvatarLink']),
      monthlyTotal: _asInt(map['monthlyTotal']),
      subscriptionsCount: _asInt(map['subscriptionsCount']),
      subscriptions: _asList(map['subscriptions'])
          .map((item) => SubscriptionItemVm.fromMap(item))
          .toList(),
      categoryStats: _asList(map['categoryStats'])
          .map((item) => CategoryStatVm.fromMap(item))
          .toList(),
      categoryTotal: _asInt(map['categoryTotal']),
      cardStats: _asList(map['cardStats'])
          .map((item) => CardStatVm.fromMap(item))
          .toList(),
      cardTotal: _asInt(map['cardTotal']),
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
    required this.typeName,
    required this.typeImage,
    required this.categoryName,
  });

  final String id;
  final int price;
  final int monthlyPrice;
  final int period;
  final DateTime? nextPaymentAt;
  final String typeName;
  final String typeImage;
  final String categoryName;

  factory SubscriptionItemVm.fromMap(Map<String, dynamic> map) {
    return SubscriptionItemVm(
      id: _asString(map['id']),
      price: _asInt(map['price']),
      monthlyPrice: _asInt(map['monthlyPrice']),
      period: _asInt(map['period']),
      nextPaymentAt: _asDateTime(map['nextPaymentAt']),
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
  final int amount;
  final double share;

  factory CategoryStatVm.fromMap(Map<String, dynamic> map) {
    return CategoryStatVm(
      name: _asString(map['name'], fallback: 'Прочее'),
      amount: _asInt(map['amount']),
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
  final int amount;
  final double share;
  final int subscriptionsCount;

  factory CardStatVm.fromMap(Map<String, dynamic> map) {
    return CardStatVm(
      label: _asString(map['label'], fallback: 'Банк • ****'),
      amount: _asInt(map['amount']),
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
