import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui_kit/skeleton_box.dart';
import '../../../app/ui_kit/tokens.dart';
import '../../../features/home/presentation/home_formatters.dart';
import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import 'search_add_subscription_dialog.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _categories = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _popular = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _paymentMethods = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _banks = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final categories = await api.getData('/catalog/categories');
      final popular =
          await api.getData('/catalog/popular', query: {'limit': 8});
      final paymentMethods = await api.getData('/payment-methods');
      final banks = await api.getData('/banks');

      if (!mounted) return;
      setState(() {
        _categories = asMapList(categories);
        _popular = asMapList(popular);
        _paymentMethods = asMapList(paymentMethods);
        _banks = asMapList(banks);
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

  void _openCatalog({String category = ''}) {
    final query = _query.text.trim();
    final params = <String, String>{};
    if (query.isNotEmpty) {
      params['q'] = query;
    }
    if (category.isNotEmpty) {
      params['category'] = category;
    }
    final uri = Uri(
        path: '/search/all', queryParameters: params.isEmpty ? null : params);
    context.push(uri.toString());
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

    if (result == AddSubscriptionDialogResult.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Подписка ${_itemName(item)} уже добавлена.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Подписка ${_itemName(item)} добавлена.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE8EDF4)),
      child: RefreshIndicator(
        onRefresh: _bootstrap,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: UiTokens.pagePadding,
          children: <Widget>[
            const Text(
              'Поиск',
              style: TextStyle(
                color: Color(0xFF10233F),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            _SearchInput(
              controller: _query,
              onSubmitted: (_) => _openCatalog(),
            ),
            const SizedBox(height: 16),
            if (_loading && _popular.isEmpty)
              const _SearchLoading()
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _bootstrap)
            else ...<Widget>[
              _CategorySection(
                categories: _categories,
                onTap: (slug) => _openCatalog(category: slug),
              ),
              const SizedBox(height: 16),
              _PopularSection(
                items: _popular,
                onShowAll: _openCatalog,
                onAddTap: _openAddDialog,
              ),
              const SizedBox(height: 16),
              _CtaCard(
                onTap: () => context.push('/subscriptions/new'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _itemName(Map<String, dynamic> item) =>
      (item['name'] ?? item['typeName'] ?? '-').toString();
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Color(0xFF1A2D47), fontSize: 15),
      decoration: const InputDecoration(
        hintText: 'Найдите подписку или сервис...',
        hintStyle: TextStyle(color: Color(0xFF7E92AA), fontSize: 15),
        isDense: true,
        filled: true,
        fillColor: Color(0xFFF3F6FA),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: UiTokens.radius12,
          borderSide: BorderSide(color: Color(0xFFDAE2ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UiTokens.radius12,
          borderSide: BorderSide(color: Color(0xFF8DB2D0)),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categories,
    required this.onTap,
  });

  final List<Map<String, dynamic>> categories;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Категории',
          style: TextStyle(
            color: Color(0xFF122842),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final name =
                (category['name'] ?? category['label'] ?? '').toString();
            final slug =
                (category['slug'] ?? category['value'] ?? '').toString();
            return InkWell(
              borderRadius: UiTokens.radius12,
              onTap: slug.isEmpty ? null : () => onTap(slug),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: UiTokens.radius12,
                  border: Border.all(color: const Color(0xFFD7DEE8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  name,
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
          },
        ),
      ],
    );
  }
}

class _PopularSection extends StatelessWidget {
  const _PopularSection({
    required this.items,
    required this.onShowAll,
    required this.onAddTap,
  });

  final List<Map<String, dynamic>> items;
  final VoidCallback onShowAll;
  final Future<void> Function(Map<String, dynamic>) onAddTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Популярное',
                style: TextStyle(
                  color: Color(0xFF122842),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            InkWell(
              onTap: onShowAll,
              child: const Text(
                'ВСЕ',
                style: TextStyle(
                  color: Color(0xFF22B8CE),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PopularItem(
              item: item,
              onAddTap: () => onAddTap(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopularItem extends StatelessWidget {
  const _PopularItem({
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
                  ? _FallbackIcon(letter: letter)
                  : Image.network(
                      icon,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          _FallbackIcon(letter: letter),
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
                  style: const TextStyle(
                    color: Color(0xFF8899AF),
                    fontSize: 12,
                  ),
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
              const Text(
                '/мес',
                style: TextStyle(color: Color(0xFF98A6BA), fontSize: 11),
              ),
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

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({
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

class _CtaCard extends StatelessWidget {
  const _CtaCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: const BoxDecoration(
        borderRadius: UiTokens.radius16,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0C2141),
            Color(0xFF19243F),
            Color(0xFF24344F),
          ],
          stops: <double>[0, 0.58, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Не нашли нужную подписку?',
            style: TextStyle(
              color: Color(0xFFECF5FF),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавьте свой вариант подписки, чтобы она появилась в каталоге.',
            style: TextStyle(
              color: Color(0xFFB4C8DF),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            borderRadius: UiTokens.radius12,
            child: Container(
              height: 44,
              decoration: const BoxDecoration(
                borderRadius: UiTokens.radius12,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF1EB8CE), Color(0xFF46E0CA)],
                ),
              ),
              child: const Center(
                child: Text(
                  'Создать подписку',
                  style: TextStyle(
                    color: Color(0xFF0E2034),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
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
            'Не удалось загрузить поиск',
            style: TextStyle(
              color: Color(0xFF10233F),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFF3F5168))),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

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
