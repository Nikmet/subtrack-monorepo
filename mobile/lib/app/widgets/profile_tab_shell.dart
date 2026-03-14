import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_menu.dart';

class ProfileTabShell extends StatelessWidget {
  const ProfileTabShell({
    super.key,
    required this.location,
    required this.child,
    this.backgroundColor = const Color(0xFFE8EDF4),
  });

  final String location;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      backgroundColor: backgroundColor,
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
              onDestinationSelected: (index) {
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
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
