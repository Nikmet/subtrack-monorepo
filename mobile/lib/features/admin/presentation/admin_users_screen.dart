import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await ref.read(apiClientProvider).getData('/admin/users');
    setState(() {
      _users = asMapList(raw);
      _loading = false;
    });
  }

  Future<void> _ban(String id) async {
    await ref.read(apiClientProvider).postData('/admin/users/$id/ban', body: {'reason': 'Нарушение правил'});
    await _load();
  }

  Future<void> _unban(String id) async {
    await ref.read(apiClientProvider).postData('/admin/users/$id/unban', body: {});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: _users
                  .map(
                    (user) => SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((user['email'] ?? '-').toString(), style: Theme.of(context).textTheme.titleMedium),
                          Text('Роль: ${(user['role'] ?? 'USER').toString()}'),
                          Text('Подписки: ${(user['subscriptionsCount'] ?? 0).toString()}'),
                          if (user['isBanned'] == true)
                            Text('Причина бана: ${(user['banReason'] ?? '-').toString()}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (user['isBanned'] == true)
                                OutlinedButton(
                                  onPressed: () => _unban((user['id'] ?? '').toString()),
                                  child: const Text('Разблокировать'),
                                )
                              else
                                OutlinedButton(
                                  onPressed: () => _ban((user['id'] ?? '').toString()),
                                  child: const Text('Заблокировать'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
