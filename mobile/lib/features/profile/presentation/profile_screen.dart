import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui_kit/skeleton_box.dart';
import '../../../app/ui_kit/tokens.dart';
import '../../../features/home/presentation/home_formatters.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _ProfileState _state = _ProfileState.loading;
  Map<String, dynamic> _data = const <String, dynamic>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = _ProfileState.loading;
      _error = null;
    });
    try {
      final raw = await ref.read(apiClientProvider).getData('/profile');
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _ProfileState.loaded;
        _data = asMap(raw);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _ProfileState.error;
        _error = error.toString();
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
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    if (_state == _ProfileState.loading) {
      return const _ProfileLoadingView();
    }

    if (_state == _ProfileState.error) {
      return _ProfileErrorView(
        message: _error ?? 'Не удалось загрузить профиль.',
        onRetry: _load,
      );
    }

    final name =
        (_data['name'] ?? user?.name ?? user?.email ?? 'Профиль').toString();
    final email = (_data['email'] ?? user?.email ?? '').toString();
    final yearlyTotal = _asNum(_data['yearlyTotal']);
    final activeSubscriptions = _asNum(_data['activeSubscriptions']).toInt();
    final avatar =
        (_data['avatarLink'] ?? user?.avatarLink ?? '').toString().trim();
    final initials = (_data['initials'] ?? _initialsFromName(name)).toString();

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE8EDF4)),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 104),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF081227),
                    Color(0xFF09203F),
                    Color(0xFF063F56),
                  ],
                  stops: <double>[0, 0.52, 1],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Профиль',
                          style: TextStyle(
                            color: Color(0xFFF4F8FF),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push('/settings'),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0x3395B5D5),
                            border: Border.all(color: const Color(0x40C5DAF2)),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Color(0xFFD6E8FB),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      _Avatar(imageUrl: avatar, initials: initials),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFF4F8FF),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFAFC4DF),
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _StatCard(
                          label: 'За год',
                          value: formatRub(yearlyTotal),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Активных подписок',
                          value: '$activeSubscriptions',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle(text: 'Подписки'),
            _GroupCard(
              children: <Widget>[
                _ProfileRow(
                  icon: const _RowIconClock(),
                  text: 'Мои заявки на публикацию',
                  onTap: () => context.push('/subscriptions/pending'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle(text: 'Безопасность'),
            const _GroupCard(
              children: <Widget>[
                _ProfileRow(
                  icon: _RowIconShield(),
                  text: 'Двухфакторная аутентификация',
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: InkWell(
                onTap: _logout,
                borderRadius: UiTokens.radius12,
                child: Container(
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEF0),
                    borderRadius: UiTokens.radius12,
                  ),
                  child: const Center(
                    child: Text(
                      'Выйти из аккаунта',
                      style: TextStyle(
                        color: Color(0xFFF24359),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static num _asNum(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _initialsFromName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts =
        trimmed.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).toList();
    final first = _firstRune(parts.first);
    if (parts.length == 1) {
      return first.toUpperCase();
    }
    final second = _firstRune(parts[1]);
    return '$first$second'.toUpperCase();
  }

  static String _firstRune(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return String.fromCharCode(value.runes.first);
  }
}

enum _ProfileState { loading, loaded, error }

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.initials,
  });

  final String imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 70,
        height: 70,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) =>
                    _AvatarFallback(initials: initials),
              )
            : _AvatarFallback(initials: initials),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF244B7D), Color(0xFF0F1F34)],
        ),
        border: Border.all(color: const Color(0xFF2E99B5), width: 3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFFEBF5FF),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F7),
        borderRadius: UiTokens.radius14,
      ),
      child: Column(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8698AF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF122034),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF92A3B9),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.56,
          height: 1.2,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 14, right: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: UiTokens.radius14,
        border: Border.all(color: const Color(0xFFE0E5EC)),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final Widget icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF1F6),
              borderRadius: UiTokens.radius10,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF10203A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFC1CAD8),
            size: 20,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: UiTokens.radius14,
      child: content,
    );
  }
}

class _RowIconClock extends StatelessWidget {
  const _RowIconClock();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.access_time_rounded,
      color: Color(0xFF3B82F6),
      size: 20,
    );
  }
}

class _RowIconShield extends StatelessWidget {
  const _RowIconShield();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.shield_outlined,
      color: Color(0xFF9D4DFF),
      size: 20,
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE8EDF4)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: UiTokens.radius12,
              border: Border.all(color: const Color(0xFFD9E1EC)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Ошибка загрузки профиля',
                  style: TextStyle(
                    color: Color(0xFF10233F),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF3F5168),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE8EDF4)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 104),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF081227),
                  Color(0xFF09203F),
                  Color(0xFF063F56),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Column(
              children: <Widget>[
                SkeletonBox(
                  width: double.infinity,
                  height: 32,
                  borderRadius: UiTokens.radius10,
                ),
                SizedBox(height: 16),
                SkeletonBox(
                  width: double.infinity,
                  height: 70,
                  borderRadius: UiTokens.radius14,
                ),
                SizedBox(height: 16),
                SkeletonBox(
                  width: double.infinity,
                  height: 96,
                  borderRadius: UiTokens.radius14,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SkeletonBox(
              width: 100,
              height: 14,
              borderRadius: UiTokens.radius10,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SkeletonBox(
              width: double.infinity,
              height: 58,
              borderRadius: UiTokens.radius14,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SkeletonBox(
              width: 120,
              height: 14,
              borderRadius: UiTokens.radius10,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SkeletonBox(
              width: double.infinity,
              height: 58,
              borderRadius: UiTokens.radius14,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SkeletonBox(
              width: double.infinity,
              height: 46,
              borderRadius: UiTokens.radius12,
            ),
          ),
        ],
      ),
    );
  }
}
