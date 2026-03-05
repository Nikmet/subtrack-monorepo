import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_session_state.dart';
import '../../../core/models/session_user.dart';
import '../data/auth_repository.dart';

class AuthViewState {
  const AuthViewState({
    required this.sessionState,
    this.user,
    this.error,
    this.isLoading = false,
  });

  final AuthSessionState sessionState;
  final SessionUser? user;
  final String? error;
  final bool isLoading;

  bool get isAuthenticated => sessionState == AuthSessionState.authenticated;

  AuthViewState copyWith({
    AuthSessionState? sessionState,
    SessionUser? user,
    String? error,
    bool clearError = false,
    bool? isLoading,
  }) {
    return AuthViewState(
      sessionState: sessionState ?? this.sessionState,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static const unknown = AuthViewState(sessionState: AuthSessionState.unknown);
}

class AuthController extends StateNotifier<AuthViewState> {
  AuthController(this._repository) : super(AuthViewState.unknown);

  final AuthRepository _repository;

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final stored = await _repository.readTokens();
    if (stored == null) {
      state = const AuthViewState(sessionState: AuthSessionState.unauthenticated);
      return;
    }

    try {
      final user = await _repository.loadMe();
      state = AuthViewState(
        sessionState: user.isBanned ? AuthSessionState.banned : AuthSessionState.authenticated,
        user: user,
      );
    } catch (_) {
      try {
        final user = await _repository.refreshSession();
        state = AuthViewState(
          sessionState: user.isBanned ? AuthSessionState.banned : AuthSessionState.authenticated,
          user: user,
        );
      } catch (_) {
        await _repository.clearTokens();
        state = const AuthViewState(sessionState: AuthSessionState.unauthenticated);
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthViewState(
        sessionState: user.isBanned ? AuthSessionState.banned : AuthSessionState.authenticated,
        user: user,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.register(name: name, email: email, password: password);
      state = AuthViewState(
        sessionState: user.isBanned ? AuthSessionState.banned : AuthSessionState.authenticated,
        user: user,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _repository.logout();
    state = const AuthViewState(sessionState: AuthSessionState.unauthenticated);
  }

  Future<void> markSessionExpired() async {
    await _repository.clearTokens();
    state = const AuthViewState(sessionState: AuthSessionState.unauthenticated);
  }
}
