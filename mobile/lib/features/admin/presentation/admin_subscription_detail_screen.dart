import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';

class AdminSubscriptionDetailScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionDetailScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  ConsumerState<AdminSubscriptionDetailScreen> createState() => _AdminSubscriptionDetailScreenState();
}

class _AdminSubscriptionDetailScreenState extends ConsumerState<AdminSubscriptionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _imgLink = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _period = TextEditingController();
  final _comment = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _imgLink.dispose();
    _category.dispose();
    _price.dispose();
    _period.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await ref.read(apiClientProvider).getData('/admin/subscriptions/${widget.subscriptionId}');
    final data = asMap(raw);

    _name.text = (data['name'] ?? '').toString();
    _imgLink.text = (data['imgLink'] ?? '').toString();
    _category.text = (data['category'] ?? '').toString();
    _price.text = (data['price'] ?? '').toString();
    _period.text = (data['period'] ?? '').toString();
    _comment.text = (data['moderationComment'] ?? '').toString();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).patchData('/admin/subscriptions/${widget.subscriptionId}', body: {
        'name': _name.text.trim(),
        'imgLink': _imgLink.text.trim(),
        'category': _category.text.trim(),
        'price': double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0,
        'period': int.tryParse(_period.text.trim()) ?? 1,
        'moderationComment': _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изменения сохранены')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование подписки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (value) => (value ?? '').trim().length < 2 ? 'Введите минимум 2 символа' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _imgLink, decoration: const InputDecoration(labelText: 'URL картинки')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Категория'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Введите категорию' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Цена'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _period,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Период (дни)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _comment,
                decoration: const InputDecoration(labelText: 'Модерационный комментарий'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Сохранение...' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
