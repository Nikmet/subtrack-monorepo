import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/profile_tab_shell.dart';
import '../../../core/models/api_failure.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../settings/presentation/settings_widgets.dart';
import 'notifications_formatters.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _loading = true;
  bool _clearing = false;
  String? _error;
  List<_NotificationItem> _items = const <_NotificationItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ref.read(apiClientProvider).getData('/notifications', query: <String, dynamic>{'limit': 80});
      if (!mounted) {
        return;
      }
      setState(() {
        _items = asMapList(raw).map(_NotificationItem.fromJson).toList();
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

  Future<void> _clear() async {
    if (_items.isEmpty || _clearing) {
      return;
    }

    setState(() {
      _clearing = true;
    });

    try {
      await ref.read(apiClientProvider).deleteData('/notifications', body: <String, dynamic>{});
      await _load();
    } catch (error) {
      if (mounted) {
        showSettingsSnackBar(
          context,
          error is ApiFailure ? error.message : 'Не удалось очистить уведомления.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _clearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileTabShell(
      location: '/notifications',
      child: Builder(
        builder: (context) {
          if (_loading) {
            return const SettingsLoadingView();
          }
          if (_error != null) {
            return SettingsErrorView(
              message: _error ?? 'Не удалось загрузить уведомления.',
              onRetry: _load,
            );
          }

          return Column(
            children: <Widget>[
              Container(
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F8FC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFDFE6F0)),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Уведомления',
                        style: TextStyle(
                          color: Color(0xFF0F2742),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: (_items.isEmpty || _clearing) ? null : _clear,
                      child: Text(
                        _clearing ? 'Очистка...' : 'Очистить',
                        style: TextStyle(
                          color: (_items.isEmpty || _clearing) ? const Color(0xFF9FB0C4) : const Color(0xFF22B8CE),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 112),
                    children: <Widget>[
                      if (_items.isNotEmpty)
                        ..._items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _NotificationCard(item: item),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const _NotificationsBottomState(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
  });

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBE3EE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F111E30),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.kind.backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(
              item.kind.icon,
              size: 28,
              color: item.kind.iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Color(0xFF102642),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatNotificationRelative(item.createdAt).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF95A8C0),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: Color(0xFF62768F),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsBottomState extends StatelessWidget {
  const _NotificationsBottomState();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      margin: const EdgeInsets.only(top: 8),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2F7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: Color(0xFF7F8DA0),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Все уведомления просмотрены',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC3CFDE),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final _NotificationKind kind;
  final String title;
  final String message;
  final DateTime createdAt;

  factory _NotificationItem.fromJson(Map<String, dynamic> json) {
    return _NotificationItem(
      id: (json['id'] ?? '').toString(),
      kind: _NotificationKind.fromValue((json['kind'] ?? 'neutral').toString()),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class _NotificationKind {
  const _NotificationKind._({
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  static const _NotificationKind success = _NotificationKind._(
    value: 'success',
    icon: Icons.check_circle_outline_rounded,
    backgroundColor: Color(0xFFE7F6EF),
    iconColor: Color(0xFF17BA4C),
  );

  static const _NotificationKind info = _NotificationKind._(
    value: 'info',
    icon: Icons.access_time_rounded,
    backgroundColor: Color(0xFFE5EFFC),
    iconColor: Color(0xFF3B82F6),
  );

  static const _NotificationKind warning = _NotificationKind._(
    value: 'warning',
    icon: Icons.error_outline_rounded,
    backgroundColor: Color(0xFFF8EFE2),
    iconColor: Color(0xFFF97316),
  );

  static const _NotificationKind neutral = _NotificationKind._(
    value: 'neutral',
    icon: Icons.notifications_none_rounded,
    backgroundColor: Color(0xFFEEF2F6),
    iconColor: Color(0xFF7F8DA0),
  );

  static _NotificationKind fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'success':
        return success;
      case 'info':
        return info;
      case 'warning':
        return warning;
      default:
        return neutral;
    }
  }
}
