import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui_kit/tokens.dart';
import 'app_bottom_menu.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      backgroundColor: UiTokens.background,
      body: Stack(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: child,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomMenu(
              location: location,
              bottomInset: viewPadding.bottom,
              onDestinationSelected: (index) => _onTabSelected(context, index),
            ),
          ),
        ],
      ),
    );
  }

  static void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/calendar');
        break;
      case 2:
        context.go('/search');
        break;
      case 3:
        context.go('/profile');
        break;
      default:
        context.go('/');
    }
  }
}
