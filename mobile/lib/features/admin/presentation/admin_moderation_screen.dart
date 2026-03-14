import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_failure.dart';
import '../../shared/parsers.dart';
import '../../shared/providers.dart';
import '../../settings/presentation/settings_widgets.dart';
import 'admin_models.dart';
import 'admin_widgets.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _category = '';
  String _period = '';
  List<AdminModerationItem> _items = const <AdminModerationItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final query = <String, dynamic>{};
    if (_searchController.text.trim().isNotEmpty) {
      query['q'] = _searchController.text.trim();
    }
    if (_category.isNotEmpty) {
      query['category'] = _category;
    }
    if (_period.isNotEmpty) {
      query['period'] = _period;
    }

    try {
      final raw = await ref
          .read(apiClientProvider)
          .getData('/admin/moderation/subscriptions', query: query);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = asMapList(raw).map(AdminModerationItem.fromJson).toList();
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

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _category = '';
      _period = '';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminHeader(
            backText: '← В админ-панель',
            backRoute: '/admin',
            title: 'Очередь модерации',
          ),
          const SizedBox(height: 14),
          AdminFiltersPanel(
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: adminInputDecoration(
                  hintText: 'Поиск по подписке, автору или email',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('category-$_category'),
                initialValue: _category,
                decoration: adminInputDecoration(),
                items: adminCategoryOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('period-$_period'),
                initialValue: _period,
                decoration: adminInputDecoration(),
                items: adminPeriodFilterOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _period = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  SettingsActionButton(
                    text: 'Применить',
                    backgroundColor: const Color(0xFFDEF8E8),
                    textColor: const Color(0xFF0F7A3F),
                    onTap: _load,
                    height: 38,
                  ),
                  SettingsActionButton(
                    text: 'Сбросить',
                    backgroundColor: const Color(0xFFE2F1FF),
                    textColor: const Color(0xFF1F5D95),
                    onTap: _resetFilters,
                    height: 38,
                  ),
                ],
              ),
            ],
          ),
          const AdminSectionTitle('Модерация', top: 10),
          Expanded(
            child: _loading
                ? const SettingsLoadingView()
                : _error != null
                    ? SettingsErrorView(
                        message:
                            _error ?? 'Не удалось загрузить очередь модерации.',
                        onRetry: _load,
                      )
                    : _items.isEmpty
                        ? const AdminEmptyText('Нет заявок в очереди.')
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _ModerationCard(
                                item: _items[index],
                                onChanged: _load,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _ModerationCard extends ConsumerStatefulWidget {
  const _ModerationCard({
    required this.item,
    required this.onChanged,
  });

  final AdminModerationItem item;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_ModerationCard> createState() => _ModerationCardState();
}

class _ModerationCardState extends ConsumerState<_ModerationCard> {
  final TextEditingController _publishCommentController =
      TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();
  bool _pending = false;

  @override
  void dispose() {
    _publishCommentController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() {
      _pending = true;
    });
    try {
      await ref.read(apiClientProvider).postData(
        '/admin/moderation/subscriptions/${widget.item.id}/publish',
        body: <String, dynamic>{
          'moderationComment': _publishCommentController.text.trim().isEmpty
              ? null
              : _publishCommentController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, '${widget.item.name} опубликована.');
      await widget.onChanged();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось опубликовать подписку.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    final reason = _rejectReasonController.text.trim();
    if (reason.isEmpty) {
      showSettingsSnackBar(context, 'Укажите причину отклонения.');
      return;
    }

    setState(() {
      _pending = true;
    });
    try {
      await ref.read(apiClientProvider).postData(
        '/admin/moderation/subscriptions/${widget.item.id}/reject',
        body: <String, dynamic>{'reason': reason},
      );
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, '${widget.item.name} отклонена.');
      await widget.onChanged();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось отклонить подписку.');
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
                radius: 9,
                imageUrl: widget.item.imageUrl,
                fallbackText: adminInitials(widget.item.name),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.item.name,
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
          const SizedBox(height: 8),
          Text(
            '${widget.item.category} • ${formatAdminRub(widget.item.price)} • ${adminPeriodLabel(widget.item.period)}',
            style: const TextStyle(
              color: Color(0xFF50657F),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Автор: ${widget.item.authorName} (${widget.item.authorEmail})',
            style: const TextStyle(
              color: Color(0xFF6B7F99),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _publishCommentController,
            decoration: adminInputDecoration(
              hintText: 'Комментарий к публикации (необязательно)',
            ),
          ),
          const SizedBox(height: 8),
          SettingsActionButton(
            text: _pending ? 'Публикация...' : 'Опубликовать',
            backgroundColor: const Color(0xFFDEF8E8),
            textColor: const Color(0xFF0F7A3F),
            onTap: _pending ? null : _publish,
            height: 38,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rejectReasonController,
            decoration: adminInputDecoration(hintText: 'Причина отклонения'),
          ),
          const SizedBox(height: 8),
          SettingsActionButton(
            text: _pending ? 'Отклонение...' : 'Отклонить',
            backgroundColor: const Color(0xFFFFE6EA),
            textColor: const Color(0xFFBD2D45),
            onTap: _pending ? null : _reject,
            height: 38,
          ),
        ],
      ),
    );
  }
}
