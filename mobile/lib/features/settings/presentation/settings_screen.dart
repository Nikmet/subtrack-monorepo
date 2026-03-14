import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import 'settings_models.dart';
import 'settings_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true;
  String? _error;
  SettingsOverviewData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ref.read(apiClientProvider).getData('/settings');
      if (!mounted) {
        return;
      }
      setState(() {
        _data = SettingsOverviewData.fromJson(asMap(raw));
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
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
    return SettingsScaffold(
      title: 'Настройки',
      location: '/settings',
      backRoute: '/profile',
      child: Builder(
        builder: (context) {
          if (_loading) {
            return const SettingsLoadingView();
          }
          if (_error != null || _data == null) {
            return SettingsErrorView(
              message: _error ?? 'Не удалось загрузить настройки.',
              onRetry: _load,
            );
          }

          final data = _data!;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 112),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDCE4EE)),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      SettingsAvatar(
                        name: data.name,
                        imageUrl: data.avatarLink,
                        size: 86,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF10253F),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF627A97),
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SettingsPlanBadge(),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const SettingsSectionTitle(text: 'Личные данные'),
                SettingsGroupCard(
                  children: <Widget>[
                    SettingsRow(
                      title: 'Мой профиль',
                      icon: const Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: Color(0xFF657388),
                      ),
                      onTap: () => context.push('/settings/profile'),
                    ),
                    SettingsRow(
                      title: 'Способы оплаты',
                      subtitle: data.defaultPaymentMethodLabel,
                      value: data.defaultPaymentMethodLabel,
                      icon: const Icon(
                        Icons.credit_card_rounded,
                        size: 20,
                        color: Color(0xFF657388),
                      ),
                      onTap: () => context.push('/settings/payment-methods'),
                    ),
                    SettingsRow(
                      title: 'Безопасность',
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: Color(0xFF657388),
                      ),
                      onTap: () => context.push('/settings/security'),
                    ),
                    if (data.isAdmin)
                      SettingsRow(
                        title: 'Админ-панель',
                        subtitle: 'Раздел управления',
                        icon: const Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: Color(0xFF657388),
                        ),
                        onTap: () => context.push('/admin'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Выйти из аккаунта',
                        style: TextStyle(
                          color: Color(0xFFF24359),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SettingsFooter(),
              ],
            ),
          );
        },
      ),
    );
  }
}
