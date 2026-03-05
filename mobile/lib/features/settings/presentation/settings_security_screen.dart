import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shared/providers.dart';

class SettingsSecurityScreen extends ConsumerStatefulWidget {
  const SettingsSecurityScreen({super.key});

  @override
  ConsumerState<SettingsSecurityScreen> createState() => _SettingsSecurityScreenState();
}

class _SettingsSecurityScreenState extends ConsumerState<SettingsSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _pending = false;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _pending = true);
    try {
      await ref.read(apiClientProvider).patchData('/settings/security/password', body: {
        'currentPassword': _current.text,
        'newPassword': _newPass.text,
        'confirmPassword': _confirm.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль изменен')),
      );
      _current.clear();
      _newPass.clear();
      _confirm.clear();
    } finally {
      if (mounted) {
        setState(() => _pending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Безопасность')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Текущий пароль'),
                validator: (value) => (value ?? '').isEmpty ? 'Введите текущий пароль' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                validator: (value) {
                  if ((value ?? '').length < 8) return 'Минимум 8 символов';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Подтверждение'),
                validator: (value) {
                  if ((value ?? '') != _newPass.text) return 'Пароли не совпадают';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _pending ? null : _save,
                child: Text(_pending ? 'Сохранение...' : 'Сменить пароль'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
