import '../../../core/models/api_failure.dart';

class SettingsOverviewData {
  const SettingsOverviewData({
    required this.name,
    required this.email,
    required this.initials,
    required this.avatarLink,
    required this.defaultPaymentMethodLabel,
    required this.role,
  });

  final String name;
  final String email;
  final String initials;
  final String? avatarLink;
  final String defaultPaymentMethodLabel;
  final String role;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory SettingsOverviewData.fromJson(Map<String, dynamic> json) {
    return SettingsOverviewData(
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      initials: (json['initials'] ?? '').toString(),
      avatarLink: json['avatarLink']?.toString(),
      defaultPaymentMethodLabel: (json['defaultPaymentMethodLabel'] ?? '').toString(),
      role: (json['role'] ?? 'USER').toString(),
    );
  }
}

class SettingsProfileData {
  const SettingsProfileData({
    required this.name,
    required this.email,
    required this.avatarLink,
  });

  final String name;
  final String email;
  final String? avatarLink;

  factory SettingsProfileData.fromJson(Map<String, dynamic> json) {
    return SettingsProfileData(
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarLink: json['avatarLink']?.toString(),
    );
  }
}

class SettingsBank {
  const SettingsBank({
    required this.id,
    required this.name,
    required this.iconLink,
  });

  final String id;
  final String name;
  final String iconLink;

  factory SettingsBank.fromJson(Map<String, dynamic> json) {
    return SettingsBank(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      iconLink: (json['iconLink'] ?? '').toString(),
    );
  }
}

class SettingsPaymentMethod {
  const SettingsPaymentMethod({
    required this.id,
    required this.cardNumber,
    required this.bankId,
    required this.isDefault,
    required this.bankName,
    required this.bankIconLink,
    required this.subscriptionsCount,
  });

  final String id;
  final String cardNumber;
  final String bankId;
  final bool isDefault;
  final String bankName;
  final String bankIconLink;
  final int subscriptionsCount;

  factory SettingsPaymentMethod.fromJson(Map<String, dynamic> json) {
    final bank = json['bank'] is Map<String, dynamic> ? json['bank'] as Map<String, dynamic> : const <String, dynamic>{};
    final count = json['_count'] is Map<String, dynamic> ? json['_count'] as Map<String, dynamic> : const <String, dynamic>{};

    return SettingsPaymentMethod(
      id: (json['id'] ?? '').toString(),
      cardNumber: (json['cardNumber'] ?? '').toString(),
      bankId: (json['bankId'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
      bankName: (bank['name'] ?? '').toString(),
      bankIconLink: (bank['iconLink'] ?? '').toString(),
      subscriptionsCount: int.tryParse((count['subscriptions'] ?? 0).toString()) ?? 0,
    );
  }
}

String settingsInitials(String value) {
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

String formatPaymentMethodLabel(String bankName, String cardNumber) {
  final safeBank = bankName.trim().isEmpty ? 'Банк' : bankName.trim();
  final safeCard = cardNumber.trim().isEmpty ? '****' : cardNumber.trim();
  return '$safeBank • $safeCard';
}

String? validateProfileForm({
  required String name,
  required String email,
  required String avatarLink,
}) {
  if (name.trim().length < 2) {
    return 'Проверьте корректность имени, email и ссылки на аватар.';
  }

  final normalizedEmail = email.trim().toLowerCase();
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(normalizedEmail)) {
    return 'Проверьте корректность имени, email и ссылки на аватар.';
  }

  final avatar = avatarLink.trim();
  if (avatar.isNotEmpty) {
    final uri = Uri.tryParse(avatar);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Проверьте корректность имени, email и ссылки на аватар.';
    }
  }

  return null;
}

String mapProfileFailureToMessage(ApiFailure failure) {
  if (failure.code == 'CONFLICT' || failure.statusCode == 409) {
    return 'Пользователь с таким email уже существует.';
  }
  return 'Проверьте корректность имени, email и ссылки на аватар.';
}

String mapSecurityFailureToMessage(ApiFailure failure, String newPassword) {
  final message = failure.message.toLowerCase();
  if (message.contains('текущ') || message.contains('current')) {
    return 'Текущий пароль введен неверно.';
  }
  if (message.contains('совпад') || message.contains('match')) {
    return 'Новый пароль и подтверждение не совпадают.';
  }
  if (newPassword.length < 8) {
    return 'Новый пароль должен быть не короче 8 символов.';
  }
  return 'Заполните все поля формы.';
}

String mapPaymentMethodFailureToMessage(ApiFailure failure) {
  if (failure.code == 'PAYMENT_METHOD_EXISTS') {
    return 'Такой способ оплаты уже есть.';
  }
  if (failure.code == 'PAYMENT_METHOD_IN_USE') {
    return 'Нельзя удалить способ оплаты, который используется в подписках.';
  }
  if (failure.code == 'NOT_FOUND') {
    return 'Действие недоступно.';
  }
  return 'Введите корректное название способа оплаты.';
}
