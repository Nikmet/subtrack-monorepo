import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ-панель')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Модерация подписок'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/moderation'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Опубликованные подписки'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/published'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Пользователи'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/users'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Банки'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/banks'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
