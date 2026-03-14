import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin_models.dart';
import 'admin_widgets.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminHeader(
            backText: '← В настройки',
            backRoute: '/settings',
            title: 'Админ-панель',
          ),
          const AdminSectionTitle('Области', top: 8),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: adminAreaLinks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final area = adminAreaLinks[index];
                return InkWell(
                  onTap: () => context.push(area.route),
                  borderRadius: BorderRadius.circular(12),
                  child: AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          area.title,
                          style: const TextStyle(
                            color: Color(0xFF112841),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          area.description,
                          style: const TextStyle(
                            color: Color(0xFF6B7F99),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
