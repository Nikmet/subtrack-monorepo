import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class SettingsPaymentMethodsScreen extends ConsumerStatefulWidget {
  const SettingsPaymentMethodsScreen({super.key});

  @override
  ConsumerState<SettingsPaymentMethodsScreen> createState() => _SettingsPaymentMethodsScreenState();
}

class _SettingsPaymentMethodsScreenState extends ConsumerState<SettingsPaymentMethodsScreen> {
  bool _loading = true;
  bool _creating = false;

  List<Map<String, dynamic>> _banks = const [];
  List<Map<String, dynamic>> _methods = const [];

  final _cardNumber = TextEditingController();
  String? _selectedBankId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cardNumber.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final api = ref.read(apiClientProvider);
    final banks = asMapList(await api.getData('/banks'));
    final methods = asMapList(await api.getData('/payment-methods'));

    setState(() {
      _banks = banks;
      _methods = methods;
      _selectedBankId = banks.isNotEmpty ? (banks.first['id'] ?? '').toString() : null;
      _loading = false;
    });
  }

  Future<void> _create() async {
    if (_selectedBankId == null || _selectedBankId!.isEmpty) {
      return;
    }

    final cardNumber = _cardNumber.text.trim();
    if (cardNumber.length < 4) {
      return;
    }

    setState(() => _creating = true);
    try {
      await ref.read(apiClientProvider).postData('/payment-methods', body: {
        'bankId': _selectedBankId,
        'cardNumber': cardNumber,
      });
      _cardNumber.clear();
      await _load();
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _setDefault(String id) async {
    await ref.read(apiClientProvider).patchData('/payment-methods/$id/default', body: {});
    await _load();
  }

  Future<void> _delete(String id) async {
    await ref.read(apiClientProvider).deleteData('/payment-methods/$id', body: {});
    await _load();
  }

  Future<void> _update(String id, String bankId, String cardNumber) async {
    await ref.read(apiClientProvider).patchData('/payment-methods/$id', body: {
      'bankId': bankId,
      'cardNumber': cardNumber,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('пїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBankId,
                  items: _banks
                      .map(
                        (bank) => DropdownMenuItem(
                          value: (bank['id'] ?? '').toString(),
                          child: Text((bank['name'] ?? '').toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedBankId = value),
                  decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅ'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cardNumber,
                  decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _creating ? null : _create,
                  child: Text(_creating ? 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ...' : 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ'),
                ),
              ],
            ),
          ),
          ..._methods.map((method) {
            final id = (method['id'] ?? '').toString();
            final bank = asMap(method['bank']);
            final bankId = (method['bankId'] ?? '').toString();
            final cardNumber = (method['cardNumber'] ?? '').toString();
            final subscriptionsCount = asMap(method['_count'])['subscriptions'] ?? 0;
            final isDefault = method['isDefault'] == true;

            return _PaymentMethodCard(
              key: ValueKey(id),
              title: '${bank['name'] ?? 'пїЅпїЅпїЅпїЅ'} пїЅ $cardNumber',
              subscriptionsCount: subscriptionsCount.toString(),
              isDefault: isDefault,
              banks: _banks,
              bankId: bankId,
              cardNumber: cardNumber,
              onSetDefault: isDefault ? null : () => _setDefault(id),
              onDelete: () => _delete(id),
              onSave: (newBankId, newCard) => _update(id, newBankId, newCard),
            );
          }),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatefulWidget {
  const _PaymentMethodCard({
    super.key,
    required this.title,
    required this.subscriptionsCount,
    required this.isDefault,
    required this.banks,
    required this.bankId,
    required this.cardNumber,
    required this.onDelete,
    required this.onSave,
    this.onSetDefault,
  });

  final String title;
  final String subscriptionsCount;
  final bool isDefault;
  final List<Map<String, dynamic>> banks;
  final String bankId;
  final String cardNumber;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;
  final Future<void> Function(String bankId, String cardNumber) onSave;

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  late TextEditingController _cardController;
  late String _bankId;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _cardController = TextEditingController(text: widget.cardNumber);
    _bankId = widget.bankId;
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _pending = true);
    try {
      await widget.onSave(_bankId, _cardController.text.trim());
    } finally {
      if (mounted) {
        setState(() => _pending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium)),
              if (widget.isDefault)
                const Chip(label: Text('пїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ')),
            ],
          ),
          Text('пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ: ${widget.subscriptionsCount}'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _bankId,
            items: widget.banks
                .map(
                  (bank) => DropdownMenuItem(
                    value: (bank['id'] ?? '').toString(),
                    child: Text((bank['name'] ?? '').toString()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _bankId = value ?? _bankId),
            decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅ'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cardController,
            decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: _pending ? null : _save,
                child: const Text('пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
              ),
              if (widget.onSetDefault != null)
                OutlinedButton(
                  onPressed: _pending ? null : widget.onSetDefault,
                  child: const Text('пїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
                ),
              OutlinedButton(
                onPressed: _pending ? null : widget.onDelete,
                child: const Text('пїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
