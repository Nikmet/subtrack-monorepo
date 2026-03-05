import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/features/home/presentation/home_content.dart';
import 'package:subtrack_mobile/features/home/presentation/home_models.dart';

HomeScreenDataVm _sampleData({
  List<SubscriptionItemVm>? subscriptions,
  List<CategoryStatVm>? categoryStats,
  List<CardStatVm>? cardStats,
}) {
  return HomeScreenDataVm(
    userInitials: 'НК',
    userAvatarLink: null,
    monthlyTotal: 1504,
    subscriptionsCount: subscriptions?.length ?? 1,
    subscriptions: subscriptions ??
        const <SubscriptionItemVm>[
          SubscriptionItemVm(
            id: '1',
            price: 399,
            monthlyPrice: 399,
            period: 1,
            nextPaymentAt: null,
            typeName: 'Wink',
            typeImage: '',
            categoryName: 'Стриминг',
          ),
        ],
    categoryStats: categoryStats ??
        const <CategoryStatVm>[
          CategoryStatVm(name: 'Стриминг', amount: 1145, share: 76),
        ],
    categoryTotal: 1504,
    cardStats: cardStats ??
        const <CardStatVm>[
          CardStatVm(
              label: 'Т-Банк • 2202************222',
              amount: 1105,
              share: 73,
              subscriptionsCount: 4),
        ],
    cardTotal: 1504,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Material(
      child: child,
    ),
  );
}

void main() {
  testWidgets('shows loading state skeleton', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeScreenBody(
          status: HomeScreenStatus.loading,
          onRefresh: () async {},
          onRetry: () {},
          onNotificationsTap: () {},
          onProfileTap: () {},
          onSearchTap: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('home-loading-state')), findsOneWidget);
    expect(find.byKey(const Key('home-loaded-state')), findsNothing);
  });

  testWidgets('shows loaded data', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeScreenBody(
          status: HomeScreenStatus.loaded,
          data: _sampleData(),
          onRefresh: () async {},
          onRetry: () {},
          onNotificationsTap: () {},
          onProfileTap: () {},
          onSearchTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-loaded-state')), findsOneWidget);
    expect(find.text('Домашняя'), findsOneWidget);
    expect(find.text('Мои подписки'), findsOneWidget);
    expect(find.text('Аналитика'), findsOneWidget);
  });

  testWidgets('shows empty states for subscriptions and analytics',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        HomeScreenBody(
          status: HomeScreenStatus.loaded,
          data: _sampleData(
            subscriptions: const <SubscriptionItemVm>[],
            categoryStats: const <CategoryStatVm>[],
            cardStats: const <CardStatVm>[],
          ),
          onRefresh: () async {},
          onRetry: () {},
          onNotificationsTap: () {},
          onProfileTap: () {},
          onSearchTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-empty-subscriptions')), findsOneWidget);
    expect(find.byKey(const Key('home-empty-analytics')), findsOneWidget);
    expect(find.text('Нет данных по способам оплаты.'), findsOneWidget);
  });

  testWidgets('shows error and allows retry', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      _wrap(
        HomeScreenBody(
          status: HomeScreenStatus.error,
          errorMessage: 'Ошибка сети',
          onRefresh: () async {},
          onRetry: () {
            retried = true;
          },
          onNotificationsTap: () {},
          onProfileTap: () {},
          onSearchTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-error-state')), findsOneWidget);
    expect(find.text('Ошибка сети'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(retried, isTrue);
  });
}
