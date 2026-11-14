import 'package:flutter/cupertino.dart' show CupertinoDialogAction;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

import 'api.dart';
import 'screens/collection.dart';
import 'screens/product.dart';
import 'theme.dart';

/// A tappable region that exposes an accessibility identifier.
class Tap extends StatelessWidget {
  const Tap({super.key, this.id, required this.onTap, required this.child, this.label, this.selected});

  final String? id;
  final bool? selected;
  final String? label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      identifier: id,
      label: label,
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// A network image with cover cropping over the `surface` color.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, required this.width, this.radius = 0, this.alignment = Alignment.center});

  final String? url;
  final int width;
  final double radius;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    Widget child = ColoredBox(
      color: AppColors.surface,
      child: url == null
          ? const SizedBox.expand()
          : Image.network(
              sizedImage(url!, width),
              fit: BoxFit.cover,
              alignment: alignment,
              width: double.infinity,
              height: double.infinity,
              excludeFromSemantics: true,
              errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox.expand(),
            ),
    );
    if (radius > 0) {
      child = ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    }
    return child;
  }
}

class PriceRow extends StatelessWidget {
  const PriceRow({super.key, required this.price, this.compareAt, this.size = 15, this.compareSize = 13});

  final Money price;
  final Money? compareAt;
  final double size;
  final double compareSize;

  @override
  Widget build(BuildContext context) {
    final bool onSale = compareAt != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(price.format(),
            maxLines: 1,
            style: ts(size,
                weight: FontWeight.w700,
                color: onSale ? AppColors.sale : AppColors.text,
                lineHeight: size + 6)),
        if (onSale) ...<Widget>[
          const SizedBox(width: 6),
          Flexible(
            child: Text(compareAt!.format(),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: ts(compareSize, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
          ),
        ],
      ],
    );
  }
}

/// Product card used in the Home and Collection grids.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.id});

  final ProductSummary product;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Tap(
      id: id,
      onTap: () => openProduct(context, product.handle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(aspectRatio: 3 / 4, child: NetImage(product.imageUrl, width: 480, radius: 8)),
          const SizedBox(height: 8),
          Text(product.title,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(14, lineHeight: 18)),
          const SizedBox(height: 8),
          PriceRow(price: product.price, compareAt: product.compareAt),
        ],
      ),
    );
  }
}

/// Two-column lazily built product grid sliver.
Widget productGridSliver(List<ProductSummary> items, String idPrefix) {
  return SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final double colWidth = (constraints.crossAxisExtent - 12) / 2;
        final double extent = colWidth * 4 / 3 + 8 + scaler.scale(36) + 8 + scaler.scale(22);
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 20,
            mainAxisExtent: extent,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int i) => ProductCard(product: items[i], id: '$idPrefix-$i'),
            childCount: items.length,
          ),
        );
      },
    ),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.skeleton, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

class Spinner extends StatelessWidget {
  const Spinner({super.key, this.padding = const EdgeInsets.all(24)});
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const VectorIcon(AppIcon.alert, size: 48, color: AppColors.textMuted, strokeWidth: 1.25),
            const SizedBox(height: 12),
            Text("Couldn't load products",
                textAlign: TextAlign.center, style: ts(17, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Check your connection and try again.',
                textAlign: TextAlign.center,
                style: ts(15, lineHeight: 22, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            SecondaryButton(id: 'error-retry', label: 'Retry', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, this.id, required this.label, required this.onTap, this.height = 52, this.expand = true});
  final String? id;
  final String label;
  final VoidCallback? onTap;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Tap(
      id: id,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(12)),
          child: Center(
            widthFactor: 1,
            child: Text(label,
                maxLines: 1,
                style: ts(16, weight: FontWeight.w600, color: AppColors.background)),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.id, required this.label, required this.onTap});
  final String id;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      id: id,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.text),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(widthFactor: 1, child: Text(label, style: ts(16, weight: FontWeight.w600))),
      ),
    );
  }
}

/// 44pt navigation bar with a back button and a centered title.
class NavBar extends StatelessWidget {
  const NavBar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            Tap(
              id: 'back',
              label: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(child: VectorIcon(AppIcon.back)),
              ),
            ),
            Expanded(
              child: Text(title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(17, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

/// Opaque page background for pushed routes.
class Screen extends StatelessWidget {
  const Screen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(color: AppColors.background, child: child);
  }
}

const String productRouteName = 'product';

void openProduct(BuildContext context, String handle) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    settings: const RouteSettings(name: productRouteName),
    builder: (BuildContext context) => ProductScreen(handle: handle),
  ));
}

void openCollection(BuildContext context, CollectionSummary collection) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (BuildContext context) => CollectionScreen(collection: collection),
  ));
}

/// Calls [onLoadMore] when the scroll position is within one viewport of the end.
bool handleInfiniteScroll(ScrollNotification n, VoidCallback onLoadMore) {
  if (n.metrics.axis == Axis.vertical &&
      n.metrics.extentAfter < n.metrics.viewportDimension) {
    onLoadMore();
  }
  return false;
}

/// Shows [message] in a platform-style alert.
Future<void> showMessage(BuildContext context, String message) {
  return showAdaptiveDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final bool cupertino = Theme.of(context).platform == TargetPlatform.iOS;
      void close() => Navigator.of(context).pop();
      return AlertDialog.adaptive(
        content: Text(message),
        actions: <Widget>[
          if (cupertino)
            CupertinoDialogAction(onPressed: close, child: const Text('OK'))
          else
            TextButton(onPressed: close, child: const Text('OK')),
        ],
      );
    },
  );
}
