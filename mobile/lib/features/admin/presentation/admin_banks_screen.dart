import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import '../../shared/widgets.dart';

class AdminBanksScreen extends ConsumerStatefulWidget {
  const AdminBanksScreen({super.key});

  @override
  ConsumerState<AdminBanksScreen> createState() => _AdminBanksScreenState();
}

class _AdminBanksScreenState extends ConsumerState<AdminBanksScreen> {
  bool _loading = true;
  bool _creating = false;

  List<Map<String, dynamic>> _banks = const [];
  final _name = TextEditingController();
  final _iconLink = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _iconLink.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await ref.read(apiClientProvider).getData('/admin/banks');
    setState(() {
      _banks = asMapList(raw);
      _loading = false;
    });
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2 || _iconLink.text.trim().isEmpty) {
      return;
    }

    setState(() => _creating = true);
    try {
      await ref.read(apiClientProvider).postData('/admin/banks', body: {
        'name': _name.text.trim(),
        'iconLink': _iconLink.text.trim(),
      });
      _name.clear();
      _iconLink.clear();
      await _load();
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _update(String id, String name, String iconLink) async {
    await ref.read(apiClientProvider).patchData('/admin/banks/$id', body: {
      'name': name,
      'iconLink': iconLink,
    });
    await _load();
  }

  Future<void> _delete(String id) async {
    await ref.read(apiClientProvider).deleteData('/admin/banks/$id');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Банки')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Новый банк', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
                const SizedBox(height: 8),
                TextField(controller: _iconLink, decoration: const InputDecoration(labelText: 'URL иконки')),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _creating ? null : _create,
                  child: Text(_creating ? 'Создание...' : 'Создать'),
                ),
              ],
            ),
          ),
          ..._banks.map((bank) => _BankCard(bank: bank, onSave: _update, onDelete: _delete)),
        ],
      ),
    );
  }
}

class _BankCard extends StatefulWidget {
  const _BankCard({required this.bank, required this.onSave, required this.onDelete});

  final Map<String, dynamic> bank;
  final Future<void> Function(String id, String name, String iconLink) onSave;
  final Future<void> Function(String id) onDelete;

  @override
  State<_BankCard> createState() => _BankCardState();
}

class _BankCardState extends State<_BankCard> {
  late TextEditingController _name;
  late TextEditingController _icon;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: (widget.bank['name'] ?? '').toString());
    _icon = TextEditingController(text: (widget.bank['iconLink'] ?? '').toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = (widget.bank['id'] ?? '').toString();
    if (id.isEmpty) return;
    setState(() => _pending = true);
    try {
      await widget.onSave(id, _name.text.trim(), _icon.text.trim());
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _delete() async {
    final id = (widget.bank['id'] ?? '').toString();
    if (id.isEmpty) return;
    setState(() => _pending = true);
    try {
      await widget.onDelete(id);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
          const SizedBox(height: 8),
          TextField(controller: _icon, decoration: const InputDecoration(labelText: 'URL иконки')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: _pending ? null : _save,
                child: const Text('Сохранить'),
              ),
              OutlinedButton(
                onPressed: _pending ? null : _delete,
                child: const Text('Удалить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
