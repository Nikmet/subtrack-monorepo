import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui_kit/skeleton_box.dart';
import '../../../app/ui_kit/tokens.dart';
import '../../../features/home/presentation/home_formatters.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import 'search_add_subscription_dialog.dart';

class SearchAllScreen extends ConsumerStatefulWidget {
  const SearchAllScreen({super.key});

  @override
  ConsumerState<SearchAllScreen> createState() => _SearchAllScreenState();
}

class _SearchAllScreenState extends ConsumerState<SearchAllScreen> {
  final TextEditingController _queryController = TextEditingController();

  bool _loading = false;
  String? _error;

  String _query = '';
  String _category = '';
  int _page = 1;

  List<Map<String, dynamic>> _categories = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _items = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _paymentMethods = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _banks = const <Map<String, dynamic>>[];

  int _total = 0;
  int _totalPages = 1;

  Uri? _lastLoadedUri;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (_lastLoadedUri == uri) return;
    _lastLoadedUri = uri;

    _query = (uri.queryParameters['q'] ?? '').trim();
    _category = (uri.queryParameters['category'] ?? '').trim();
    final parsedPage = int.tryParse(uri.queryParameters['page'] ?? '') ?? 1;
    _page = parsedPage < 1 ? 1 : parsedPage;
    _queryController.text = _query;

    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final categoriesRaw = await api.getData('/catalog/categories');
      final catalogRaw = await api.getData(
        '/catalog',
        query: <String, dynamic>{
          'q': _query,
          if (_category.isNotEmpty) 'category': _category,
          'page': _page,
          'pageSize': 24,
        },
      );
      final paymentMethodsRaw = await api.getData('/payment-methods');
      final banksRaw = await api.getData('/banks');

      final catalogMap = asMap(catalogRaw);
      final items = asMapList(
          catalogMap['items'] ?? catalogMap['results'] ?? catalogMap['data']);
      final total = catalogMap['total'] is num
          ? (catalogMap['total'] as num).toInt()
          : items.length;
      final totalPages = catalogMap['totalPages'] is num
          ? (catalogMap['totalPages'] as num).toInt().clamp(1, 9999)
          : 1;

