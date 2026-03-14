import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/api/generated/openapi_client.dart';
import 'package:subtrack_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:subtrack_mobile/features/shared/providers.dart';
import 'package:subtrack_mobile/features/subscriptions/presentation/pending_subscriptions_screen.dart';

class _FakeApiClient extends GeneratedApiClient {
  _FakeApiClient({
    Map<String, dynamic>? getResponses,
  })  : getResponses = Map<String, dynamic>.from(getResponses ?? const <String, dynamic>{}),
        super(Dio());

  final Map<String, dynamic> getResponses;
  final List<String> deleteCalls = <String>[];

  @override
  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async {
    final key = query == null || query.isEmpty
        ? path
        : '$path?${query.entries.map((entry) => '${entry.key}=${entry.value}').join('&')}';
    return getResponses[key] ?? getResponses[path];
  }

  @override
  Future<dynamic> deleteData(String path, {body, Map<String, dynamic>? query}) async {
    deleteCalls.add(path);
    if (path == '/notifications') {
      getResponses['/notifications?limit=80'] = <Map<String, dynamic>>[];
      getResponses['/notifications'] = <Map<String, dynamic>>[];
    }
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> patchData(String path, {body, Map<String, dynamic>? query}) async => <String, dynamic>{};

  @override
  Future<dynamic> postData(String path, {body, Map<String, dynamic>? query}) async => <String, dynamic>{};

  @override
  Future<dynamic> uploadFile(String path, FormData formData) async => <String, dynamic>{};
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
  testWidgets('pending screen renders cards and empty action state', (tester) async {
    final api = _FakeApiClient(
      getResponses: <String, dynamic>{
        '/user-subscriptions/pending': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '1',
            'name': 'Dota Plus',
            'imgLink': '',
            'categoryName': 'Игры',
            'price': 1200,
            'period': 1,
            'moderationComment': null,
            'status': 'PUBLISHED',
          },
        ],
      },
    );

    await tester.pumpWidget(_wrap(child: const PendingSubscriptionsScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Мои заявки'), findsOneWidget);
    expect(find.text('Dota Plus'), findsOneWidget);
    expect(find.text('ОПУБЛИКОВАНО'), findsOneWidget);
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('notifications screen renders cards and clears list', (tester) async {
    final createdAt = DateTime.now().subtract(const Duration(days: 8)).toIso8601String();
    final api = _FakeApiClient(
      getResponses: <String, dynamic>{
        '/notifications?limit=80': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '1',
            'kind': 'success',
            'title': 'Подписка опубликована',
            'message': 'Ваша заявка прошла модерацию и опубликована.',
            'createdAt': createdAt,
          },
        ],
      },
    );

    await tester.pumpWidget(_wrap(child: const NotificationsScreen(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.text('Очистить'), findsOneWidget);
    expect(find.text('Подписка опубликована'), findsOneWidget);

    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();

    expect(api.deleteCalls, contains('/notifications'));
    expect(find.text('Подписка опубликована'), findsNothing);
    expect(find.text('Все уведомления просмотрены'), findsOneWidget);
  });
}
