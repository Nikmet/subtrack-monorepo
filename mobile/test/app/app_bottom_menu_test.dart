import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/app/widgets/app_bottom_menu.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Material(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('marks current route tab as active', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppBottomMenu(
          location: '/search',
          onDestinationSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final homeItem = tester.widget<BottomMenuItemButton>(
        find.byKey(const Key('bottom-menu-item-0')));
    final searchItem = tester.widget<BottomMenuItemButton>(
        find.byKey(const Key('bottom-menu-item-2')));

    expect(homeItem.isActive, isFalse);
    expect(searchItem.isActive, isTrue);
  });

  testWidgets('notifies selected tab on tap', (tester) async {
    int? selectedIndex;

    await tester.pumpWidget(
      _wrap(
        AppBottomMenu(
          location: '/',
          onDestinationSelected: (index) => selectedIndex = index,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Профиль'));
    await tester.pump();

    expect(selectedIndex, 3);
  });
}
