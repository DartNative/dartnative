/// RevenueCat demo — the simple core of the RevenueCat examples (configure →
/// getOfferings → purchasePackage → restore → customerInfo), in DartNative
/// widgets. The official apps (MagicWeather, purchase_tester) wrap this same
/// API in elaborate UI; this is the minimal surface our plugin exposes.
///
/// `configure` and Customer info work with any RevenueCat public SDK key.
/// Offerings and purchases require products + an offering in YOUR RevenueCat app
/// (RevenueCat binds each key to one app id) — see ../../README.md. Easiest to test on
/// Android (`dn run` against your own app); iOS needs a StoreKit config run from
/// Xcode, or an App Store Connect sandbox.
library;

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_revenuecat/dartnative_revenuecat.dart';

// RevenueCat public SDK keys are loaded from a bundled `.dnkeys` at runtime via
// dartnative_keys (copy .dnkeys.example → .dnkeys and fill them in; .dnkeys is
// gitignored). DnKeys.load() runs in main() before this screen builds.
import 'package:dartnative_keys/dartnative_keys.dart';

class RevenueCatDemoApp extends StatelessWidget {
  const RevenueCatDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(
      title: 'dartnative_revenuecat',
      theme: ThemeData.dark(),
      home: const RevenueCatDemoScreen(),
    );
  }
}

class RevenueCatDemoScreen extends StatefulWidget {
  const RevenueCatDemoScreen({super.key});

  @override
  State<RevenueCatDemoScreen> createState() => _RevenueCatDemoScreenState();
}

class _RevenueCatDemoScreenState extends State<RevenueCatDemoScreen> {
  String _log = '';
  Offering? _current;
  bool _configured = false;

  void _appendLog(String msg) {
    print('[RevenueCatDemo] $msg');
    setState(() => _log = '$msg\n$_log');
  }

  @override
  void initState() {
    super.initState();
    _configure();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _configure() async {
    final keyName =
        Platform.isIOS ? 'REVENUECAT_IOS_API_KEY' : 'REVENUECAT_ANDROID_API_KEY';
    final apiKey = DnKeys.get(keyName);
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('YOUR_')) {
      _appendLog('⚠️ No RevenueCat key for ${Platform.isIOS ? 'iOS' : 'Android'}. '
          'Set $keyName in .dnkeys (copy .dnkeys.example). '
          'iOS needs REVENUECAT_IOS_API_KEY, Android needs REVENUECAT_ANDROID_API_KEY.');
      return;
    }
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
      _appendLog('✓ Configured.');
      // Fetch offerings right after configure so packages show without an extra
      // tap (empty unless this key's RevenueCat app has products — see README).
      await _getOfferings();
    } catch (e) {
      _appendLog('[configure] ERROR: $e');
    }
  }

  Future<void> _getOfferings() async {
    if (!_configured) {
      _appendLog('Not configured — set your API key.');
      return;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      setState(() => _current = current);
      if (current == null) {
        _appendLog('✓ getOfferings — no current offering (all: ${offerings.all.keys.toList()}).');
      } else {
        final ids = current.availablePackages.map((p) => p.identifier).toList();
        _appendLog('✓ Offering "${current.identifier}" — packages: $ids');
      }
    } catch (e) {
      _appendLog('[offerings] ERROR: $e');
    }
  }

  Future<void> _purchase(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      if (info == null) {
        _appendLog('Purchase cancelled.');
      } else {
        _appendLog('✓ Purchased ${package.identifier}\n  active: ${info.activeSubscriptions}');
      }
    } catch (e) {
      _appendLog('[purchase] ERROR: $e');
    }
  }

  Future<void> _restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _appendLog('✓ Restored\n  active: ${info.activeSubscriptions}');
    } catch (e) {
      _appendLog('[restore] ERROR: $e');
    }
  }

  Future<void> _customerInfo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _appendLog('✓ Customer ${info.originalAppUserId}\n'
          '  active: ${info.activeSubscriptions}\n'
          '  purchased: ${info.allPurchasedProductIdentifiers}');
    } catch (e) {
      _appendLog('[customerInfo] ERROR: $e');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'dartnative_revenuecat',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          const Text(
            'Configures on launch. Offerings & purchases need products in your '
            'own RevenueCat app (see README); Customer info works with any key.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _ActionButton(label: 'Refresh offerings', onTap: _getOfferings),
          const SizedBox(height: 8),
          if (current != null) ...[
            const SizedBox(height: 8),
            Text(
              'Offering "${current.identifier}"',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final p in current.availablePackages) ...[
              _ActionButton(
                label: 'Buy '
                    '${p.storeProduct.title.isNotEmpty ? p.storeProduct.title : p.identifier}'
                    ' · ${p.storeProduct.priceString}',
                onTap: () => _purchase(p),
                emphasized: false,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
          ],
          _ActionButton(label: 'Restore purchases', onTap: _restore),
          const SizedBox(height: 8),
          _ActionButton(label: 'Customer info', onTap: _customerInfo),
          const SizedBox(height: 24),
          if (_log.isNotEmpty)
            Text(
              _log,
              style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.emphasized = true,
  });
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: disabled
                ? const Color(0xFF48484A)
                : emphasized
                ? const Color(0xFF0A84FF)
                : const Color(0xFF8E8E93),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
