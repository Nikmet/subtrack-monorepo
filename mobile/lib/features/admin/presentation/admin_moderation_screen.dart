import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await ref.read(apiClientProvider).getData('/admin/moderation/subscriptions');
    setState(() {
      _items = asMapList(raw);
      _loading = false;
    });
  }

  Future<void> _publish(String id) async {
    await ref.read(apiClientProvider).postData('/admin/moderation/subscriptions/$id/publish', body: {});
    await _load();
  }

  Future<void> _reject(String id) async {
    await ref.read(apiClientProvider).postData('/admin/moderation/subscriptions/$id/reject', body: {'reason': 'Нарушение требований'});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Модерация')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: _items
                  .map(
                    (item) => SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((item['name'] ?? '-').toString(), style: Theme.of(context).textTheme.titleMedium),
                          Text((item['category'] ?? '').toString()),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => _publish((item['id'] ?? '').toString()),
                                child: const Text('Publish'),
                              ),
                              OutlinedButton(
                                onPressed: () => _reject((item['id'] ?? '').toString()),
                                child: const Text('Reject'),
                              ),
                              OutlinedButton(
                                onPressed: () => context.push('/admin/subscriptions/${item['id']}'),
                                child: const Text('Открыть'),
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
