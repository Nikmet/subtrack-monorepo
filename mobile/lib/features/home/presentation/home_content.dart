import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/ui_kit/skeleton_box.dart';
import '../../../app/ui_kit/tokens.dart';
import 'home_formatters.dart';
import 'home_models.dart';

enum HomeScreenStatus { loading, loaded, error }

class HomeScreenBody extends StatelessWidget {
  const HomeScreenBody({
    super.key,
    required this.status,
    required this.onRefresh,
    required this.onRetry,
    required this.onNotificationsTap,
    required this.onProfileTap,
    required this.onSearchTap,
    this.data,
    this.errorMessage,
  });

  final HomeScreenStatus status;
  final HomeScreenDataVm? data;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case HomeScreenStatus.loading:
        return _HomePageFrame(
          stateKey: const Key('home-loading-state'),
          onRefresh: onRefresh,
          children: const <Widget>[
            _HeaderLoadingSkeleton(),
            SizedBox(height: 20),
            _SummaryLoadingSkeleton(),
            SizedBox(height: 24),
            _SectionTitle(text: 'Мои подписки'),
            SizedBox(height: 14),
            _SubscriptionsLoadingSkeleton(),
            SizedBox(height: 16),
            _AnalyticsLoadingSkeleton(),
          ],
        );
      case HomeScreenStatus.error:
        return _HomePageFrame(
          stateKey: const Key('home-error-state'),
          onRefresh: onRefresh,
          children: <Widget>[
            const SizedBox(height: 70),
            _ErrorCard(
              message: errorMessage ?? 'Не удалось загрузить домашний экран.',
              onRetry: onRetry,
            ),
          ],
        );
      case HomeScreenStatus.loaded:
        final loadedData = data;
        if (loadedData == null) {
          return _HomePageFrame(
            stateKey: const Key('home-error-state'),
            onRefresh: onRefresh,
            children: <Widget>[
              const SizedBox(height: 70),
              _ErrorCard(
                message: 'Не удалось загрузить домашний экран.',
                onRetry: onRetry,
              ),
            ],
          );
        }
        return _HomePageFrame(
          stateKey: const Key('home-loaded-state'),
          onRefresh: onRefresh,
          children: <Widget>[
            _HomeHeader(
              userInitials: loadedData.userInitials,
              userAvatarLink: loadedData.userAvatarLink,
              onNotificationsTap: onNotificationsTap,
              onProfileTap: onProfileTap,
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              monthlyTotal: loadedData.monthlyTotal,
              subscriptionsCount: loadedData.subscriptionsCount,
            ),
            const SizedBox(height: 24),
            const _SectionTitle(text: 'Мои подписки'),
            const SizedBox(height: 14),
            _SubscriptionsSection(
              subscriptions: loadedData.subscriptions,
            ),
            const SizedBox(height: 16),
            _AnalyticsSection(
              categoryStats: loadedData.categoryStats,
              categoryTotal: loadedData.categoryTotal,
              cardStats: loadedData.cardStats,
              cardTotal: loadedData.cardTotal,
              onSearchTap: onSearchTap,
            ),
          ],
        );
    }
  }
}

class _HomePageFrame extends StatelessWidget {
  const _HomePageFrame({
    required this.stateKey,
    required this.onRefresh,
    required this.children,
  });

  final Key stateKey;
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            UiTokens.background,
            Color(0xFFE6EDF5),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const Positioned(
            top: -120,
            right: -80,
            child: _RadialGlow(
              size: 280,
              color: Color(0x144188E6),
            ),
          ),
          const Positioned(
            left: -100,
            bottom: -120,
            child: _RadialGlow(
              size: 300,
              color: Color(0x141A4171),
            ),
          ),
          RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              key: stateKey,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: UiTokens.pagePadding,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  const _RadialGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, Colors.transparent],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userInitials,
    required this.userAvatarLink,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final String userInitials;
  final String? userAvatarLink;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Домашняя',
                style: TextStyle(
                  color: Color(0xFF12263C),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.02,
                  letterSpacing: -0.72,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Ваши подписки и платежи',
                style: TextStyle(
                  color: Color(0xFF667B92),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _RoundOutlineButton(
          onTap: onNotificationsTap,
          child: SvgPicture.asset(
            'assets/icons/bell.svg',
            width: 17,
            height: 17,
            colorFilter: const ColorFilter.mode(
              Color(0xFF6D8093),
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _AvatarButton(
          initials: userInitials,
          imageUrl: userAvatarLink,
          onTap: onProfileTap,
        ),
      ],
    );
  }
}

class _RoundOutlineButton extends StatelessWidget {
  const _RoundOutlineButton({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFCFD9E6)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.initials,
    required this.imageUrl,
    required this.onTap,
  });

  final String initials;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarLetter = initials.trim().isEmpty ? '?' : initials.trim();
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 38,
          height: 38,
          child: hasImage
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) =>
                      _AvatarFallback(letter: avatarLetter),
                )
              : _AvatarFallback(letter: avatarLetter),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.letter,
  });

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFEEF3F9)],
        ),
        border: Border.all(color: const Color(0xFFCFDAE6)),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Color(0xFF244865),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.monthlyTotal,
    required this.subscriptionsCount,
  });

  final int monthlyTotal;
  final int subscriptionsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: UiTokens.radius14,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF12243D), Color(0xFF2D4668)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x33132236),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'ЕЖЕМЕСЯЧНЫЕ РАСХОДЫ',
            style: TextStyle(
              color: Color(0xFFF0F5FC),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.96,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: <Widget>[
              Text(
                formatRub(monthlyTotal),
                style: const TextStyle(
                  color: Color(0xFFF6FBFF),
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  letterSpacing: -1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '/мес',
                  style: TextStyle(
                    color: Color(0xFFF0F5FC),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x3D9DB1CF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4DE592),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x2E4DE592),
                        spreadRadius: 3,
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatSubscriptionCount(subscriptionsCount),
                  style: const TextStyle(
                    color: Color(0xFFEAF1FC),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
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
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF19354E),
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.06,
        letterSpacing: -0.68,
      ),
    );
  }
}

