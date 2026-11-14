import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;
  String _query = '';
  int _generation = 0;
  final List<ProductSummary> _items = <ProductSummary>[];
  int _total = 0;
  bool _hasNext = false;
  String? _cursor;
  bool _loading = false;
  bool _loaded = false;
  bool _error = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final String q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _generation++;
        _query = '';
        _resetResults();
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (q == _query) return;
      _generation++;
      _query = q;
      _resetResults();
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _fetch();
    });
  }

  void _resetResults() {
    _items.clear();
    _total = 0;
    _hasNext = false;
    _cursor = null;
    _loading = false;
    _loaded = false;
    _error = false;
  }

  Future<void> _fetch() async {
    if (_loading || _query.isEmpty) return;
    final int gen = _generation;
    final String query = _query;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final ProductPage page = await StorefrontApi.instance.search(query, after: _cursor);
      // Discard responses for a query that is no longer current.
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(page.products);
        _total = page.totalCount ?? 0;
        _hasNext = page.hasNextPage;
        _cursor = page.endCursor;
        _loading = false;
        _loaded = true;
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
    return Screen(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    const VectorIcon(AppIcon.search, size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        identifier: 'search-input',
                        container: true,
                        child: TextField(
                          controller: _text,
                          onChanged: _onChanged,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.search,
                          style: ts(16),
                          cursorColor: AppColors.text,
                          decoration: InputDecoration.collapsed(
                            hintText: 'Search products',
                            hintStyle: ts(16, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Text('Search across 995 products by name.',
            textAlign: TextAlign.center,
            style: ts(15, lineHeight: 22, color: AppColors.textMuted)),
      );
    }
    if (!_loaded) {
      if (_error) return ErrorState(onRetry: _fetch);
      return const Align(alignment: Alignment.topCenter, child: Spinner());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('$_total results', style: ts(13, color: AppColors.textMuted)),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification n) => handleInfiniteScroll(n, _loadMore),
            child: Semantics(
              identifier: 'search-results',
              container: true,
              explicitChildNodes: true,
              child: ListView.builder(
                controller: _scroll,
                itemCount: _items.length + 1,
                itemBuilder: (BuildContext context, int i) {
                  if (i == _items.length) return _footer();
                  return _row(_items[i], i);
                },
              ),
            ),
          ),
        ),
      ],
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
    return const SizedBox(height: 16);
  }

  Widget _row(ProductSummary p, int i) {
    return Tap(
      id: 'search-result-$i',
      onTap: () => openProduct(context, p.handle),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            SizedBox(width: 64, height: 85, child: NetImage(p.imageUrl, width: 240, radius: 8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(p.title, style: ts(15, lineHeight: 20)),
                  const SizedBox(height: 4),
                  PriceRow(price: p.price, compareAt: p.compareAt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
