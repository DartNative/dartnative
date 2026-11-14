import 'package:flutter/material.dart';

import '../api.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.handle});
  final String handle;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  ProductDetail? _product;
  bool _error = false;
  Map<String, String> _selected = <String, String>{};
  Variant? _variant;
  bool _adding = false;
  final PageController _pages = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = false;
      _product = null;
    });
    try {
      final ProductDetail p = await StorefrontApi.instance.product(widget.handle);
      if (!mounted) return;
      Variant? v;
      if (p.variants.isNotEmpty) {
        v = p.variants.firstWhere((Variant v) => v.availableForSale,
            orElse: () => p.variants.first);
      }
      setState(() {
        _product = p;
        _variant = v;
        _selected = Map<String, String>.of(v?.selectedOptions ?? <String, String>{});
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _select(String name, String value) {
    final Map<String, String> want = Map<String, String>.of(_selected)..[name] = value;
    final List<Variant> variants = _product!.variants;
    Variant? match;
    for (final Variant v in variants) {
      if (want.entries.every((MapEntry<String, String> e) => v.selectedOptions[e.key] == e.value)) {
        match = v;
        break;
      }
    }
    match ??= variants.cast<Variant?>().firstWhere(
        (Variant? v) => v!.selectedOptions[name] == value,
        orElse: () => null);
    if (match == null) return;
    setState(() {
      _variant = match;
      _selected = Map<String, String>.of(match!.selectedOptions);
    });
  }

  Future<void> _addToCart() async {
    final Variant? v = _variant;
    if (v == null || _adding) return;
    setState(() => _adding = true);
    final String? error = await cartStore.add(v.id);
    if (!mounted) return;
    setState(() => _adding = false);
    if (error != null) {
      await showMessage(context, error);
    } else {
      currentTab.value = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets insets = MediaQuery.paddingOf(context);
    final ProductDetail? p = _product;
    Widget body;
    if (_error) {
      body = Padding(padding: EdgeInsets.only(top: insets.top), child: ErrorState(onRetry: _load));
    } else if (p == null) {
      body = const Spinner();
    } else {
      body = _content(p);
    }
    return Screen(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: body),
                if (p == null) Positioned(top: insets.top, left: 12, child: _backButton()),
              ],
            ),
          ),
          if (p != null && _variant != null) _bottomBar(insets.bottom),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Tap(
      id: 'back',
      label: 'Back',
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: const VectorIcon(AppIcon.back, size: 22),
      ),
    );
  }

  Widget _bottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: PrimaryButton(
        id: 'add-to-cart',
        label: 'Add to cart · ${_variant!.price.format()}',
        onTap: _adding ? null : _addToCart,
      ),
    );
  }

  Widget _content(ProductDetail p) {
    final Variant? v = _variant;
    final List<ProductOption> options = p.options
        .where((ProductOption o) =>
            !(o.name == 'Title' && o.values.length == 1 && o.values.first == 'Default Title'))
        .toList();
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(aspectRatio: 3 / 4, child: _carousel(p.images)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(p.title, style: ts(22, weight: FontWeight.w700, lineHeight: 28)),
                if (v != null) ...<Widget>[
                  const SizedBox(height: 6),
                  PriceRow(price: v.price, compareAt: v.compareAt, size: 20, compareSize: 15),
                ],
              ],
            ),
          ),
          for (final ProductOption o in options) _optionGroup(o),
          if (p.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Description', style: ts(15, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(p.description, style: ts(15, lineHeight: 22, color: AppColors.body)),
                ],
              ),
            ),
          if (p.recommendations.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
              child: Text('You may also like', style: ts(17, weight: FontWeight.w700)),
            ),
            SizedBox(
              height: 187 + 6 + scaler.scale(36) + 6 + scaler.scale(22),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: p.recommendations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int i) =>
                    _recommendation(p.recommendations[i], i),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _carousel(List<String> images) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Semantics(
          identifier: 'product-carousel',
          container: true,
          explicitChildNodes: true,
          child: images.isEmpty
              ? const ColoredBox(color: AppColors.surface)
              : PageView.builder(
                  controller: _pages,
                  itemCount: images.length,
                  onPageChanged: (int i) => setState(() => _page = i),
                  itemBuilder: (BuildContext context, int i) =>
                      NetImage(images[i], width: 1080),
                ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top,
          left: 12,
          child: _backButton(),
        ),
        if (images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < images.length; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    child: Tap(
                      label: 'Show image ${i + 1}',
                      onTap: () => _pages.jumpToPage(i),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page ? AppColors.text : AppColors.dotInactive,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _optionGroup(ProductOption o) {
    final String? current = _selected[o.name];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              text: '${o.name}: ',
              style: ts(15, weight: FontWeight.w600),
              children: <InlineSpan>[
                TextSpan(
                    text: current ?? '',
                    style: ts(15, weight: FontWeight.w400, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String value in o.values)
                _pill(o.name, value, value == current),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String name, String value, bool selected) {
    return Tap(
      id: 'option-$name-$value',
      selected: selected,
      onTap: () => _select(name, value),
      child: Container(
        constraints: const BoxConstraints(minWidth: 56),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(
            color: selected ? AppColors.text : AppColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(value,
              style: ts(15, weight: selected ? FontWeight.w600 : FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _recommendation(ProductSummary r, int i) {
    return Tap(
      id: 'recommendation-$i',
      onTap: () => openProduct(context, r.handle),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 140, height: 187, child: NetImage(r.imageUrl, width: 480, radius: 8)),
            const SizedBox(height: 6),
            Text(r.title,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(14, lineHeight: 18)),
            const SizedBox(height: 6),
            PriceRow(price: r.price, compareAt: r.compareAt, size: 14, compareSize: 12),
          ],
        ),
      ),
    );
  }
}
