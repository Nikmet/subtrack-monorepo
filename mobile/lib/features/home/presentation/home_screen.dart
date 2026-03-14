import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/api_failure.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import 'home_content.dart';
import 'home_delete_confirm.dart';
import 'home_models.dart';
import 'home_subscription_editor.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeScreenStatus _status = HomeScreenStatus.loading;
  HomeScreenDataVm? _data;
  String? _errorMessage;
  String _currency = 'rub';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? currency}) async {
    final targetCurrency = currency ?? _currency;

    if (mounted) {
      setState(() {
        _status = HomeScreenStatus.loading;
        _errorMessage = null;
      });
    }

    try {
      final raw = await ref.read(apiClientProvider).getData(
        '/home',
        query: <String, dynamic>{'currency': targetCurrency},
      );
      final mapped = HomeScreenDataVm.fromMap(asMap(raw));
      if (!mounted) {
        return;
      }

      setState(() {
        _status = HomeScreenStatus.loaded;
        _data = mapped;
        _currency = mapped.currency;
      });

      if (mapped.currencyFallback && targetCurrency != 'rub' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Курс ЦБ РФ недоступен. Показаны суммы в рублях.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = HomeScreenStatus.error;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _changeCurrency(String currency) async {
    if (_currency == currency || _status == HomeScreenStatus.loading) {
      return;
    }

    await _load(currency: currency);
  }

  Future<void> _editSubscription(SubscriptionItemVm item) async {
    try {
      final api = ref.read(apiClientProvider);
      final responses = await Future.wait<dynamic>(<Future<dynamic>>[
        api.getData('/payment-methods'),
        api.getData('/banks'),
      ]);

      final paymentMethods = asMapList(responses[0]);
      final banks = asMapList(responses[1]);

      if (!mounted) {
        return;
      }

      final result = await showEditSubscriptionDialog(
        context: context,
        item: item,
        currency: _currency,
        paymentMethods: paymentMethods,
        banks: banks,
      );

      if (result == null) {
        return;
      }

      await api.patchData(
        '/user-subscriptions/${item.id}',
        body: <String, dynamic>{
          'nextPaymentAt': result.nextPaymentAt,
          'paymentMethodId': result.paymentMethodId,
          'newPaymentMethodBankId': result.newPaymentMethodBankId,
          'newPaymentMethodCardNumber': result.newPaymentMethodCardNumber,
        },
      );

      await _load(currency: _currency);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Подписка ${item.typeName} обновлена.')),
      );
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось обновить подписку.')),
      );
    }
  }

  Future<void> _deleteSubscription(SubscriptionItemVm item) async {
    final confirmed = await showDeleteSubscriptionDialog(
      context: context,
      subscriptionName: item.typeName,
    );

    if (!confirmed) {
      return;
    }

    try {
      await ref
          .read(apiClientProvider)
          .deleteData('/user-subscriptions/${item.id}');
      await _load(currency: _currency);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Подписка ${item.typeName} удалена.')),
      );
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить подписку.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreenBody(
      status: _status,
      data: _data,
      errorMessage: _errorMessage,
      onRefresh: _load,
      onRetry: _load,
      onNotificationsTap: () => context.push('/notifications'),
      onProfileTap: () => context.push('/profile'),
      onSearchTap: () => context.push('/search'),
      onCurrencyChange: (currency) => _changeCurrency(currency),
      onSubscriptionEdit: (item) => _editSubscription(item),
      onSubscriptionDelete: (item) => _deleteSubscription(item),
    );
  }
}
