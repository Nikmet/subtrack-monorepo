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

class AdminSubscriptionDetailScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionDetailScreen(
      {super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  ConsumerState<AdminSubscriptionDetailScreen> createState() =>
      _AdminSubscriptionDetailScreenState();
}

class _AdminSubscriptionDetailScreenState
    extends ConsumerState<AdminSubscriptionDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String _category = 'streaming';
  String _period = '1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ref
          .read(apiClientProvider)
          .getData('/admin/subscriptions/${widget.subscriptionId}');
      final data =
          AdminSubscriptionDetail.fromJson(widget.subscriptionId, asMap(raw));
      if (!mounted) {
        return;
      }
      setState(() {
        _nameController.text = data.name;
        _imageController.text = data.imageUrl;
        _priceController.text = data.price;
        _commentController.text = data.moderationComment;
        _category = data.category.isEmpty ? 'streaming' : data.category;
        _period = data.period.isEmpty ? '1' : data.period;
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

  Future<void> _uploadIcon() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) {
      return;
    }

    final size = await File(file.path).length();
    if (size > 10 * 1024 * 1024) {
      if (mounted) {
        showSettingsSnackBar(
            context, 'Размер файла иконки не должен превышать 10 MB.');
      }
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path),
      });
      final response =
          await ref.read(apiClientProvider).uploadFile('/uploads/icon', form);
      final url = response is Map<String, dynamic>
          ? (response['url'] ?? '').toString().trim()
          : '';
      if (url.isEmpty) {
        if (mounted) {
          showSettingsSnackBar(context, 'Не удалось загрузить иконку.');
        }
      } else {
        _imageController.text = url;
        if (mounted) {
          setState(() {});
        }
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось загрузить иконку.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final imageUrl = _imageController.text.trim();
    final price = _priceController.text.trim().replaceAll(',', '.');
    final parsedPrice = double.tryParse(price);

    if (name.isEmpty ||
        imageUrl.isEmpty ||
        parsedPrice == null ||
        parsedPrice < 0) {
      showSettingsSnackBar(context, 'Проверьте название, цену и URL иконки.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(apiClientProvider).patchData(
        '/admin/subscriptions/${widget.subscriptionId}',
        body: <String, dynamic>{
          'name': name,
          'imgLink': imageUrl,
          'category': _category,
          'price': parsedPrice,
          'period': int.tryParse(_period) ?? 1,
          'moderationComment': _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, 'Изменения сохранены');
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось сохранить изменения.');
      }
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
    return AdminPageScaffold(
      maxWidth: 760,
      child: _loading
          ? const SettingsLoadingView()
          : _error != null
              ? SettingsErrorView(
                  message: _error ?? 'Не удалось загрузить подписку.',
                  onRetry: _load,
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    const AdminHeader(
                      backText: '← К опубликованным',
                      backRoute: '/admin/published',
                      title: 'Редактирование подписки',
                    ),
                    const SizedBox(height: 14),
                    AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AdminIconBox(
                            size: 88,
                            radius: 18,
                            imageUrl: _imageController.text,
                            fallbackText: adminInitials(_nameController.text),
                            fontSize: 28,
                          ),
                          const SizedBox(height: 10),
                          AdminUploadButton(
                            text:
                                _uploading ? 'Загрузка...' : 'Загрузить иконку',
                            onTap: (_uploading || _saving) ? null : _uploadIcon,
                            enabled: !_uploading && !_saving,
                          ),
                          const SizedBox(height: 12),
                          const SettingsFormLabel('Название'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: adminInputDecoration(),
                          ),
                          const SizedBox(height: 10),
                          const SettingsFormLabel('URL иконки'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _imageController,
                            decoration: adminInputDecoration(),
                          ),
                          const SizedBox(height: 10),
                          const SettingsFormLabel('Категория'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>('edit-category-$_category'),
                            initialValue: _category,
                            decoration: adminInputDecoration(),
                            items: adminCategoryOptions
                                .where((option) => option.value.isNotEmpty)
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option.value,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _category = value ?? 'streaming';
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const SettingsFormLabel('Стоимость'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: adminInputDecoration(),
                          ),
                          const SizedBox(height: 10),
                          const SettingsFormLabel('Период'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>('edit-period-$_period'),
                            initialValue: _period,
                            decoration: adminInputDecoration(),
                            items: adminPeriodEditorOptions
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option.value,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _period = value ?? '1';
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const SettingsFormLabel('Комментарий модератора'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _commentController,
                            maxLines: 4,
                            decoration: adminInputDecoration(),
                          ),
                          const SizedBox(height: 14),
                          SettingsActionButton(
                            text: _saving
                                ? 'Сохранение...'
                                : 'Сохранить изменения',
                            backgroundColor: const Color(0xFFDEF8E8),
                            textColor: const Color(0xFF0F7A3F),
                            onTap: (_saving || _uploading) ? null : _save,
                            height: 38,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
