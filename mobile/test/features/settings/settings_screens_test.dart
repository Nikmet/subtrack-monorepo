import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/api/generated/openapi_client.dart';
import 'package:subtrack_mobile/features/settings/presentation/settings_payment_methods_screen.dart';
import 'package:subtrack_mobile/features/settings/presentation/settings_profile_screen.dart';
import 'package:subtrack_mobile/features/settings/presentation/settings_screen.dart';
import 'package:subtrack_mobile/features/settings/presentation/settings_security_screen.dart';
import 'package:subtrack_mobile/features/shared/providers.dart';

class _FakeApiClient extends GeneratedApiClient {
  _FakeApiClient({
    this.getResponses = const <String, dynamic>{},
  }) : super(Dio());

  final Map<String, dynamic> getResponses;

  @override
  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async {
    return getResponses[path];
  }

  @override
  Future<dynamic> patchData(String path, {body, Map<String, dynamic>? query}) async => <String, dynamic>{};

  @override
  Future<dynamic> postData(String path, {body, Map<String, dynamic>? query}) async => <String, dynamic>{};

  @override
  Future<dynamic> deleteData(String path, {body, Map<String, dynamic>? query}) async => <String, dynamic>{};

  @override
  Future<dynamic> uploadFile(String path, FormData formData) async => <String, dynamic>{'url': 'https://example.com/avatar.png'};
}

Widget _wrap({
  required Widget child,
  required GeneratedApiClient api,
}) {
  return ProviderScope(
    overrides: <Override>[
      apiClientProvider.overrideWithValue(api),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  testWidgets('settings screen shows overview, admin row and footer', (tester) async {
    final api = _FakeApiClient(
      getResponses: <String, dynamic>{
        '/settings': <String, dynamic>{
          'name': 'Метлов Никита',
          'email': 'metlov.nm@yandex.ru',
          'initials': 'МН',
          'avatarLink': null,
          'defaultPaymentMethodLabel': 'Т-Банк • 2202************222',
          'role': 'ADMIN',
        },
      },
    );

    await tester.pumpWidget(_wrap(child: const SettingsScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Метлов Никита'), findsOneWidget);
    expect(find.text('FREE план'), findsOneWidget);
    expect(find.text('ЛИЧНЫЕ ДАННЫЕ'), findsOneWidget);
    expect(find.text('Админ-панель'), findsOneWidget);
    expect(find.text('Выйти из аккаунта'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('SubTrack App © 2026'), findsOneWidget);
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('profile screen shows fetched form and upload action', (tester) async {
    final api = _FakeApiClient(
      getResponses: <String, dynamic>{
        '/settings/profile': <String, dynamic>{
          'name': 'Метлов Никита',
          'email': 'metlov.nm@yandex.ru',
          'avatarLink': 'https://example.com/avatar.png',
        },
      },
    );

    await tester.pumpWidget(_wrap(child: const SettingsProfileScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Профиль'), findsWidgets);
    expect(find.text('Загрузить аватар'), findsOneWidget);
    expect(find.text('Имя'.toUpperCase()), findsOneWidget);
    expect(find.text('URL аватара'.toUpperCase()), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);
    expect(find.text('metlov.nm@yandex.ru'), findsOneWidget);
  });

  testWidgets('security screen shows password fields and action button', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const SettingsSecurityScreen(),
        api: _FakeApiClient(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Безопасность'), findsOneWidget);
    expect(find.text('ТЕКУЩИЙ ПАРОЛЬ'), findsOneWidget);
    expect(find.text('НОВЫЙ ПАРОЛЬ'), findsOneWidget);
    expect(find.text('ПОДТВЕРДИТЕ НОВЫЙ ПАРОЛЬ'), findsOneWidget);
    expect(find.text('Изменить пароль'), findsOneWidget);
  });

  testWidgets('payment methods screen shows create form and cards', (tester) async {
    final api = _FakeApiClient(
      getResponses: <String, dynamic>{
        '/banks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 't',
            'name': 'Т-Банк',
            'iconLink': '',
          },
          <String, dynamic>{
            'id': 's',
            'name': 'Сбербанк',
            'iconLink': '',
          },
        ],
        '/payment-methods': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '1',
            'cardNumber': '2202************222',
            'bankId': 't',
            'isDefault': true,
            'bank': <String, dynamic>{
              'name': 'Т-Банк',
              'iconLink': '',
            },
            '_count': <String, dynamic>{'subscriptions': 4},
          },
          <String, dynamic>{
            'id': '2',
            'cardNumber': '2202************123',
            'bankId': 's',
            'isDefault': false,
            'bank': <String, dynamic>{
              'name': 'Сбербанк',
              'iconLink': '',
            },
            '_count': <String, dynamic>{'subscriptions': 1},
          },
        ],
      },
    );

    await tester.pumpWidget(_wrap(child: const SettingsPaymentMethodsScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Способы оплаты'), findsOneWidget);
    expect(find.text('НОВЫЙ СПОСОБ ОПЛАТЫ'), findsOneWidget);
    expect(find.text('МОИ КАРТЫ'), findsOneWidget);
    expect(find.text('По умолчанию'), findsOneWidget);
    expect(find.text('Подписок: 4'), findsOneWidget);
    expect(find.text('Т-Банк • 2202************222'), findsOneWidget);
    expect(find.text('Сделать основным'), findsOneWidget);
    expect(find.text('Удалить'), findsWidgets);
  });
}
