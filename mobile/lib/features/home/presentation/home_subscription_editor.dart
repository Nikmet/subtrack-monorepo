import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui_kit/tokens.dart';
import '../../../features/shared/parsers.dart';
import 'home_formatters.dart';
import 'home_models.dart';

const String newPaymentMethodValue = '__new__';

class EditSubscriptionDialogResult {
  const EditSubscriptionDialogResult({
    required this.nextPaymentAt,
    required this.paymentMethodId,
    required this.newPaymentMethodBankId,
    required this.newPaymentMethodCardNumber,
  });

  final String nextPaymentAt;
  final String paymentMethodId;
  final String newPaymentMethodBankId;
  final String newPaymentMethodCardNumber;
}

Future<EditSubscriptionDialogResult?> showEditSubscriptionDialog({
  required BuildContext context,
  required SubscriptionItemVm item,
  required String currency,
  required List<Map<String, dynamic>> paymentMethods,
  required List<Map<String, dynamic>> banks,
}) {
  return showDialog<EditSubscriptionDialogResult>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return EditSubscriptionDialog(
        item: item,
        currency: currency,
        paymentMethods: paymentMethods,
        banks: banks,
      );
    },
  );
}

class EditSubscriptionDialog extends ConsumerStatefulWidget {
  const EditSubscriptionDialog({
    super.key,
    required this.item,
    required this.currency,
    required this.paymentMethods,
    required this.banks,
  });

  final SubscriptionItemVm item;
  final String currency;
  final List<Map<String, dynamic>> paymentMethods;
  final List<Map<String, dynamic>> banks;

