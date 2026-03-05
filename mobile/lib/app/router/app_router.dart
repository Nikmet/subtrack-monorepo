import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_banks_screen.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/admin/presentation/admin_moderation_screen.dart';
import '../../features/admin/presentation/admin_published_screen.dart';
import '../../features/admin/presentation/admin_subscription_detail_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_all_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_payment_methods_screen.dart';
import '../../features/settings/presentation/settings_profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/settings_security_screen.dart';
import '../../features/shared/providers.dart';
import '../../features/shared/splash_screen.dart';
import '../../features/subscriptions/presentation/new_subscription_screen.dart';
import '../../features/subscriptions/presentation/pending_subscriptions_screen.dart';
import 'route_guard.dart';
import '../widgets/app_shell_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);

  ref.listen(authControllerProvider, (_, __) {
    refresh.value++;
  });

  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      return resolveRedirect(
        sessionState: auth.sessionState,
        isAdmin: auth.user?.isAdmin ?? false,
        location: state.uri.path,
      );
    },
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return AppShellScaffold(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen()),
          GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen()),
          GoRoute(
              path: '/search/all',
              builder: (context, state) => const SearchAllScreen()),
          GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
          path: '/subscriptions/new',
          builder: (context, state) => const NewSubscriptionScreen()),
      GoRoute(
          path: '/subscriptions/pending',
          builder: (context, state) => const PendingSubscriptionsScreen()),
      GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/settings/profile',
          builder: (context, state) => const SettingsProfileScreen()),
      GoRoute(
          path: '/settings/payment-methods',
          builder: (context, state) => const SettingsPaymentMethodsScreen()),
      GoRoute(
          path: '/settings/security',
          builder: (context, state) => const SettingsSecurityScreen()),
      GoRoute(
          path: '/admin', builder: (context, state) => const AdminHomeScreen()),
      GoRoute(
          path: '/admin/moderation',
          builder: (context, state) => const AdminModerationScreen()),
      GoRoute(
          path: '/admin/published',
          builder: (context, state) => const AdminPublishedScreen()),
      GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen()),
      GoRoute(
          path: '/admin/banks',
          builder: (context, state) => const AdminBanksScreen()),
      GoRoute(
        path: '/admin/subscriptions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdminSubscriptionDetailScreen(subscriptionId: id);
        },
      ),
    ],
  );
});
