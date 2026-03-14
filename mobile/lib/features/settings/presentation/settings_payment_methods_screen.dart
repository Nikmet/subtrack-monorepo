import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_failure.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import 'settings_models.dart';
import 'settings_widgets.dart';

class SettingsPaymentMethodsScreen extends ConsumerStatefulWidget {
  const SettingsPaymentMethodsScreen({super.key});

  @override
  ConsumerState<SettingsPaymentMethodsScreen> createState() => _SettingsPaymentMethodsScreenState();
}

class _SettingsPaymentMethodsScreenState extends ConsumerState<SettingsPaymentMethodsScreen> {
  final _createCardController = TextEditingController();

  bool _loading = true;
  bool _isCreating = false;
  String? _error;
  String? _selectedBankId;
  List<SettingsBank> _banks = const <SettingsBank>[];
  List<SettingsPaymentMethod> _methods = const <SettingsPaymentMethod>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _createCardController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final responses = await Future.wait<dynamic>(<Future<dynamic>>[
        api.getData('/banks'),
        api.getData('/payment-methods'),
      ]);

      final banks = asMapList(responses[0]).map(SettingsBank.fromJson).toList();
      final methods = asMapList(responses[1]).map(SettingsPaymentMethod.fromJson).toList();
      final selectedBank = banks.any((bank) => bank.id == _selectedBankId)
          ? _selectedBankId
          : (banks.isEmpty ? null : banks.first.id);

