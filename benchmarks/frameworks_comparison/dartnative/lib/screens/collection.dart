import 'package:dartnative/dartnative.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class _Sort {
  const _Sort(this.id, this.label, this.sortKey, this.reverse);
  final String id;
  final String label;
  final String sortKey;
  final bool reverse;
}

const List<_Sort> _sorts = <_Sort>[
  _Sort('sort-featured', 'Featured', 'COLLECTION_DEFAULT', false),
  _Sort('sort-best-selling', 'Best selling', 'BEST_SELLING', false),
  _Sort('sort-price-asc', 'Price: low to high', 'PRICE', false),
  _Sort('sort-price-desc', 'Price: high to low', 'PRICE', true),
];

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.collection});
  final CollectionSummary collection;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final ScrollController _scroll = ScrollController();
  int _sort = 0;
  String? _description;
  final List<ProductSummary> _items = <ProductSummary>[];
  bool _hasNext = false;
  String? _cursor;
  bool _loading = false;
  bool _error = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _reload() {
    _generation++;
    _items.clear();
    _hasNext = false;
    _cursor = null;
    _loading = false;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _fetch();
  }

  Future<void> _fetch() async {
    if (_loading) return;
    final int gen = _generation;
    final _Sort sort = _sorts[_sort];
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final ProductPage page = await StorefrontApi.instance.collectionProducts(
        handle: widget.collection.handle,
        after: _cursor,
        sortKey: sort.sortKey,
        reverse: sort.reverse,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _description = page.description;
        _items.addAll(page.products);
        _hasNext = page.hasNextPage;
        _cursor = page.endCursor;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _loadMore() {
    if (_hasNext && !_loading && !_error) _fetch();
  }

  void _checkEnd() {
    if (!mounted || !_scroll.hasClients) return;
    final ScrollPosition p = _scroll.position;
    if (p.extentAfter < p.viewportDimension) _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final bool initialError = _error && _items.isEmpty;
    final bool initialLoading = _loading && _items.isEmpty;
    return Screen(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            NavBar(title: widget.collection.title),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification n) => handleInfiniteScroll(n, _loadMore),
                child: Semantics(
                  identifier: 'product-grid',
                  container: true,
                  child: CustomScrollView(
                    controller: _scroll,
                    slivers: <Widget>[
                      if (_description != null && _description!.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: Text(_description!,
                                style: ts(14, lineHeight: 20, color: AppColors.textMuted)),
                          ),
                        ),
                      SliverToBoxAdapter(child: _sortChips()),
                      if (initialError)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: ErrorState(onRetry: _fetch),
                        )
                      else if (initialLoading)
                        const SliverToBoxAdapter(child: Spinner(padding: EdgeInsets.all(48)))
                      else ...<Widget>[
                        productGridSliver(context, _items, 'product-card'),
                        SliverToBoxAdapter(child: _footer()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    if (_loading) return const Spinner();
    if (_error) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: SecondaryButton(id: 'error-retry', label: 'Retry', onTap: _fetch)),
      );
    }
    return const SizedBox(height: 24);
  }

  Widget _sortChips() {
    return horizontalList(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        spacing: 8,
        itemCount: _sorts.length,
        itemBuilder: (BuildContext context, int i) {
          final bool selected = i == _sort;
          return Tap(
            id: _sorts[i].id,
            selected: selected,
            onTap: () {
              if (_sort == i) return;
              setState(() => _sort = i);
              _reload();
            },
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.text : AppColors.background,
                border: Border.all(color: selected ? AppColors.text : AppColors.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(_sorts[i].label,
                  style: ts(13,
                      weight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.background : AppColors.text)),
            ),
          );
        },
    );
  }
}
