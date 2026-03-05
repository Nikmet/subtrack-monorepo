import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class PendingSubscriptionsScreen extends ConsumerStatefulWidget {
  const PendingSubscriptionsScreen({super.key});

  @override
  ConsumerState<PendingSubscriptionsScreen> createState() => _PendingSubscriptionsScreenState();
}

class _PendingSubscriptionsScreenState extends ConsumerState<PendingSubscriptionsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final raw = await ref.read(apiClientProvider).getData('/user-subscriptions/pending');
    return asMapList(raw);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заявки на публикацию')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorPlaceholder(message: snapshot.error.toString(), onRetry: _reload);
          }

          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return const Center(child: Text('Нет ожидающих заявок'));
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              children: items
                  .map(
                    (item) => ListTile(
                      title: Text((item['name'] ?? item['typeName'] ?? '-').toString()),
                      subtitle: Text((item['status'] ?? 'PENDING').toString()),
                      trailing: Text(money(item['price'] ?? 0)),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
