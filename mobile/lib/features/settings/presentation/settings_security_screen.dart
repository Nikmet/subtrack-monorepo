import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_failure.dart';
import '../../../features/shared/providers.dart';
import 'settings_models.dart';
import 'settings_widgets.dart';

class SettingsSecurityScreen extends ConsumerStatefulWidget {
  const SettingsSecurityScreen({super.key});

  @override
  ConsumerState<SettingsSecurityScreen> createState() => _SettingsSecurityScreenState();
}

class _SettingsSecurityScreenState extends ConsumerState<SettingsSecurityScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _pending = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_currentController.text.isEmpty || _newController.text.isEmpty || _confirmController.text.isEmpty) {
      showSettingsSnackBar(context, 'Заполните все поля формы.');
      return;
    }
    if (_newController.text.length < 8) {
      showSettingsSnackBar(context, 'Новый пароль должен быть не короче 8 символов.');
      return;
    }
    if (_newController.text != _confirmController.text) {
      showSettingsSnackBar(context, 'Новый пароль и подтверждение не совпадают.');
      return;
    }

    setState(() {
      _pending = true;
    });

    try {
      await ref.read(apiClientProvider).patchData(
        '/settings/security/password',
        body: <String, dynamic>{
          'currentPassword': _currentController.text,
          'newPassword': _newController.text,
          'confirmPassword': _confirmController.text,
        },
      );

      if (!mounted) {
        return;
      }
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      showSettingsSnackBar(context, 'Пароль обновлен.');
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, mapSecurityFailureToMessage(failure, _newController.text));
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Заполните все поля формы.');
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
    return SettingsScaffold(
      title: 'Безопасность',
      location: '/settings/security',
      backRoute: '/settings',
      child: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 112),
        children: <Widget>[
          SettingsCardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SettingsFormLabel('Текущий пароль'),
                const SizedBox(height: 8),
                TextField(
                  controller: _currentController,
                  obscureText: true,
                  decoration: settingsInputDecoration(),
                ),
                const SizedBox(height: 10),
                const SettingsFormLabel('Новый пароль'),
                const SizedBox(height: 8),
                TextField(
                  controller: _newController,
                  obscureText: true,
                  decoration: settingsInputDecoration(),
                ),
                const SizedBox(height: 10),
                const SettingsFormLabel('Подтвердите новый пароль'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: settingsInputDecoration(),
                ),
                const SizedBox(height: 16),
                SettingsPrimaryButton(
                  text: _pending ? 'Сохранение...' : 'Изменить пароль',
                  onTap: _pending ? null : _save,
                  enabled: !_pending,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