      if (!mounted) return;
      setState(() {
        _categories = asMapList(categoriesRaw);
        _items = items;
        _total = total;
        _totalPages = totalPages;
        _paymentMethods = asMapList(paymentMethodsRaw);
        _banks = asMapList(banksRaw);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _goTo({
    String? query,
    String? category,
    int? page,
  }) {
    final q = (query ?? _query).trim();
    final c = (category ?? _category).trim();
    final p = page ?? _page;
    final params = <String, String>{};
    if (q.isNotEmpty) params['q'] = q;
    if (c.isNotEmpty) params['category'] = c;
    if (p > 1) params['page'] = '$p';
    final uri = Uri(
        path: '/search/all', queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  Future<void> _openAddDialog(Map<String, dynamic> item) async {
    if (_paymentMethods.isEmpty && _banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Сначала добавьте способ оплаты в настройках.')),
      );
      return;
    }

    final result = await showAddSubscriptionDialog(
      context: context,
      item: item,
      paymentMethods: _paymentMethods,
      banks: _banks,
    );
    if (!mounted || result == null) return;

    final name = (item['name'] ?? item['typeName'] ?? '-').toString();
    if (result == AddSubscriptionDialogResult.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Подписка $name уже добавлена.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Подписка $name добавлена.')),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF4),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: UiTokens.pagePadding,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Каталог подписок',
                      style: TextStyle(
                        color: Color(0xFF10233F),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/search'),
                    child: const Text(
                      'НАЗАД',
                      style: TextStyle(
                        color: Color(0xFF22B8CE),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queryController,
                onSubmitted: (_) =>
                    _goTo(query: _queryController.text, page: 1),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Найдите подписку или сервис...',
                  hintStyle: TextStyle(color: Color(0xFF7E92AA), fontSize: 15),
                  isDense: true,
                  filled: true,
                  fillColor: Color(0xFFF3F6FA),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: UiTokens.radius12,
                    borderSide: BorderSide(color: Color(0xFFDAE2ED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: UiTokens.radius12,
                    borderSide: BorderSide(color: Color(0xFF8DB2D0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading && _items.isEmpty)
                const _CatalogLoading()
              else if (_error != null)
                _CatalogError(
                  message: _error!,
                  onRetry: _load,
                )
              else ...<Widget>[
                const Text(
                  'Категории',
                  style: TextStyle(
                    color: Color(0xFF122842),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.8,
                  children: <Widget>[
                    _CategoryChip(
                      title: 'Все категории',
                      active: _category.isEmpty,
                      onTap: () => _goTo(category: '', page: 1),
                    ),
                    ..._categories.map((category) {
                      final slug = (category['slug'] ?? category['value'] ?? '')
                          .toString();
                      final name = (category['name'] ?? category['label'] ?? '')
                          .toString();
                      return _CategoryChip(
                        title: name,
                        active: slug == _category,
                        onTap: () => _goTo(category: slug, page: 1),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Каталог',
                        style: TextStyle(
                          color: Color(0xFF122842),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Всего: $_total',
                      style: const TextStyle(
                        color: Color(0xFF8899AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: UiTokens.radius12,
                      border: Border.all(color: const Color(0xFFD9E1EC)),
                    ),
                    child: const Text(
                      'Ничего не найдено. Попробуйте изменить запрос или фильтры.',
                      style: TextStyle(
                        color: Color(0xFF3F5168),
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  ..._items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CatalogItemCard(
                        item: item,
                        onAddTap: () => _openAddDialog(item),
                      ),
                    ),
                  ),
                if (_totalPages > 1) ...<Widget>[
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _page <= 1 ? null : () => _goTo(page: _page - 1),
                          child: const Text('Назад'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _page >= _totalPages
                              ? null
                              : () => _goTo(page: _page + 1),
                          child: const Text('Далее'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.title,
    required this.active,
    required this.onTap,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: UiTokens.radius12,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F8FC) : const Color(0xFFF4F6F8),
          borderRadius: UiTokens.radius12,
          border: Border.all(
            color: active ? const Color(0xFF68B7CC) : const Color(0xFFD7DEE8),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF19304E),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CatalogItemCard extends StatelessWidget {
  const _CatalogItemCard({
    required this.item,
    required this.onAddTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? item['typeName'] ?? '-').toString();
    final icon = (item['imgLink'] ?? item['typeIcon'] ?? '').toString();
    final category =
        (item['categoryName'] ?? item['category'] ?? 'Прочее').toString();
    final period = item['period'] is num
        ? (item['period'] as num).toInt()
        : int.tryParse(item['period']?.toString() ?? '') ?? 1;
    final priceRaw = item['suggestedMonthlyPrice'] ??
        item['monthlyPrice'] ??
        item['price'] ??
        0;
    final price =
        priceRaw is num ? priceRaw : num.tryParse(priceRaw.toString()) ?? 0;
    final letter =
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: UiTokens.radius12,
        border: Border.all(color: const Color(0xFFD9E1EB)),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: UiTokens.radius10,
            child: SizedBox(
              width: 40,
              height: 40,
              child: icon.trim().isEmpty
                  ? _CatalogFallback(letter: letter)
                  : Image.network(
                      icon,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          _CatalogFallback(letter: letter),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF10233F),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$category • ${formatPeriodLabel(period)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF8899AF), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatRub(price),
                style: const TextStyle(
                  color: Color(0xFF182C49),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text('/мес',
                  style: TextStyle(color: Color(0xFF98A6BA), fontSize: 11)),
            ],
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onAddTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8FC),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: Color(0xFF1AB5CB),
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    height: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogFallback extends StatelessWidget {
  const _CatalogFallback({
    required this.letter,
  });

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8ECF2),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Color(0xFF8493A8),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: UiTokens.radius12,
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Не удалось загрузить каталог',
            style: TextStyle(
              color: Color(0xFF10233F),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFF3F5168))),
          const SizedBox(height: 10),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: UiTokens.radius12,
            border: Border.all(color: const Color(0xFFD9E1EB)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SkeletonBox(
                  width: 120, height: 18, borderRadius: UiTokens.radius10),
              SizedBox(height: 8),
              SkeletonBox(
                  width: double.infinity,
                  height: 48,
                  borderRadius: UiTokens.radius12),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const SkeletonBox(
            width: double.infinity,
            height: 88,
            borderRadius: UiTokens.radius12),
        const SizedBox(height: 10),
        const SkeletonBox(
            width: double.infinity,
            height: 88,
            borderRadius: UiTokens.radius12),
      ],
    );
  }
}
