import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/widgets/profile_tab_shell.dart';
import '../../../core/models/api_failure.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../settings/presentation/settings_widgets.dart';

final NumberFormat _pendingRubFormatter = NumberFormat('#,##0', 'ru_RU');

class PendingSubscriptionsScreen extends ConsumerStatefulWidget {
  const PendingSubscriptionsScreen({
    super.key,
    this.toastType,
    this.toastName,
  });

  final String? toastType;
  final String? toastName;

  @override
  ConsumerState<PendingSubscriptionsScreen> createState() => _PendingSubscriptionsScreenState();
}

class _PendingSubscriptionsScreenState extends ConsumerState<PendingSubscriptionsScreen> {
  bool _loading = true;
  bool _toastShown = false;
  String? _error;
  List<_PendingItem> _items = const <_PendingItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showInitialToastIfNeeded();
  }

  void _showInitialToastIfNeeded() {
    if (_toastShown || widget.toastType != 'submitted') {
      return;
    }
    _toastShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final safeName = widget.toastName?.trim().isNotEmpty == true ? widget.toastName!.trim() : 'Подписка';
      showSettingsSnackBar(context, '$safeName отправлена на модерацию.');
      context.replace('/subscriptions/pending');
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ref.read(apiClientProvider).getData('/user-subscriptions/pending');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = asMapList(raw).map(_PendingItem.fromJson).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is ApiFailure ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileTabShell(
      location: '/subscriptions/pending',
      child: Builder(
        builder: (context) {
          if (_loading) {
            return const SettingsLoadingView();
          }
          if (_error != null) {
            return SettingsErrorView(
              message: _error ?? 'Не удалось загрузить заявки.',
              onRetry: _load,
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 112),
              children: <Widget>[
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFDDE5EF)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 40,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => context.go('/profile'),
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF9EABBC),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Мои заявки',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF112840),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD6E0EC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'У вас пока нет заявок на публикацию.',
                          style: TextStyle(
                            color: Color(0xFF3F5168),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SettingsActionButton(
                          text: 'Создать новую подписку',
                          backgroundColor: const Color(0xFFDFF8FB),
                          textColor: const Color(0xFF0E7386),
                          onTap: () => context.go('/subscriptions/new'),
                          height: 38,
                          alignment: Alignment.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PendingCard(item: item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.item,
  });

  final _PendingItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E1EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PendingIcon(name: item.name, imageUrl: item.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xFF10233F),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.categoryName} • ${_formatRub(item.price)} • ${_formatPendingPeriodLabel(item.period)}',
                  style: const TextStyle(
                    color: Color(0xFF7A8DA5),
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status.backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.status.label.toUpperCase(),
                    style: TextStyle(
                      color: item.status.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
                if (item.moderationComment != null && item.moderationComment!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Комментарий: ${item.moderationComment!.trim()}',
                    style: const TextStyle(
                      color: Color(0xFF5A6F89),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingIcon extends StatelessWidget {
  const _PendingIcon({
    required this.name,
    required this.imageUrl,
  });

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first).toUpperCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 42,
        height: 42,
        child: imageUrl.isEmpty
            ? Container(
                color: const Color(0xFFE8ECF2),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF8493A8),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE8ECF2),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF8493A8),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PendingItem {
  const _PendingItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.categoryName,
    required this.price,
    required this.period,
    required this.status,
    required this.moderationComment,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String categoryName;
  final num price;
  final int period;
  final _PendingStatus status;
  final String? moderationComment;

  factory _PendingItem.fromJson(Map<String, dynamic> json) {
    return _PendingItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['imgLink'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
      price: json['price'] is num ? json['price'] as num : num.tryParse((json['price'] ?? 0).toString()) ?? 0,
      period: int.tryParse((json['period'] ?? 1).toString()) ?? 1,
      status: _PendingStatus.fromValue((json['status'] ?? 'PENDING').toString()),
      moderationComment: json['moderationComment']?.toString(),
    );
  }
}

class _PendingStatus {
  const _PendingStatus._({
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String value;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  static const _PendingStatus pending = _PendingStatus._(
    value: 'PENDING',
    label: 'На модерации',
    backgroundColor: Color(0xFFF6EDCC),
    textColor: Color(0xFF8B6E12),
  );

  static const _PendingStatus published = _PendingStatus._(
    value: 'PUBLISHED',
    label: 'Опубликовано',
    backgroundColor: Color(0xFFDAF8E8),
    textColor: Color(0xFF0F7A3F),
  );

  static const _PendingStatus rejected = _PendingStatus._(
    value: 'REJECTED',
    label: 'Отклонено',
    backgroundColor: Color(0xFFFFE6EA),
    textColor: Color(0xFFBD2D45),
  );

  static _PendingStatus fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'PUBLISHED':
        return published;
      case 'REJECTED':
        return rejected;
      default:
        return pending;
    }
  }
}

String _formatRub(num value) => '${_pendingRubFormatter.format(value.round())} ₽';

String _formatPendingPeriodLabel(int period) {
  final safe = period < 1 ? 1 : period;
  if (safe == 1) {
    return 'Ежемесячно';
  }
  if (safe == 12) {
    return 'Раз в год';
  }
  return 'Раз в $safe ${_monthsWord(safe)}';
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
