import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/shared/providers.dart';

class NewSubscriptionScreen extends ConsumerStatefulWidget {
  const NewSubscriptionScreen({super.key});

  @override
  ConsumerState<NewSubscriptionScreen> createState() => _NewSubscriptionScreenState();
}

class _NewSubscriptionScreenState extends ConsumerState<NewSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();

  String _category = 'other';
  int _period = 1;
  bool _pending = false;
  String _iconUrl = '';

  static const categories = [
    'streaming',
    'music',
    'games',
    'shopping',
    'ai',
    'finance',
    'other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _upload(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) {
      return;
    }

    final api = ref.read(apiClientProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final response = await api.uploadFile('/uploads/icon', form);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final url = (map['url'] ?? '').toString();

    if (url.isNotEmpty) {
      setState(() {
        _iconUrl = url;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _pending = true);

    try {
      await ref.read(apiClientProvider).postData('/common-subscriptions', body: {
        'name': _name.text.trim(),
        'imgLink': _iconUrl,
        'category': _category,
        'price': double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0,
        'period': _period,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _pending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_iconUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_iconUrl, height: 120, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8E1EC)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('пїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _upload(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('пїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _upload(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('пїЅпїЅпїЅпїЅпїЅпїЅ'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
                validator: (value) => (value ?? '').trim().length < 2 ? 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅ 2 пїЅпїЅпїЅпїЅпїЅпїЅпїЅ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
                validator: (value) {
                  final amount = double.tryParse((value ?? '').replaceAll(',', '.')) ?? 0;
                  if (amount <= 0) return 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _category = value ?? 'other'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _period,
                decoration: const InputDecoration(labelText: 'пїЅпїЅпїЅпїЅпїЅпїЅ (пїЅпїЅпїЅпїЅпїЅпїЅпїЅ)'),
                items: const [1, 3, 6, 12]
                    .map((p) => DropdownMenuItem<int>(value: p, child: Text('$p')))
                    .toList(),
                onChanged: (value) => setState(() => _period = value ?? 1),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _pending ? null : _submit,
                child: Text(_pending ? 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ...' : 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
