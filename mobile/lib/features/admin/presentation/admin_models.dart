import 'package:intl/intl.dart';

final NumberFormat _adminRubFormatter = NumberFormat('#,##0', 'ru_RU');

class AdminOption<T> {
  const AdminOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class AdminAreaLinkData {
  const AdminAreaLinkData({
    required this.route,
    required this.title,
    required this.description,
  });

  final String route;
  final String title;
  final String description;
}

const List<AdminAreaLinkData> adminAreaLinks = <AdminAreaLinkData>[
  AdminAreaLinkData(
    route: '/admin/moderation',
    title: 'Очередь модерации',
    description: 'Проверка новых подписок, публикация и отклонение.',
  ),
  AdminAreaLinkData(
    route: '/admin/published',
    title: 'Опубликованные',
    description: 'Редактирование и удаление уже опубликованных подписок.',
  ),
  AdminAreaLinkData(
    route: '/admin/users',
    title: 'Пользователи',
    description: 'Блокировка и разблокировка пользователей.',
  ),
  AdminAreaLinkData(
    route: '/admin/banks',
    title: 'Банки',
    description: 'Справочник банков и их иконок для способов оплаты.',
  ),
];

const List<AdminOption<String>> adminCategoryOptions = <AdminOption<String>>[
  AdminOption(value: '', label: 'Все категории'),
  AdminOption(value: 'streaming', label: 'Стриминг'),
  AdminOption(value: 'music', label: 'Музыка'),
  AdminOption(value: 'games', label: 'Игры'),
  AdminOption(value: 'shopping', label: 'Покупки'),
  AdminOption(value: 'ai', label: 'AI'),
  AdminOption(value: 'finance', label: 'Финансы'),
  AdminOption(value: 'other', label: 'Прочее'),
];

const List<AdminOption<String>> adminPeriodFilterOptions =
    <AdminOption<String>>[
  AdminOption(value: '', label: 'Любой период'),
  AdminOption(value: '1', label: 'Ежемесячно'),
  AdminOption(value: '3', label: 'Раз в 3 месяца'),
  AdminOption(value: '6', label: 'Раз в 6 месяцев'),
  AdminOption(value: '12', label: 'Раз в год'),
];

const List<AdminOption<String>> adminRoleFilterOptions = <AdminOption<String>>[
  AdminOption(value: '', label: 'Все роли'),
  AdminOption(value: 'USER', label: 'Пользователь'),
  AdminOption(value: 'ADMIN', label: 'Администратор'),
];

const List<AdminOption<String>> adminBanFilterOptions = <AdminOption<String>>[
  AdminOption(value: '', label: 'Любой статус бана'),
  AdminOption(value: 'active', label: 'Активные'),
  AdminOption(value: 'banned', label: 'Заблокированные'),
];

const List<AdminOption<String>> adminPeriodEditorOptions =
    <AdminOption<String>>[
  AdminOption(value: '1', label: 'Ежемесячно'),
  AdminOption(value: '3', label: 'Раз в 3 месяца'),
  AdminOption(value: '6', label: 'Раз в 6 месяцев'),
  AdminOption(value: '12', label: 'Раз в год'),
];

String adminCategoryLabel(String value) {
  for (final option in adminCategoryOptions) {
    if (option.value == value) {
      return option.label;
    }
  }
  return 'Прочее';
}

String adminPeriodLabel(int period) {
  final safePeriod = period < 1 ? 1 : period;
  if (safePeriod == 1) {
    return 'Ежемесячно';
  }
  if (safePeriod == 12) {
    return 'Раз в год';
  }
  return 'Раз в $safePeriod ${_monthsWord(safePeriod)}';
}

String formatAdminRub(num value) =>
    '${_adminRubFormatter.format(value.round())} ₽';

String adminInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  return parts
      .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
      .join();
}

class AdminModerationItem {
  const AdminModerationItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.period,
    required this.authorName,
    required this.authorEmail,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final num price;
  final int period;
  final String authorName;
  final String authorEmail;

  factory AdminModerationItem.fromJson(Map<String, dynamic> json) {
    final createdByUser = json['createdByUser'] is Map<String, dynamic>
        ? json['createdByUser'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return AdminModerationItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['imgLink'] ?? '').toString(),
      category: (json['categoryName'] ??
              adminCategoryLabel((json['category'] ?? '').toString()))
          .toString(),
      price: json['price'] is num
          ? json['price'] as num
          : num.tryParse((json['price'] ?? 0).toString()) ?? 0,
      period: int.tryParse((json['period'] ?? 1).toString()) ?? 1,
      authorName: (createdByUser['name'] ?? 'Неизвестно').toString(),
      authorEmail: (createdByUser['email'] ?? '-').toString(),
    );
  }
}

class AdminPublishedItem {
  const AdminPublishedItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.period,
    required this.subscribersCount,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final num price;
  final int period;
  final int subscribersCount;

  factory AdminPublishedItem.fromJson(Map<String, dynamic> json) {
    return AdminPublishedItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['imgLink'] ?? '').toString(),
      category: (json['categoryName'] ??
              adminCategoryLabel((json['category'] ?? '').toString()))
          .toString(),
      price: json['price'] is num
          ? json['price'] as num
          : num.tryParse((json['price'] ?? 0).toString()) ?? 0,
      period: int.tryParse((json['period'] ?? 1).toString()) ?? 1,
      subscribersCount:
          int.tryParse((json['subscribersCount'] ?? 0).toString()) ?? 0,
    );
  }
}

class AdminUserItem {
  const AdminUserItem({
    required this.id,
    required this.name,
    required this.avatarLink,
    required this.email,
    required this.role,
    required this.isBanned,
    required this.banReason,
    required this.subscriptionsCount,
  });

  final String id;
  final String name;
  final String? avatarLink;
  final String email;
  final String role;
  final bool isBanned;
  final String? banReason;
  final int subscriptionsCount;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    return AdminUserItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarLink: json['avatarLink']?.toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'USER').toString(),
      isBanned: json['isBanned'] == true,
      banReason: json['banReason']?.toString(),
      subscriptionsCount:
          int.tryParse((json['subscriptionsCount'] ?? 0).toString()) ?? 0,
    );
  }
}

class AdminBankItem {
  const AdminBankItem({
    required this.id,
    required this.name,
    required this.iconLink,
    required this.paymentMethodsCount,
  });

  final String id;
  final String name;
  final String iconLink;
  final int paymentMethodsCount;

  factory AdminBankItem.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] is Map<String, dynamic>
        ? json['_count'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return AdminBankItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      iconLink: (json['iconLink'] ?? '').toString(),
      paymentMethodsCount:
          int.tryParse((count['paymentMethods'] ?? 0).toString()) ?? 0,
    );
  }
}

class AdminSubscriptionDetail {
  const AdminSubscriptionDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.period,
    required this.moderationComment,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String price;
  final String period;
  final String moderationComment;

  factory AdminSubscriptionDetail.fromJson(
      String id, Map<String, dynamic> json) {
    return AdminSubscriptionDetail(
      id: id,
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['imgLink'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      period: (json['period'] ?? '1').toString(),
      moderationComment: (json['moderationComment'] ?? '').toString(),
    );
  }
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
