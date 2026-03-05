import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final raw = await ref.read(apiClientProvider).getData('/notifications', query: {'limit': 80});
    return asMapList(raw);
  }

  Future<void> _clear() async {
    await ref.read(apiClientProvider).deleteData('/notifications');
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          TextButton(
            onPressed: _clear,
            child: const Text('Очистить'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorPlaceholder(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final notifications = snapshot.data ?? const <Map<String, dynamic>>[];
          if (notifications.isEmpty) {
            return const Center(child: Text('Пока уведомлений нет'));
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return ListTile(
                  title: Text((item['title'] ?? item['type'] ?? 'Уведомление').toString()),
                  subtitle: Text((item['message'] ?? item['createdAt'] ?? '').toString()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
