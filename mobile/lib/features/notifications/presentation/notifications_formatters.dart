String formatNotificationRelative(DateTime createdAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(createdAt);

  if (diff.inMinutes < 1) {
    return 'только что';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} ${_plural(diff.inMinutes, 'минута', 'минуты', 'минут')} назад';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} ${_plural(diff.inHours, 'час', 'часа', 'часов')} назад';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} ${_plural(diff.inDays, 'день', 'дня', 'дней')} назад';
  }

  const months = <String>[
    'янв.',
    'февр.',
    'мар.',
    'апр.',
    'мая',
    'июн.',
    'июл.',
    'авг.',
    'сент.',
    'окт.',
    'нояб.',
    'дек.',
  ];
  return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
}

String _plural(int value, String one, String twoToFour, String many) {
  final mod10 = value % 10;
  final mod100 = value % 100;

  if (mod10 == 1 && mod100 != 11) {
    return one;
  }
  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return twoToFour;
  }
  return many;
}
