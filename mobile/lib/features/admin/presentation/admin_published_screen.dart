import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/api_failure.dart';
import '../../shared/parsers.dart';
import '../../shared/providers.dart';
import '../../settings/presentation/settings_widgets.dart';
import 'admin_models.dart';
import 'admin_widgets.dart';

class AdminPublishedScreen extends ConsumerStatefulWidget {
  const AdminPublishedScreen({super.key});

  @override
  ConsumerState<AdminPublishedScreen> createState() =>
      _AdminPublishedScreenState();
}

class _AdminPublishedScreenState extends ConsumerState<AdminPublishedScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _category = '';
  String _period = '';
  List<AdminPublishedItem> _items = const <AdminPublishedItem>[];

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
          .getData('/admin/published/subscriptions', query: query);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = asMapList(raw).map(AdminPublishedItem.fromJson).toList();
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
            title: 'Опубликованные подписки',
          ),
          const SizedBox(height: 14),
          AdminFiltersPanel(
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: adminInputDecoration(
                  hintText: 'Поиск по названию подписки',
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
          const AdminSectionTitle('Опубликованные', top: 10),
          Expanded(
            child: _loading
                ? const SettingsLoadingView()
                : _error != null
                    ? SettingsErrorView(
                        message: _error ??
                            'Не удалось загрузить опубликованные подписки.',
                        onRetry: _load,
                      )
                    : _items.isEmpty
                        ? const AdminEmptyText(
                            'Опубликованных подписок пока нет.')
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _PublishedCard(
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

class _PublishedCard extends ConsumerStatefulWidget {
  const _PublishedCard({
    required this.item,
    required this.onChanged,
  });

  final AdminPublishedItem item;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_PublishedCard> createState() => _PublishedCardState();
}

class _PublishedCardState extends ConsumerState<_PublishedCard> {
  final TextEditingController _reasonController = TextEditingController();
  bool _pending = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      showSettingsSnackBar(context, 'Укажите причину удаления.');
      return;
    }

    setState(() {
      _pending = true;
    });
    try {
      await ref.read(apiClientProvider).deleteData(
        '/admin/subscriptions/${widget.item.id}',
        body: <String, dynamic>{'reason': reason},
      );
      if (!mounted) {
        return;
      }
      showSettingsSnackBar(context, '${widget.item.name} удалена из каталога.');
      await widget.onChanged();
    } on ApiFailure catch (failure) {
      if (mounted) {
        showSettingsSnackBar(context, failure.message);
      }
    } catch (_) {
      if (mounted) {
        showSettingsSnackBar(context, 'Не удалось удалить подписку.');
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
              const SizedBox(width: 10),
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
            'Подписчиков: ${widget.item.subscribersCount}',
            style: const TextStyle(
              color: Color(0xFF6B7F99),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 128,
            child: SettingsSecondaryButton(
              text: 'Редактировать',
              onTap: () =>
                  context.push('/admin/subscriptions/${widget.item.id}'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            decoration: adminInputDecoration(hintText: 'Причина удаления'),
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
