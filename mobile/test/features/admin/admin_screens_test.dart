import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/api/generated/openapi_client.dart';
import 'package:subtrack_mobile/features/admin/presentation/admin_banks_screen.dart';
import 'package:subtrack_mobile/features/admin/presentation/admin_home_screen.dart';
import 'package:subtrack_mobile/features/admin/presentation/admin_moderation_screen.dart';
import 'package:subtrack_mobile/features/admin/presentation/admin_published_screen.dart';
import 'package:subtrack_mobile/features/admin/presentation/admin_subscription_detail_screen.dart';
import 'package:subtrack_mobile/features/admin/presentation/admin_users_screen.dart';
import 'package:subtrack_mobile/features/shared/providers.dart';

class _FakeAdminApiClient extends GeneratedApiClient {
  _FakeAdminApiClient({
    this.getResponses = const <String, dynamic>{},
  }) : super(Dio());

  final Map<String, dynamic> getResponses;

  @override
  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async {
    return getResponses[path];
  }

  @override
  Future<dynamic> patchData(String path,
          {body, Map<String, dynamic>? query}) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> postData(String path,
          {body, Map<String, dynamic>? query}) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> deleteData(String path,
          {body, Map<String, dynamic>? query}) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> uploadFile(String path, FormData formData) async =>
      <String, dynamic>{'url': 'https://example.com/icon.png'};
}

Widget _wrap({
  required Widget child,
  required GeneratedApiClient api,
}) {
  return ProviderScope(
    overrides: <Override>[
      apiClientProvider.overrideWithValue(api),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('admin home screen shows all russian areas', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const AdminHomeScreen(),
        api: _FakeAdminApiClient(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Админ-панель'), findsOneWidget);
    expect(find.text('Области'), findsOneWidget);
    expect(find.text('Очередь модерации'), findsOneWidget);
    expect(find.text('Опубликованные'), findsOneWidget);
    expect(find.text('Пользователи'), findsOneWidget);
    expect(find.text('Банки'), findsOneWidget);
  });

  testWidgets('moderation screen shows translated filters and actions',
      (tester) async {
    final api = _FakeAdminApiClient(
      getResponses: <String, dynamic>{
        '/admin/moderation/subscriptions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'sub-1',
            'name': 'X5 Пакет',
            'imgLink': '',
            'category': 'shopping',
            'categoryName': 'Покупки',
            'price': 199,
            'period': 1,
            'createdByUser': <String, dynamic>{
              'name': 'Метлов Никита',
              'email': 'metlov.nm@yandex.ru',
            },
          },
        ],
      },
    );

    await tester
        .pumpWidget(_wrap(child: const AdminModerationScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Очередь модерации'), findsOneWidget);
    expect(find.text('Модерация'), findsOneWidget);
    expect(find.text('Применить'), findsOneWidget);
    expect(find.text('Сбросить'), findsOneWidget);
    expect(find.text('X5 Пакет'), findsOneWidget);
    expect(find.text('Автор: Метлов Никита (metlov.nm@yandex.ru)'),
        findsOneWidget);
    expect(find.text('Опубликовать'), findsOneWidget);
    expect(find.text('Отклонить'), findsOneWidget);
  });

  testWidgets('published screen shows russian title and edit action',
      (tester) async {
    final api = _FakeAdminApiClient(
      getResponses: <String, dynamic>{
        '/admin/published/subscriptions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'pub-1',
            'name': 'WB Клуб',
            'imgLink': '',
            'category': 'shopping',
            'categoryName': 'Покупки',
            'price': 399,
            'period': 1,
            'subscribersCount': 0,
          },
        ],
      },
    );

    await tester
        .pumpWidget(_wrap(child: const AdminPublishedScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Опубликованные подписки'), findsOneWidget);
    expect(find.text('Опубликованные'), findsOneWidget);
    expect(find.text('WB Клуб'), findsOneWidget);
    expect(find.text('Подписчиков: 0'), findsOneWidget);
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
  });

  testWidgets('users screen shows russian filters and admin label',
      (tester) async {
    final api = _FakeAdminApiClient(
      getResponses: <String, dynamic>{
        '/admin/users': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'admin-1',
            'name': 'Метлов Никита',
            'avatarLink': '',
            'email': 'metlov.nm@yandex.ru',
            'role': 'ADMIN',
            'isBanned': false,
            'subscriptionsCount': 5,
          },
          <String, dynamic>{
            'id': 'user-1',
            'name': 'Вася Пупкин',
            'avatarLink': '',
            'email': 'a@a.ru',
            'role': 'USER',
            'isBanned': false,
            'subscriptionsCount': 0,
          },
        ],
      },
    );

    await tester.pumpWidget(_wrap(child: const AdminUsersScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Пользователи'), findsWidgets);
    expect(find.text('Применить'), findsOneWidget);
    expect(find.text('Сбросить'), findsOneWidget);
    expect(find.text('Метлов Никита • АДМИН'), findsOneWidget);
    expect(find.text('Администраторы не блокируются.'), findsOneWidget);
    expect(find.text('Вася Пупкин'), findsOneWidget);
    expect(find.text('Заблокировать'), findsOneWidget);
  });

  testWidgets('banks screen shows create form and list section',
      (tester) async {
    final api = _FakeAdminApiClient(
      getResponses: <String, dynamic>{
        '/admin/banks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'sber',
            'name': 'Сбербанк',
            'iconLink': '',
            '_count': <String, dynamic>{'paymentMethods': 1},
          },
        ],
      },
    );

    await tester.pumpWidget(_wrap(child: const AdminBanksScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Банки'), findsOneWidget);
    expect(find.text('Новый банк'), findsOneWidget);
    expect(find.text('Создать банк'), findsOneWidget);
    expect(find.text('Справочник'), findsOneWidget);
    expect(find.text('Сбербанк'), findsWidgets);
    expect(find.text('Используется в 1 способах оплаты'), findsOneWidget);
  });

  testWidgets('subscription detail screen shows russian form labels',
      (tester) async {
    final api = _FakeAdminApiClient(
      getResponses: <String, dynamic>{
        '/admin/subscriptions/pub-1': <String, dynamic>{
          'name': 'WB Клуб',
          'imgLink': 'https://example.com/icon.png',
          'category': 'shopping',
          'price': 399,
          'period': 1,
          'moderationComment': '',
        },
      },
    );

    await tester.pumpWidget(
      _wrap(
        child: const AdminSubscriptionDetailScreen(subscriptionId: 'pub-1'),
        api: api,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Редактирование подписки'), findsOneWidget);
    expect(find.text('НАЗВАНИЕ'), findsOneWidget);
    expect(find.text('URL ИКОНКИ'), findsOneWidget);
    expect(find.text('КАТЕГОРИЯ'), findsOneWidget);
    expect(find.text('СТОИМОСТЬ'), findsOneWidget);
    expect(find.text('ПЕРИОД'), findsOneWidget);
    expect(find.text('КОММЕНТАРИЙ МОДЕРАТОРА'), findsOneWidget);
    expect(find.text('Сохранить изменения'), findsOneWidget);
  });
}
