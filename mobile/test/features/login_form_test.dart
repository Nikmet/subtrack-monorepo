import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/api/generated/openapi_client.dart';
import 'package:subtrack_mobile/features/auth/data/auth_repository.dart';
import 'package:subtrack_mobile/features/auth/presentation/auth_controller.dart';
import 'package:subtrack_mobile/features/auth/presentation/login_screen.dart';
import 'package:subtrack_mobile/features/shared/providers.dart';

import '../support/in_memory_token_storage.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController()
      : super(
          AuthRepository(
            api: GeneratedApiClient(Dio()),
            tokenStorage: InMemoryTokenStorage(),
          ),
        );

  int loginCalls = 0;

  @override
  Future<bool> login({required String email, required String password}) async {
    loginCalls += 1;
    return true;
  }
}

void main() {
  testWidgets('login form validates empty fields', (tester) async {
    final controller = _FakeAuthController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    // Validation blocks submit if required fields are empty.
    expect(controller.loginCalls, 0);
  });
}
