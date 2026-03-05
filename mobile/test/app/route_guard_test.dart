import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/app/router/route_guard.dart';
import 'package:subtrack_mobile/core/models/auth_session_state.dart';

void main() {
  test('route guard redirects unauthenticated users to login', () {
    final result = resolveRedirect(
      sessionState: AuthSessionState.unauthenticated,
      isAdmin: false,
      location: '/',
    );

    expect(result, '/login');
  });

  test('route guard redirects auth users from login to home', () {
    final result = resolveRedirect(
      sessionState: AuthSessionState.authenticated,
      isAdmin: false,
      location: '/login',
    );

    expect(result, '/');
  });

  test('route guard blocks non-admin in admin section', () {
    final result = resolveRedirect(
      sessionState: AuthSessionState.authenticated,
      isAdmin: false,
      location: '/admin/users',
    );

    expect(result, '/');
  });
}
