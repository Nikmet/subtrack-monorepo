import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/api_failure.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import 'settings_models.dart';
import 'settings_widgets.dart';

class SettingsProfileScreen extends ConsumerStatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  ConsumerState<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends ConsumerState<SettingsProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _avatarController = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String? _uploadErrorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ref.read(apiClientProvider).getData('/settings/profile');
      final data = SettingsProfileData.fromJson(asMap(raw));
      _nameController.text = data.name;
      _emailController.text = data.email;
      _avatarController.text = data.avatarLink ?? '';

      if (!mounted) {
        return;
      }
      setState(() {
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

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }

    final size = await File(file.path).length();
    if (size > 10 * 1024 * 1024) {
      setState(() {
        _uploadErrorText = 'Размер файла аватара не должен превышать 10MB.';
      });
      return;
    }

    setState(() {
      _uploading = true;
      _uploadErrorText = null;
    });

    try {
      final form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await ref.read(apiClientProvider).uploadFile('/uploads/avatar', form);
      final url = response is Map<String, dynamic> ? (response['url'] ?? '').toString() : '';

      if (url.isEmpty) {
        setState(() {
          _uploadErrorText = 'Не удалось загрузить аватар.';
        });
      } else {
        _avatarController.text = url;
      }
    } on ApiFailure catch (failure) {
      setState(() {
        _uploadErrorText = failure.message.isEmpty ? 'Не удалось загрузить аватар.' : failure.message;
      });
    } catch (_) {
      setState(() {
        _uploadErrorText = 'Ошибка загрузки. Попробуйте снова.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final validationMessage = validateProfileForm(
      name: _nameController.text,
      email: _emailController.text,
      avatarLink: _avatarController.text,
    );

    if (validationMessage != null) {
      showSettingsSnackBar(context, validationMessage);
      return;
    }

    setState(() {
      _saving = true;
      _uploadErrorText = null;
    });

    final normalizedName = _nameController.text.trim();
    final normalizedEmail = _emailController.text.trim().toLowerCase();
    final normalizedAvatar = _avatarController.text.trim();

    try {
      await ref.read(apiClientProvider).patchData(
        '/settings/profile',
        body: <String, dynamic>{
          'name': normalizedName,
          'email': normalizedEmail,
          'avatarLink': normalizedAvatar.isEmpty ? null : normalizedAvatar,
        },
      );

      final auth = ref.read(authControllerProvider);
      final currentUser = auth.user;
      if (currentUser != null) {
        ref.read(authControllerProvider.notifier).replaceUser(
              currentUser.copyWith(
                name: normalizedName,
                email: normalizedEmail,
                avatarLink: normalizedAvatar.isEmpty ? null : normalizedAvatar,
              ),
            );
      }

      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Профиль обновлен.');
    } on ApiFailure catch (failure) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, mapProfileFailureToMessage(failure));
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Проверьте корректность имени, email и ссылки на аватар.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Профиль',
      location: '/settings/profile',
      backRoute: '/settings',
      child: Builder(
        builder: (context) {
          if (_loading) {
            return const SettingsLoadingView();
          }
          if (_error != null) {
            return SettingsErrorView(
              message: _error ?? 'Не удалось загрузить профиль.',
              onRetry: _load,
            );
          }

          return ListView(
            padding: const EdgeInsets.only(top: 14, bottom: 112),
            children: <Widget>[
              SettingsCardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SettingsAvatar(
                      name: _nameController.text,
                      imageUrl: _avatarController.text,
                      size: 90,
                    ),
                    const SizedBox(height: 8),
                    SettingsActionButton(
                      text: _uploading ? 'Загрузка...' : 'Загрузить аватар',
                      backgroundColor: const Color(0xFFE2F1FF),
                      textColor: const Color(0xFF1F5D95),
                      onTap: _uploading ? null : _pickAvatar,
                      height: 34,
                      enabled: !_uploading,
                    ),
                    if (_uploadErrorText != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        _uploadErrorText!,
                        style: const TextStyle(
                          color: Color(0xFFBD2D45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const SettingsFormLabel('Имя'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: settingsInputDecoration(),
                    ),
                    const SizedBox(height: 10),
                    const SettingsFormLabel('Email'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: settingsInputDecoration(),
                    ),
                    const SizedBox(height: 10),
                    const SettingsFormLabel('URL аватара'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _avatarController,
                      keyboardType: TextInputType.url,
                      decoration: settingsInputDecoration(),
                    ),
                    const SizedBox(height: 14),
                    SettingsPrimaryButton(
                      text: _saving ? 'Сохранение...' : 'Сохранить',
                      onTap: (_saving || _uploading) ? null : _save,
                      enabled: !_saving && !_uploading,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