class _SubscriptionsSection extends StatelessWidget {
  const _SubscriptionsSection({
    required this.subscriptions,
  });

  final List<SubscriptionItemVm> subscriptions;

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return Container(
        key: const Key('home-empty-subscriptions'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: UiTokens.radius14,
          border: Border.all(color: const Color(0xFFBFD0E2)),
        ),
        child: const Text(
          'Подписок пока нет. Добавьте первую подписку через поиск.',
          style: TextStyle(
            color: Color(0xFF4D647B),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UiTokens.radius14,
        border: Border.all(color: const Color(0xFFD5E0EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1419304D),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: List<Widget>.generate(
          subscriptions.length,
          (index) {
            final item = subscriptions[index];
            return Column(
              children: <Widget>[
                _SubscriptionListItem(item: item),
                if (index != subscriptions.length - 1)
                  const Divider(
                    color: Color(0xFFE3EAF2),
                    height: 1,
                    thickness: 1,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubscriptionListItem extends StatelessWidget {
  const _SubscriptionListItem({
    required this.item,
  });

  final SubscriptionItemVm item;

  @override
  Widget build(BuildContext context) {
    final title = item.typeName.trim().isEmpty ? '-' : item.typeName;
    final meta =
        '${item.categoryName} • ${formatNextPayment(item.nextPaymentAt)} • ${formatPeriodLabel(item.period)}';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SubscriptionIcon(
            imageUrl: item.typeImage,
            name: title,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F3448),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFF76899D),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRub(item.monthlyPrice),
                  style: const TextStyle(
                    color: Color(0xFF1C374F),
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                    letterSpacing: -0.84,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'В МЕСЯЦ',
                  style: TextStyle(
                    color: Color(0xFF6F8399),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionIcon extends StatelessWidget {
  const _SubscriptionIcon({
    required this.imageUrl,
    required this.name,
  });

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final normalizedImage = imageUrl.trim();
    final showFallback = normalizedImage.isEmpty;
    final firstLetter =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return ClipRRect(
      borderRadius: UiTokens.radius10,
      child: Container(
        width: 38,
        height: 38,
        color: const Color(0xFFEDF3FB),
        child: showFallback
            ? Center(
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: Color(0xFF37546F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              )
            : Image.network(
                normalizedImage,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Color(0xFF37546F),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.categoryStats,
    required this.categoryTotal,
    required this.cardStats,
    required this.cardTotal,
    required this.onSearchTap,
  });

  final List<CategoryStatVm> categoryStats;
  final int categoryTotal;
  final List<CardStatVm> cardStats;
  final int cardTotal;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _SectionSurface(
          child: Column(
            children: <Widget>[
              _SectionHeader(
                title: 'Аналитика',
                total: '${formatRub(categoryTotal)} /мес',
                titleSize: 32,
              ),
              const SizedBox(height: 14),
              if (categoryStats.isEmpty)
                Container(
                  key: const Key('home-empty-analytics'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Добавьте подписки, чтобы увидеть структуру расходов по категориям.',
                        style: TextStyle(
                          color: Color(0xFF6F8398),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: UiTokens.radius10,
                        onTap: onSearchTap,
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: const BoxDecoration(
                            borderRadius: UiTokens.radius10,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFF1F3A57),
                                Color(0xFF30567C),
                              ],
                            ),
                          ),
                          child: const Text(
                            'Добавить подписку',
                            style: TextStyle(
                              color: Color(0xFFF6FBFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children:
                      List<Widget>.generate(categoryStats.length, (index) {
                    final item = categoryStats[index];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: index == categoryStats.length - 1 ? 0 : 14),
                      child: _CategoryStatItem(
                        item: item,
                        color: UiTokens.categoryBarColors[
                            index % UiTokens.categoryBarColors.length],
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionSurface(
          child: Column(
            children: <Widget>[
              _SectionHeader(
                title: 'По карточкам',
                total: '${formatRub(cardTotal)} /мес',
                titleSize: 20,
              ),
              const SizedBox(height: 14),
              if (cardStats.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Нет данных по способам оплаты.',
                    style: TextStyle(
                      color: Color(0xFF6F8398),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              else
                Column(
                  children: List<Widget>.generate(cardStats.length, (index) {
                    final item = cardStats[index];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: index == cardStats.length - 1 ? 0 : 10),
                      child: _CardStatItem(item: item),
                    );
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UiTokens.radius14,
        border: Border.all(color: const Color(0xFFD8E2EC)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1219304D),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.total,
    required this.titleSize,
  });

  final String title;
  final String total;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF1B3550),
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            total,
            style: const TextStyle(
              color: Color(0xFF5F7891),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryStatItem extends StatelessWidget {
  const _CategoryStatItem({
    required this.item,
    required this.color,
  });

  final CategoryStatVm item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final share = math.max(0, math.min(item.share, 100)).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  color: Color(0xFF243C53),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatRub(item.amount),
              style: const TextStyle(
                color: Color(0xFF1F364C),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: share / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE4EDF4),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${item.share.round()}% от общих расходов',
          style: const TextStyle(
            color: Color(0xFF6F8397),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _CardStatItem extends StatelessWidget {
  const _CardStatItem({
    required this.item,
  });

  final CardStatVm item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FB),
        borderRadius: UiTokens.radius12,
        border: Border.all(color: const Color(0xFFE0E8F2)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF142F4A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subscriptionsCount} подписок • ${item.share.round()}%',
                  style: const TextStyle(
                    color: Color(0xFF6F8398),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRub(item.amount),
            style: const TextStyle(
              color: Color(0xFF132A43),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UiTokens.radius14,
        border: Border.all(color: const Color(0xFFD8E2EC)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1219304D),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Не удалось загрузить данные',
            style: TextStyle(
              color: Color(0xFF1B3550),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6F8398),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: const Color(0xFF1F3A57),
              foregroundColor: const Color(0xFFF6FBFF),
              shape: const RoundedRectangleBorder(
                borderRadius: UiTokens.radius10,
              ),
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _HeaderLoadingSkeleton extends StatelessWidget {
  const _HeaderLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonBox(
                  width: 210, height: 36, borderRadius: UiTokens.radius10),
              SizedBox(height: 8),
              SkeletonBox(
                  width: 180, height: 14, borderRadius: UiTokens.radius10),
            ],
          ),
        ),
        SizedBox(width: 10),
        SkeletonBox(
            width: 38,
            height: 38,
            borderRadius: BorderRadius.all(Radius.circular(999))),
        SizedBox(width: 10),
        SkeletonBox(
            width: 38,
            height: 38,
            borderRadius: BorderRadius.all(Radius.circular(999))),
      ],
    );
  }
}

class _SummaryLoadingSkeleton extends StatelessWidget {
  const _SummaryLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF243E5F),
        borderRadius: UiTokens.radius14,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SkeletonBox(width: 150, height: 12),
          SizedBox(height: 12),
          SkeletonBox(width: 240, height: 52),
          SizedBox(height: 14),
          SkeletonBox(
              width: 130,
              height: 24,
              borderRadius: BorderRadius.all(Radius.circular(999))),
        ],
      ),
    );
  }
}

class _SubscriptionsLoadingSkeleton extends StatelessWidget {
  const _SubscriptionsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UiTokens.radius14,
        border: Border.all(color: const Color(0xFFD5E0EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: const Column(
        children: <Widget>[
          _SubscriptionRowLoadingSkeleton(),
          SizedBox(height: 12),
          _SubscriptionRowLoadingSkeleton(),
          SizedBox(height: 12),
          _SubscriptionRowLoadingSkeleton(),
        ],
      ),
    );
  }
}

class _SubscriptionRowLoadingSkeleton extends StatelessWidget {
  const _SubscriptionRowLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SkeletonBox(width: 38, height: 38, borderRadius: UiTokens.radius10),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonBox(width: 120, height: 16),
              SizedBox(height: 6),
              SkeletonBox(width: 210, height: 12),
              SizedBox(height: 10),
              SkeletonBox(width: 95, height: 28),
              SizedBox(height: 4),
              SkeletonBox(width: 50, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsLoadingSkeleton extends StatelessWidget {
  const _AnalyticsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: UiTokens.radius14,
            border: Border.all(color: const Color(0xFFD8E2EC)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonBox(width: 180, height: 28),
              SizedBox(height: 14),
              SkeletonBox(width: 220, height: 14),
              SizedBox(height: 8),
              SkeletonBox(
                  width: double.infinity,
                  height: 8,
                  borderRadius: BorderRadius.all(Radius.circular(999))),
              SizedBox(height: 12),
              SkeletonBox(width: 220, height: 14),
              SizedBox(height: 8),
              SkeletonBox(
                  width: double.infinity,
                  height: 8,
                  borderRadius: BorderRadius.all(Radius.circular(999))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: UiTokens.radius14,
            border: Border.all(color: const Color(0xFFD8E2EC)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonBox(width: 160, height: 22),
              SizedBox(height: 14),
              SkeletonBox(width: double.infinity, height: 52),
              SizedBox(height: 10),
              SkeletonBox(width: double.infinity, height: 52),
            ],
          ),
        ),
      ],
    );
  }
}