      if (!mounted) {
        return;
      }
      setState(() {
        _banks = banks;
        _methods = methods;
        _selectedBankId = selectedBank;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final bankId = _selectedBankId;
    final cardNumber = _createCardController.text.trim();

    if (bankId == null || bankId.isEmpty || cardNumber.length < 4) {
      showSettingsSnackBar(context, 'Введите корректное название способа оплаты.');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await ref.read(apiClientProvider).postData(
        '/payment-methods',
        body: <String, dynamic>{
          'bankId': bankId,
          'cardNumber': cardNumber,
        },
      );

      final bankName = _banks.firstWhere((bank) => bank.id == bankId).name;
      await _load();
      _createCardController.clear();

      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, '${formatPaymentMethodLabel(bankName, cardNumber)} добавлен.');
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, mapPaymentMethodFailureToMessage(failure));
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Введите корректное название способа оплаты.');
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _updateMethod(SettingsPaymentMethod method, String bankId, String cardNumber) async {
    try {
      await ref.read(apiClientProvider).patchData(
        '/payment-methods/${method.id}',
        body: <String, dynamic>{
          'bankId': bankId,
          'cardNumber': cardNumber,
        },
      );

      final bankName = _banks.firstWhere((bank) => bank.id == bankId).name;
      await _load();
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, '${formatPaymentMethodLabel(bankName, cardNumber)} обновлен.');
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, mapPaymentMethodFailureToMessage(failure));
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Введите корректное название способа оплаты.');
    }
  }

  Future<void> _setDefault(SettingsPaymentMethod method) async {
    try {
      await ref.read(apiClientProvider).patchData(
        '/payment-methods/${method.id}/default',
        body: <String, dynamic>{},
      );
      await _load();
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, '${formatPaymentMethodLabel(method.bankName, method.cardNumber)} выбран по умолчанию.');
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, mapPaymentMethodFailureToMessage(failure));
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Введите корректное название способа оплаты.');
    }
  }

  Future<void> _deleteMethod(SettingsPaymentMethod method) async {
    try {
      await ref.read(apiClientProvider).deleteData(
        '/payment-methods/${method.id}',
        body: <String, dynamic>{},
      );
      await _load();
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, '${formatPaymentMethodLabel(method.bankName, method.cardNumber)} удален.');
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, mapPaymentMethodFailureToMessage(failure));
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Введите корректное название способа оплаты.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Способы оплаты',
      location: '/settings/payment-methods',
      backRoute: '/settings',
      child: Builder(
        builder: (context) {
          if (_loading) {
            return const SettingsLoadingView();
          }
          if (_error != null) {
            return SettingsErrorView(
              message: _error ?? 'Не удалось загрузить способы оплаты.',
              onRetry: _load,
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 14, bottom: 112),
              children: <Widget>[
                const SettingsSectionTitle(text: 'Новый способ оплаты'),
                if (_banks.isNotEmpty)
                  SettingsCardBox(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          key: ValueKey<String?>(_selectedBankId),
                          initialValue: _selectedBankId,
                          items: _banks
                              .map(
                                (bank) => DropdownMenuItem<String>(
                                  value: bank.id,
                                  child: Text(bank.name),
                                ),
                              )
                              .toList(),
                          decoration: settingsInputDecoration(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBankId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _createCardController,
                          decoration: settingsInputDecoration(
                            hintText: 'Номер карты, например **** 4242',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SettingsPrimaryButton(
                          text: _isCreating ? 'Создание...' : 'Создать',
                          onTap: _isCreating ? null : _create,
                          enabled: !_isCreating,
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Банки не настроены. Добавьте их в админ-панели.',
                      style: TextStyle(
                        color: Color(0xFF6B7F99),
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                const SettingsSectionTitle(text: 'Мои карты'),
                if (_methods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Сохраненных способов оплаты пока нет.',
                      style: TextStyle(
                        color: Color(0xFF6B7F99),
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  ..._methods.map(
                    (method) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentMethodCard(
                        method: method,
                        banks: _banks,
                        onSave: (bankId, cardNumber) => _updateMethod(method, bankId, cardNumber),
                        onSetDefault: method.isDefault ? null : () => _setDefault(method),
                        onDelete: () => _deleteMethod(method),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentMethodCard extends StatefulWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.banks,
    required this.onSave,
    required this.onDelete,
    this.onSetDefault,
  });

  final SettingsPaymentMethod method;
  final List<SettingsBank> banks;
  final Future<void> Function(String bankId, String cardNumber) onSave;
  final Future<void> Function() onDelete;
  final Future<void> Function()? onSetDefault;

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  late final TextEditingController _cardController;
  late String _selectedBankId;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _cardController = TextEditingController(text: widget.method.cardNumber);
    _selectedBankId = widget.method.bankId;
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _pending = true;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCardBox(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD6E0EC)),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.method.bankIconLink.isEmpty
                    ? const Icon(Icons.account_balance_wallet_outlined, size: 18)
                    : Image.network(
                        widget.method.bankIconLink,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.account_balance_wallet_outlined, size: 18),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatPaymentMethodLabel(widget.method.bankName, widget.method.cardNumber),
                  style: const TextStyle(
                    color: Color(0xFF10253F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (widget.method.isDefault)
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEF8E8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'По умолчанию',
                    style: TextStyle(
                      color: Color(0xFF0F7A3F),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Подписок: ${widget.method.subscriptionsCount}',
            style: const TextStyle(
              color: Color(0xFF6B7F99),
              fontSize: 12,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>(_selectedBankId),
            initialValue: _selectedBankId,
            items: widget.banks
                .map(
                  (bank) => DropdownMenuItem<String>(
                    value: bank.id,
                    child: Text(bank.name),
                  ),
                )
                .toList(),
            decoration: settingsInputDecoration(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedBankId = value;
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cardController,
            decoration: settingsInputDecoration(),
          ),
          const SizedBox(height: 8),
          SettingsSecondaryButton(
            text: _pending ? 'Сохранение...' : 'Сохранить',
            onTap: _pending
                ? null
                : () => _run(
                      () => widget.onSave(_selectedBankId, _cardController.text.trim()),
                    ),
            enabled: !_pending,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (widget.onSetDefault != null)
                SizedBox(
                  width: 140,
                  child: SettingsSecondaryButton(
                    text: _pending ? 'Сохранение...' : 'Сделать основным',
                    onTap: _pending ? null : () => _run(widget.onSetDefault!),
                    enabled: !_pending,
                  ),
                ),
              SettingsDeleteButton(
                text: _pending ? 'Удаление...' : 'Удалить',
                onTap: _pending ? null : () => _run(widget.onDelete),
                enabled: !_pending,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
