import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';

class SettingsProfileScreen extends ConsumerStatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  ConsumerState<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends ConsumerState<SettingsProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _avatarUrl = TextEditingController();
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
    _email.dispose();
    _avatarUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raw = await ref.read(apiClientProvider).getData('/settings/profile');
    final data = asMap(raw);

    _name.text = (data['name'] ?? '').toString();
    _email.text = (data['email'] ?? '').toString();
    _avatarUrl.text = (data['avatarLink'] ?? '').toString();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) {
      return;
    }

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final response = await ref.read(apiClientProvider).uploadFile('/uploads/avatar', form);
    final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final url = (map['url'] ?? '').toString();

    if (url.isNotEmpty) {
      setState(() {
        _avatarUrl.text = url;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    await ref.read(apiClientProvider).patchData('/settings/profile', body: {
      'name': _name.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'avatarLink': _avatarUrl.text.trim().isEmpty ? null : _avatarUrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль обновлен')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_avatarUrl.text.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _avatarUrl.text.trim(),
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _uploadAvatar(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Галерея'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _uploadAvatar(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Камера'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Имя'),
                validator: (value) => (value ?? '').trim().length < 2 ? 'Введите минимум 2 символа' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty || !v.contains('@')) return 'Введите корректный email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarUrl,
                decoration: const InputDecoration(labelText: 'URL аватара'),
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
