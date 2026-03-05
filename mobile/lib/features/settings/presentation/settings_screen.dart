import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final raw = await ref.read(apiClientProvider).getData('/settings');
    return asMap(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: FutureBuilder<Map<String, dynamic>>(
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
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['name'] ?? '').toString(), style: Theme.of(context).textTheme.titleLarge),
                    Text((data['email'] ?? '').toString()),
                    const SizedBox(height: 8),
                    Text('Основная карта: ${(data['defaultPaymentMethodLabel'] ?? '-').toString()}'),
                  ],
                ),
              ),
              SectionCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Профиль'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/profile'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Способы оплаты'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/payment-methods'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Безопасность'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/security'),
                    ),
                    if ((data['role'] ?? '').toString().toUpperCase() == 'ADMIN')
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Админ-панель'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
