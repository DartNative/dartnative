import 'package:dartnative/dartnative.dart';
import 'package:dartnative_url_launcher/dartnative_url_launcher.dart';

import '../api.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: cartStore,
          builder: (BuildContext context, Widget? _) {
            final Cart? cart = cartStore.cart;
            final bool empty = cart == null || cart.lines.isEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text('Cart', style: ts(22, weight: FontWeight.w700)),
                ),
                if (empty)
                  const Expanded(child: _EmptyCart())
                else ...<Widget>[
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cart.lines.length,
                      itemBuilder: (BuildContext context, int i) =>
                          _CartLineRow(line: cart.lines[i], index: i, busy: cartStore.busy),
                    ),
                  ),
                  _Summary(cart: cart),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const VectorIcon(AppIcon.cart, size: 48, color: AppColors.textMuted, strokeWidth: 1.25),
            const SizedBox(height: 12),
            Text('Your cart is empty',
                textAlign: TextAlign.center, style: ts(17, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Items you add will appear here.',
                textAlign: TextAlign.center,
                style: ts(15, lineHeight: 22, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Start shopping',
              height: 48,
              expand: false,
              onTap: () => currentTab.value = 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({required this.line, required this.index, required this.busy});
  final CartLine line;
  final int index;
  final bool busy;

  Future<void> _setQuantity(BuildContext context, int quantity) async {
    final String? error = await cartStore.update(line.id, quantity);
    if (error != null && context.mounted) await showMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final bool showVariant = line.variantTitle.isNotEmpty && line.variantTitle != 'Default Title';
    return Semantics(
      container: true,
      identifier: 'cart-line-$index',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                    width: 80, height: 107, child: NetImage(line.imageUrl, width: 240, radius: 8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(line.productTitle,
                        style: ts(15, weight: FontWeight.w600, lineHeight: 20)),
                    if (showVariant) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(line.variantTitle, style: ts(13, color: AppColors.textMuted)),
                    ],
                    const Spacer(),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _StepButton(
                                id: 'qty-dec-$index',
                                label: 'Decrease quantity',
                                icon: AppIcon.minus,
                                onTap: busy ? null : () => _setQuantity(context, line.quantity - 1),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 24),
                                child: Text('${line.quantity}',
                                    textAlign: TextAlign.center,
                                    style: ts(15, weight: FontWeight.w600)),
                              ),
                              _StepButton(
                                id: 'qty-inc-$index',
                                label: 'Increase quantity',
                                icon: AppIcon.plus,
                                onTap: busy ? null : () => _setQuantity(context, line.quantity + 1),
                              ),
                            ],
                          ),
                        ),
                        Text(line.total.format(), style: ts(15, weight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.id, required this.label, required this.icon, required this.onTap});
  final String id;
  final String label;
  final AppIcon icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      id: id,
      label: label,
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 34,
        child: Center(
          child: VectorIcon(icon,
              size: 16,
              strokeWidth: 2,
              color: onTap == null ? AppColors.textMuted : AppColors.text),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: <Widget>[
              Text('Subtotal', style: ts(15)),
              Semantics(
                container: true,
                identifier: 'cart-subtotal',
                child: Text(cart.subtotal.format(), style: ts(17, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Taxes and shipping are calculated at checkout.',
              style: ts(13, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          PrimaryButton(
            id: 'checkout',
            label: 'Check out',
            onTap: () {
              if (cart.checkoutUrl.isNotEmpty) DartNativeUrlLauncher.launch(cart.checkoutUrl);
            },
          ),
        ],
      ),
    );
  }
}
