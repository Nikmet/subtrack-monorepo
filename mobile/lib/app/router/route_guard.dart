import '../../core/models/auth_session_state.dart';

String? resolveRedirect({
  required AuthSessionState sessionState,
  required bool isAdmin,
  required String location,
}) {
  final isAuthRoute = location == '/login' || location == '/register';
  final isSplash = location == '/splash';

  if (sessionState == AuthSessionState.unknown) {
    return isSplash ? null : '/splash';
  }

  if (sessionState == AuthSessionState.unauthenticated) {
    return isAuthRoute ? null : '/login';
  }

  if (sessionState == AuthSessionState.banned) {
    return '/login';
  }

  if (isAuthRoute || isSplash) {
    return '/';
  }

  if (location.startsWith('/admin') && !isAdmin) {
    return '/';
  }

  return null;
}
