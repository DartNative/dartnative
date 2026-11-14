import 'package:dartnative/dartnative.dart';

import 'api.dart';

/// Index of the selected bottom tab (0 Home, 1 Search, 2 Cart).
final ValueNotifier<int> currentTab = ValueNotifier<int>(0);

final CartStore cartStore = CartStore();

const String cartFailedMessage = "Couldn't update your cart. Check your connection and try again.";

/// In-memory cart. Every operation replaces the cart with the response's cart.
class CartStore extends ChangeNotifier {
  Cart? cart;
  bool busy = false;

  int get totalQuantity => cart?.totalQuantity ?? 0;

  /// Adds one of [variantId]. Returns an error message to show, or null.
  Future<String?> add(String variantId) {
    final String? id = cart?.id;
    return _run(() => id == null
        ? StorefrontApi.instance.cartCreate(variantId)
        : StorefrontApi.instance.cartLinesAdd(id, variantId));
  }

  /// Sets the quantity of [lineId]. Returns an error message to show, or null.
  Future<String?> update(String lineId, int quantity) {
    final String? id = cart?.id;
    if (id == null) return Future<String?>.value(null);
    return _run(() => StorefrontApi.instance.cartLinesUpdate(id, lineId, quantity));
  }

  Future<String?> _run(Future<CartResult> Function() op) async {
    busy = true;
    notifyListeners();
    try {
      final CartResult r = await op();
      if (r.cart != null) cart = r.cart;
      return r.errorMessage;
    } catch (_) {
      return cartFailedMessage;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
