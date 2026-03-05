import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class AdminPublishedScreen extends ConsumerStatefulWidget {
  const AdminPublishedScreen({super.key});

  @override
  ConsumerState<AdminPublishedScreen> createState() => _AdminPublishedScreenState();
}

class _AdminPublishedScreenState extends ConsumerState<AdminPublishedScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await ref.read(apiClientProvider).getData('/admin/published/subscriptions');
    setState(() {
      _items = asMapList(raw);
      _loading = false;
    });
  }

  Future<void> _remove(String id) async {
    await ref.read(apiClientProvider).deleteData('/admin/subscriptions/$id', body: {'reason': 'Запрос администратора'});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Опубликованные')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: _items
                  .map(
                    (item) => SectionCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text((item['name'] ?? '-').toString()),
                        subtitle: Text((item['category'] ?? '').toString()),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.push('/admin/subscriptions/${item['id']}'),
                              child: const Text('Edit'),
                            ),
                            OutlinedButton(
                              onPressed: () => _remove((item['id'] ?? '').toString()),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
