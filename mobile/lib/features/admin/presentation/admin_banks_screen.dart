import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/api_failure.dart';
import '../../shared/parsers.dart';
import '../../shared/providers.dart';
import '../../settings/presentation/settings_widgets.dart';
import 'admin_models.dart';
import 'admin_widgets.dart';

class AdminBanksScreen extends ConsumerStatefulWidget {
  const AdminBanksScreen({super.key});

  @override
  ConsumerState<AdminBanksScreen> createState() => _AdminBanksScreenState();
}

class _AdminBanksScreenState extends ConsumerState<AdminBanksScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _creating = false;
  String? _error;
  List<AdminBankItem> _banks = const <AdminBankItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ref.read(apiClientProvider).getData('/admin/banks');
      if (!mounted) {
        return;
      }
      setState(() {
        _banks = asMapList(raw).map(AdminBankItem.fromJson).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is ApiFailure ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  Future<String?> _uploadIcon() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) {
      return null;
    }

    final size = await File(file.path).length();
    if (size > 10 * 1024 * 1024) {
      if (mounted) {
        showSettingsSnackBar(
            context, 'Размер файла иконки не должен превышать 10 MB.');
      }
      return null;
    }

    try {
      final form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path),
      });
      final response =
          await ref.read(apiClientProvider).uploadFile('/uploads/icon', form);
      if (response is Map<String, dynamic>) {
        final url = (response['url'] ?? '').toString().trim();
        if (url.isNotEmpty) {
          return url;
        }
      }
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось загрузить иконку.');
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось загрузить иконку.');
      }
    }
    return null;
  }

  Future<void> _pickCreateIcon() async {
    final url = await _uploadIcon();
    if (url != null && mounted) {
      _iconController.text = url;
      setState(() {});
    }
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final iconLink = _iconController.text.trim();
    if (name.isEmpty || iconLink.isEmpty) {
      showSettingsSnackBar(context, 'Заполните название банка и URL иконки.');
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      await ref.read(apiClientProvider).postData(
        '/admin/banks',
        body: <String, dynamic>{
          'name': name,
          'iconLink': iconLink,
        },
      );
      if (!mounted) {
        return;
      }
      _nameController.clear();
      _iconController.clear();
      showSettingsSnackBar(context, 'Банк создан.');
      await _load();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось создать банк.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      child: _loading
          ? const SettingsLoadingView()
          : _error != null
              ? SettingsErrorView(
                  message: _error ?? 'Не удалось загрузить банки.',
                  onRetry: _load,
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    const AdminHeader(
                      backText: '← В админ-панель',
                      backRoute: '/admin',
                      title: 'Банки',
                    ),
                    const AdminSectionTitle('Новый банк', top: 8),
                    AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AdminIconBox(
                            size: 52,
                            radius: 14,
                            imageUrl: _iconController.text,
                            fallbackText: '?',
                            fontSize: 24,
                          ),
                          const SizedBox(height: 8),
                          AdminUploadButton(
                            text: 'Загрузить иконку',
                            onTap: _creating ? null : _pickCreateIcon,
                            enabled: !_creating,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            decoration: adminInputDecoration(
                                hintText: 'Название банка'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _iconController,
                            decoration:
                                adminInputDecoration(hintText: 'URL иконки'),
                          ),
                          const SizedBox(height: 10),
                          SettingsActionButton(
                            text: _creating ? 'Создание...' : 'Создать банк',
                            backgroundColor: const Color(0xFFDEF8E8),
                            textColor: const Color(0xFF0F7A3F),
                            onTap: _creating ? null : _create,
                            height: 38,
                          ),
                        ],
                      ),
                    ),
                    const AdminSectionTitle('Справочник', top: 10),
                    if (_banks.isEmpty)
                      const AdminEmptyText('Банки пока не добавлены.')
                    else
                      ..._banks.map(
                        (bank) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _BankCard(
                            bank: bank,
                            onChanged: _load,
                            uploadIcon: _uploadIcon,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _BankCard extends ConsumerStatefulWidget {
  const _BankCard({
    required this.bank,
    required this.onChanged,
    required this.uploadIcon,
  });

  final AdminBankItem bank;
  final Future<void> Function() onChanged;
  final Future<String?> Function() uploadIcon;

  @override
  ConsumerState<_BankCard> createState() => _BankCardState();
}

class _BankCardState extends ConsumerState<_BankCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bank.name);
    _iconController = TextEditingController(text: widget.bank.iconLink);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final url = await widget.uploadIcon();
    if (url != null && mounted) {
      _iconController.text = url;
      setState(() {});
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final iconLink = _iconController.text.trim();
    if (name.isEmpty || iconLink.isEmpty) {
      showSettingsSnackBar(context, 'Заполните название банка и URL иконки.');
      return;
    }

    setState(() {
      _pending = true;
    });
    try {
      await ref.read(apiClientProvider).patchData(
        '/admin/banks/${widget.bank.id}',
        body: <String, dynamic>{
          'name': name,
          'iconLink': iconLink,
        },
      );
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Банк обновлен.');
      await widget.onChanged();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось обновить банк.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    setState(() {
      _pending = true;
    });
    try {
      await ref
          .read(apiClientProvider)
          .deleteData('/admin/banks/${widget.bank.id}');
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Банк удален.');
      await widget.onChanged();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось удалить банк.');
      }
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
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AdminIconBox(
                size: 38,
                radius: 10,
                imageUrl: widget.bank.iconLink,
                fallbackText: adminInitials(widget.bank.name),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.bank.name,
                  style: const TextStyle(
                    color: Color(0xFF112841),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Используется в ${widget.bank.paymentMethodsCount} способах оплаты',
            style: const TextStyle(
              color: Color(0xFF6B7F99),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          AdminIconBox(
            size: 52,
            radius: 14,
            imageUrl: _iconController.text,
            fallbackText: adminInitials(_nameController.text.isEmpty
                ? widget.bank.name
                : _nameController.text),
            fontSize: 20,
          ),
          const SizedBox(height: 8),
          AdminUploadButton(
            text: 'Загрузить иконку',
            onTap: _pending ? null : _pickIcon,
            enabled: !_pending,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: adminInputDecoration(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _iconController,
            decoration: adminInputDecoration(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 104,
            child: SettingsSecondaryButton(
              text: 'Сохранить',
              onTap: _pending ? null : _save,
            ),
          ),
          const SizedBox(height: 10),
          SettingsActionButton(
            text: _pending ? 'Удаление...' : 'Удалить',
            backgroundColor: const Color(0xFFFFE6EA),
            textColor: const Color(0xFFBD2D45),
            onTap: _pending ? null : _delete,
            height: 38,
          ),
        ],
      ),
    );
  }
}
