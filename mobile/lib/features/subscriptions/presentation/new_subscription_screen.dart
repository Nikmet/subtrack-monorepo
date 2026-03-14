import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/ui_kit/tokens.dart';
import '../../../core/models/api_failure.dart';
import '../../../features/shared/providers.dart';

class NewSubscriptionScreen extends ConsumerStatefulWidget {
  const NewSubscriptionScreen({super.key});

  @override
  ConsumerState<NewSubscriptionScreen> createState() =>
      _NewSubscriptionScreenState();
}

class _NewSubscriptionScreenState extends ConsumerState<NewSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _category = 'other';
  int _period = 1;
  bool _submitting = false;
  bool _uploading = false;
  String _iconUrl = '';
  String? _uploadError;
  String? _formError;

  static const List<_Option<String>> _categories = <_Option<String>>[
    _Option(value: 'streaming', label: 'Стриминг'),
    _Option(value: 'music', label: 'Музыка'),
    _Option(value: 'games', label: 'Игры'),
    _Option(value: 'shopping', label: 'Покупки'),
    _Option(value: 'ai', label: 'AI'),
    _Option(value: 'finance', label: 'Финансы'),
    _Option(value: 'other', label: 'Прочее'),
  ];

  static const List<_Option<int>> _periods = <_Option<int>>[
    _Option(value: 1, label: 'Ежемесячно'),
    _Option(value: 3, label: 'Раз в 3 месяца'),
    _Option(value: 6, label: 'Раз в 6 месяцев'),
    _Option(value: 12, label: 'Раз в год'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadIcon() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }

    final fileSize = await File(file.path).length();
    if (fileSize > 10 * 1024 * 1024) {
      setState(() {
        _uploadError = 'Размер файла иконки не должен превышать 10MB.';
      });
      return;
    }

    setState(() {
      _uploading = true;
      _uploadError = null;
    });

    try {
      final form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path),
      });
      final response =
          await ref.read(apiClientProvider).uploadFile('/uploads/icon', form);
      final map =
          response is Map<String, dynamic> ? response : <String, dynamic>{};
      final nested = map['data'] is Map<String, dynamic>
          ? map['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final uploadedUrl = ((map['url'] ?? nested['url']) ?? '').toString();

      if (uploadedUrl.isEmpty) {
        setState(() {
          _uploadError = 'Не удалось загрузить иконку.';
        });
        return;
      }

      setState(() {
        _iconUrl = uploadedUrl;
      });
    } catch (_) {
      setState(() {
        _uploadError = 'Ошибка загрузки. Попробуйте снова.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    final price =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0;

    try {
      await ref
          .read(apiClientProvider)
          .postData('/common-subscriptions', body: <String, dynamic>{
        'name': _nameController.text.trim(),
        'category': _category,
        'imgLink': _iconUrl,
        'price': price,
        'period': _period,
      });

      if (!mounted) {
        return;
      }
      final name = Uri.encodeQueryComponent(_nameController.text.trim());
      context.go('/subscriptions/pending?toast=submitted&name=$name');
    } catch (error) {
      if (error is ApiFailure) {
        setState(() {
          _formError = error.message;
        });
      } else {
        setState(() {
          _formError = 'Не удалось создать подписку.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE9EEF5)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: UiTokens.pagePadding,
        children: <Widget>[
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FC),
              borderRadius: UiTokens.radius12,
              border: Border(
                bottom: BorderSide(color: Color(0xFFDDE5EF)),
              ),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => context.go('/search'),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: Center(
                          child: Text(
                            '←',
                            style: TextStyle(
                              color: Color(0xFF9EABBC),
                              fontSize: 26,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Новая общая подписка',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF112840),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FB),
                borderRadius: UiTokens.radius12,
                border: Border.all(color: const Color(0xFFD9E2EE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Column(
                      children: <Widget>[
                        InkWell(
                          onTap: _uploading ? null : _pickAndUploadIcon,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(14)),
                          child: _IconDrop(
                            iconUrl: _iconUrl,
                            showUploading: _uploading,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _uploading
                              ? 'Загрузка...'
                              : 'Нажмите, чтобы загрузить иконку',
                          style: const TextStyle(
                            color: Color(0xFF92A2B6),
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                        if (_uploadError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _uploadError!,
                              style: const TextStyle(
                                color: Color(0xFFC23636),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _FieldLabel(text: 'Название сервиса'),
                  const SizedBox(height: 5),
                  _TextInput(
                    controller: _nameController,
                    hint: 'Напр. Netflix',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Укажите название сервиса.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const _FieldLabel(text: 'Стоимость'),
                            const SizedBox(height: 5),
                            _TextInput(
                              controller: _priceController,
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                final amount = double.tryParse(
                                      (value ?? '').trim().replaceAll(',', '.'),
                                    ) ??
                                    0;
                                if (amount <= 0) {
                                  return 'Цена должна быть больше 0.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const _FieldLabel(text: 'Период'),
                            const SizedBox(height: 5),
                            _DropdownInput<int>(
                              value: _period,
                              items: _periods,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _period = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _FieldLabel(text: 'Категория'),
                  const SizedBox(height: 5),
                  _DropdownInput<String>(
                    value: _category,
                    items: _categories,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _category = value;
                      });
                    },
                  ),
                  if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formError!,
                        style: const TextStyle(
                          color: Color(0xFFC23636),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _submitting || _uploading ? null : _submit,
                    borderRadius: UiTokens.radius12,
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      height: 46,
                      decoration: const BoxDecoration(
                        borderRadius: UiTokens.radius12,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xFF1FB8CE),
                            Color(0xFF43E0CA),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _submitting ? 'Отправка...' : 'Создать подписку',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconDrop extends StatelessWidget {
  const _IconDrop({
    required this.iconUrl,
    required this.showUploading,
  });

  final String iconUrl;
  final bool showUploading;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: const Color(0xFFCFD9E6),
        radius: 14,
      ),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: iconUrl.isEmpty
            ? Center(
                child: Text(
                  showUploading ? '...' : 'ИКОНКА',
                  style: const TextStyle(
                    color: Color(0xFFB4BFCE),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              )
            : Image.network(
                iconUrl,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFF182D49),
          fontSize: 14,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9AAABD),
            fontSize: 14,
            height: 1.2,
          ),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF3F6FA),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          enabledBorder: const OutlineInputBorder(
            borderRadius: UiTokens.radius10,
            borderSide: BorderSide(color: Color(0xFFD4DEEA)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: UiTokens.radius10,
            borderSide: BorderSide(color: Color(0xFF79AAC8)),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: UiTokens.radius10,
            borderSide: BorderSide(color: Color(0xFFC23636)),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: UiTokens.radius10,
            borderSide: BorderSide(color: Color(0xFFC23636)),
          ),
        ),
      ),
    );
  }
}

class _DropdownInput<T> extends StatelessWidget {
  const _DropdownInput({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<_Option<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: UiTokens.radius10,
        border: Border.all(color: const Color(0xFFD4DEEA)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF182D49),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item.value,
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: Color(0xFF182D49),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF9AAABD),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        height: 1.2,
      ),
    );
  }
}

class _Option<T> {
  const _Option({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;
  final double strokeWidth = 1;
  final double dash = 4;
  final double gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
