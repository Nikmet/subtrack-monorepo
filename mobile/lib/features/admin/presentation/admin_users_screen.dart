import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_failure.dart';
import '../../shared/parsers.dart';
import '../../shared/providers.dart';
import '../../settings/presentation/settings_widgets.dart';
import 'admin_models.dart';
import 'admin_widgets.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _role = '';
  String _ban = '';
  List<AdminUserItem> _users = const <AdminUserItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final query = <String, dynamic>{};
    if (_searchController.text.trim().isNotEmpty) {
      query['q'] = _searchController.text.trim();
    }
    if (_role.isNotEmpty) {
      query['role'] = _role;
    }
    if (_ban.isNotEmpty) {
      query['ban'] = _ban;
    }

    try {
      final raw = await ref
          .read(apiClientProvider)
          .getData('/admin/users', query: query);
      if (!mounted) {
        return;
      }
      setState(() {
        _users = asMapList(raw).map(AdminUserItem.fromJson).toList();
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

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _role = '';
      _ban = '';
    });
    _load();
  }

  Future<void> _banUser(AdminUserItem user) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFFF5F8FC),
          title: const Text('Причина блокировки'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: adminInputDecoration(hintText: 'Укажите причину'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Заблокировать'),
            ),
          ],
        );
      },
    );

    if (!mounted || reason == null) {
      return;
    }
    if (reason.isEmpty) {
      showSettingsSnackBar(context, 'Укажите причину блокировки.');
      return;
    }

    try {
      await ref.read(apiClientProvider).postData(
        '/admin/users/${user.id}/ban',
        body: <String, dynamic>{'reason': reason},
      );
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Пользователь заблокирован.');
      await _load();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось заблокировать пользователя.');
      }
    }
  }

  Future<void> _unbanUser(AdminUserItem user) async {
    try {
      await ref.read(apiClientProvider).postData(
        '/admin/users/${user.id}/unban',
        body: <String, dynamic>{},
      );
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Пользователь разблокирован.');
      await _load();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(
            context, 'Не удалось разблокировать пользователя.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminHeader(
            backText: '← В админ-панель',
            backRoute: '/admin',
            title: 'Пользователи',
          ),
          const SizedBox(height: 14),
          AdminFiltersPanel(
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: adminInputDecoration(
                  hintText: 'Поиск по имени или email',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('role-$_role'),
                initialValue: _role,
                decoration: adminInputDecoration(),
                items: adminRoleFilterOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _role = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('ban-$_ban'),
                initialValue: _ban,
                decoration: adminInputDecoration(),
                items: adminBanFilterOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _ban = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  SettingsActionButton(
                    text: 'Применить',
                    backgroundColor: const Color(0xFFDEF8E8),
                    textColor: const Color(0xFF0F7A3F),
                    onTap: _load,
                    height: 38,
                  ),
                  SettingsActionButton(
                    text: 'Сбросить',
                    backgroundColor: const Color(0xFFE2F1FF),
                    textColor: const Color(0xFF1F5D95),
                    onTap: _resetFilters,
                    height: 38,
                  ),
                ],
              ),
            ],
          ),
          const AdminSectionTitle('Пользователи', top: 10),
          Expanded(
            child: _loading
                ? const SettingsLoadingView()
                : _error != null
                    ? SettingsErrorView(
                        message:
                            _error ?? 'Не удалось загрузить пользователей.',
                        onRetry: _load,
                      )
                    : _users.isEmpty
                        ? const AdminEmptyText('Пользователи не найдены.')
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _users.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return _UserCard(
                                user: user,
                                onBan:
                                    user.isAdmin ? null : () => _banUser(user),
                                onUnban: user.isAdmin
                                    ? null
                                    : () => _unbanUser(user),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onBan,
    required this.onUnban,
  });

  final AdminUserItem user;
  final VoidCallback? onBan;
  final VoidCallback? onUnban;

  @override
  Widget build(BuildContext context) {
    final title = user.isAdmin ? '${user.name} • АДМИН' : user.name;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AdminIconBox(
                size: 38,
                radius: 10,
                imageUrl: user.avatarLink ?? '',
                fallbackText: adminInitials(user.name),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF112841),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            user.email,
            style: const TextStyle(
              color: Color(0xFF50657F),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Подписок: ${user.subscriptionsCount}',
            style: const TextStyle(
              color: Color(0xFF6B7F99),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          if (user.isAdmin)
            const Text(
              'Администраторы не блокируются.',
              style: TextStyle(
                color: Color(0xFF6B7F99),
                fontSize: 12,
                height: 1.3,
              ),
            )
          else if (user.isBanned)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Блокировка: ${user.banReason?.trim().isNotEmpty == true ? user.banReason! : 'Без причины'}',
                  style: const TextStyle(
                    color: Color(0xFF6B7F99),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SettingsSecondaryButton(
                    text: 'Разблокировать',
                    onTap: onUnban,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SettingsActionButton(
                text: 'Заблокировать',
                backgroundColor: const Color(0xFFFFE6EA),
                textColor: const Color(0xFFBD2D45),
                onTap: onBan,
                height: 38,
              ),
            ),
        ],
      ),
    );
  }
}
