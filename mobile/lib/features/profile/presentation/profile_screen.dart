import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final raw = await ref.read(apiClientProvider).getData('/profile');
    return asMap(raw);
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ErrorPlaceholder(
            message: snapshot.error.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }

        final data = snapshot.data ?? const <String, dynamic>{};

        return ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 120),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((data['name'] ?? user?.email ?? 'Профиль').toString(), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text((data['email'] ?? user?.email ?? '').toString()),
                  const SizedBox(height: 12),
                  Text('За год: ${money(data['yearlyTotal'] ?? 0)}'),
                  Text('Активные подписки: ${(data['activeSubscriptions'] ?? 0)}'),
                ],
              ),
            ),
            SectionCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Уведомления'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notifications'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Настройки'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Мои заявки'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/subscriptions/pending'),
                  ),
                  if (user?.isAdmin == true)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Админ-панель'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: FilledButton.tonal(
                onPressed: _logout,
                child: const Text('Выйти'),
              ),
            ),
          ],
        );
      },
    );
  }
}