  @override
  ConsumerState<EditSubscriptionDialog> createState() =>
      _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState
    extends ConsumerState<EditSubscriptionDialog> {
  late String _paymentMethodId;
  late String _newBankId;
  late DateTime _nextPaymentAt;
  final TextEditingController _cardController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _paymentMethodId = _defaultPaymentMethodId(
      widget.paymentMethods,
      widget.item.paymentMethodId,
    );
    _newBankId = widget.banks.isNotEmpty
        ? (widget.banks.first['id'] ?? '').toString()
        : '';
    _nextPaymentAt = widget.item.nextPaymentAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  bool get _showNewPaymentMethodForm =>
      _paymentMethodId == newPaymentMethodValue;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPaymentAt,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      locale: const Locale('ru', 'RU'),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _nextPaymentAt = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _submit() {
    if (_showNewPaymentMethodForm) {
      if (_newBankId.isEmpty) {
        setState(() => _error = 'Выберите банк.');
        return;
      }
      if (_cardController.text.trim().length < 4) {
        setState(
          () => _error = 'Укажите номер карты минимум из 4 символов.',
        );
        return;
      }
    } else if (_paymentMethodId.isEmpty) {
      setState(() => _error = 'Выберите способ оплаты.');
      return;
    }

    Navigator.of(context).pop(
      EditSubscriptionDialogResult(
        nextPaymentAt: _dateIso(_nextPaymentAt),
        paymentMethodId: _showNewPaymentMethodForm ? '' : _paymentMethodId,
        newPaymentMethodBankId: _showNewPaymentMethodForm ? _newBankId : '',
        newPaymentMethodCardNumber:
            _showNewPaymentMethodForm ? _cardController.text.trim() : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: UiTokens.radius16,
          border: Border.all(color: const Color(0xFFD4DEEA)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x3309182B),
              blurRadius: 48,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Редактировать подписку',
                    style: TextStyle(
                      color: Color(0xFF142B45),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: UiTokens.radius10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9EFF7),
                      borderRadius: UiTokens.radius10,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF4F627A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ServiceCard(
              iconUrl: widget.item.typeImage,
              name: widget.item.typeName,
              meta:
                  '${widget.item.categoryName} • ${formatMoney(widget.item.price, widget.currency)} • ${formatPeriodLabel(widget.item.period)}',
            ),
            const SizedBox(height: 12),
            const _FieldLabel(text: 'ДАТА ОПЛАТЫ'),
            const SizedBox(height: 5),
            InkWell(
              onTap: _pickDate,
              borderRadius: UiTokens.radius10,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FA),
                  borderRadius: UiTokens.radius10,
                  border: Border.all(color: const Color(0xFFD4DEEA)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _dateRu(_nextPaymentAt),
                        style: const TextStyle(
                          color: Color(0xFF182D49),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _FieldLabel(text: 'СПОСОБ ОПЛАТЫ'),
            const SizedBox(height: 5),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: UiTokens.radius10,
                border: Border.all(color: const Color(0xFFD4DEEA)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _paymentMethodId,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more),
                  items: <DropdownMenuItem<String>>[
                    ...widget.paymentMethods.map((method) {
                      final bankName =
                          asMap(method['bank'])['name']?.toString() ?? 'Банк';
                      final cardNumber =
                          (method['cardNumber'] ?? '').toString();
                      final isDefault = method['isDefault'] == true;
                      final label =
                          '${_paymentLabel(bankName, cardNumber)}${isDefault ? ' (по умолчанию)' : ''}';
                      return DropdownMenuItem<String>(
                        value: (method['id'] ?? '').toString(),
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF182D49),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }),
                    if (widget.banks.isNotEmpty)
                      const DropdownMenuItem<String>(
                        value: newPaymentMethodValue,
                        child: Text('Новая карта'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _paymentMethodId = value;
                      _error = null;
                    });
                  },
                ),
              ),
            ),
            if (_showNewPaymentMethodForm) ...<Widget>[
              const SizedBox(height: 10),
              const _FieldLabel(text: 'БАНК'),
              const SizedBox(height: 5),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FA),
                  borderRadius: UiTokens.radius10,
                  border: Border.all(color: const Color(0xFFD4DEEA)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _newBankId.isEmpty ? null : _newBankId,
                    isExpanded: true,
                    items: widget.banks
                        .map(
                          (bank) => DropdownMenuItem<String>(
                            value: (bank['id'] ?? '').toString(),
                            child: Text((bank['name'] ?? '').toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() => _newBankId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _FieldLabel(text: 'НОМЕР КАРТЫ'),
              const SizedBox(height: 5),
              TextField(
                controller: _cardController,
                decoration: const InputDecoration(
                  hintText: 'Например, **** 4242',
                  isDense: true,
                  filled: true,
                  fillColor: Color(0xFFF3F6FA),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: UiTokens.radius10,
                    borderSide: BorderSide(color: Color(0xFFD4DEEA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: UiTokens.radius10,
                    borderSide: BorderSide(color: Color(0xFF79AAC8)),
                  ),
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFB3261E),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _submit,
              borderRadius: UiTokens.radius12,
              child: Container(
                height: 44,
                decoration: const BoxDecoration(
                  borderRadius: UiTokens.radius12,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF1FB8CE), Color(0xFF43E0CA)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Сохранить',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _defaultPaymentMethodId(
    List<Map<String, dynamic>> methods,
    String? currentPaymentMethodId,
  ) {
    if (currentPaymentMethodId != null && currentPaymentMethodId.isNotEmpty) {
      return currentPaymentMethodId;
    }
    if (methods.isEmpty) {
      return newPaymentMethodValue;
    }

    final defaultMethod =
        methods.where((item) => item['isDefault'] == true).toList();
    final selected =
        defaultMethod.isNotEmpty ? defaultMethod.first : methods.first;
    return (selected['id'] ?? '').toString();
  }

  static String _dateIso(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _dateRu(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  static String _paymentLabel(String bankName, String cardNumber) {
    final safeBank = bankName.trim().isEmpty ? 'Банк' : bankName.trim();
    final safeCard = cardNumber.trim().isEmpty ? '****' : cardNumber.trim();
    return '$safeBank • $safeCard';
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.iconUrl,
    required this.name,
    required this.meta,
  });

  final String iconUrl;
  final String name;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final firstLetter =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FA),
        borderRadius: UiTokens.radius12,
        border: Border.all(color: const Color(0xFFD8E2EE)),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: UiTokens.radius10,
            child: SizedBox(
              width: 40,
              height: 40,
              child: iconUrl.trim().isEmpty
                  ? Container(
                      color: const Color(0xFFE4EBF4),
                      child: Center(
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: Color(0xFF8494A8),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        color: const Color(0xFFE4EBF4),
                        child: Center(
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                              color: Color(0xFF8494A8),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF122842),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6C819B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9AAABD),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}
