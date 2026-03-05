import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ui_kit/tokens.dart';

class AppBottomMenu extends StatelessWidget {
  const AppBottomMenu({
    super.key,
    required this.location,
    required this.onDestinationSelected,
    this.bottomInset = 0,
  });

  final String location;
  final ValueChanged<int> onDestinationSelected;
  final double bottomInset;

  static int resolveIndex(String location) {
    if (location.startsWith('/calendar')) {
      return 1;
    }
    if (location.startsWith('/search')) {
      return 2;
    }
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/notifications') ||
        location.startsWith('/subscriptions/pending') ||
        location.startsWith('/admin')) {
      return 3;
    }
    return 0;
  }

  static const List<_MenuItemData> _items = <_MenuItemData>[
    _MenuItemData(
      label: 'Домашняя',
      iconAsset: 'assets/icons/menu_home.svg',
    ),
    _MenuItemData(
      label: 'Календарь',
      iconAsset: 'assets/icons/menu_calendar.svg',
    ),
    _MenuItemData(
      label: 'Поиск',
      iconAsset: 'assets/icons/menu_search.svg',
    ),
    _MenuItemData(
      label: 'Профиль',
      iconAsset: 'assets/icons/menu_profile.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = resolveIndex(location);

    return Container(
      height: UiTokens.bottomNavHeight + bottomInset,
      decoration: const BoxDecoration(
        color: UiTokens.bottomNavBackground,
        border: Border(
          top: BorderSide(color: UiTokens.bottomNavBorder),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: UiTokens.bottomNavShadow,
            blurRadius: 28,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(10, 8, 10, 10 + bottomInset),
      child: Row(
        children: List<Widget>.generate(_items.length, (index) {
          final item = _items[index];
          return Expanded(
            child: BottomMenuItemButton(
              key: Key('bottom-menu-item-$index'),
              label: item.label,
              iconAsset: item.iconAsset,
              isActive: currentIndex == index,
              onTap: () => onDestinationSelected(index),
            ),
          );
        }),
      ),
    );
  }
}

class BottomMenuItemButton extends StatelessWidget {
  const BottomMenuItemButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemColor =
        isActive ? UiTokens.bottomNavItemActive : UiTokens.bottomNavItem;

    return InkWell(
      borderRadius: UiTokens.radius10,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? UiTokens.bottomNavItemActiveBackground
                  : Colors.transparent,
              borderRadius: UiTokens.radius10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  iconAsset,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.label,
    required this.iconAsset,
  });

  final String label;
  final String iconAsset;
}
