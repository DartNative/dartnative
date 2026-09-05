# dartnative_revenuecat

In-app purchases and subscriptions for DartNative — a drop-in take on
`purchases_flutter`, running natively on both platforms with **zero Flutter, pure
FFI**. Backed by RevenueCat's own [PurchasesHybridCommon](https://github.com/RevenueCat/purchases-hybrid-common)
(the same C-layer their Flutter/React Native/Unity SDKs use), so offerings,
purchases, and entitlements go through the shipping RevenueCat SDK. iOS and Android.

## Why you'll like it

- **Familiar API** — `Purchases.configure(...)`, `getOfferings()`,
  `purchasePackage(pkg)`, `restorePurchases()`, mirroring the `purchases_flutter`
  calls you already know.
- **The store sheets you expect** — real StoreKit / Play Billing purchase flows,
  driven by RevenueCat, not a re-implementation.
- **A focused surface** — the handful of calls a subscription app actually uses,
  with the same model classes (`Offering`, `Package`, `CustomerInfo`) and JSON
  parsers as upstream.

## Highlights

- **`Purchases.configure(PurchasesConfiguration(apiKey))`** — call once before
  anything else (set `..appUserID` to identify the user up front).
- **`Purchases.getOfferings()`** → `Offerings` (`.current`, `.all`), each
  `Offering` holding its `availablePackages`.
- **`Purchases.purchasePackage(package)`** → the updated `CustomerInfo`, or
  `null` if the user cancelled; throws `RevenueCatException` on failure.
- **`Purchases.restorePurchases()`** → `CustomerInfo`.
- **`Purchases.getCustomerInfo()`** → `CustomerInfo` (`activeSubscriptions`,
  `allPurchasedProductIdentifiers`).
- **`Purchases.logIn(appUserID)` / `logOut()`** — identify or anonymise the
  current user; `logIn` returns a `LogInResult` (`customerInfo`, `created`).
- **`Purchases.setAttributes({...})`** — subscriber attributes.
- **`Purchases.setLogLevel(LogLevel.debug)`** — verbosity, before or after
  configure.
- **`PurchasesErrorHelper.getErrorCode(e)`** → a typed `PurchasesErrorCode` for a
  caught `RevenueCatException`.

## Install

```yaml
dependencies:
  dartnative_revenuecat: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

Register the plugin once, in `main()`:

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'dart:io' show Platform;
import 'package:dartnative_revenuecat/dartnative_revenuecat.dart';

// Use the public SDK key that matches the platform you're running on.
final apiKey = Platform.isIOS ? 'appl_XXXX' : 'goog_XXXX';
await Purchases.configure(PurchasesConfiguration(apiKey));

// Show the current offering's packages…
final offerings = await Purchases.getOfferings();
final current = offerings.current;
for (final pkg in current?.availablePackages ?? const []) {
  print('${pkg.storeProduct.title} · ${pkg.storeProduct.priceString}');
}

// …buy one…
if (current != null && current.availablePackages.isNotEmpty) {
  final info = await Purchases.purchasePackage(current.availablePackages.first);
  if (info == null) {
    print('Purchase cancelled');
  } else {
    print('Active: ${info.activeSubscriptions}');
  }
}

// …restore, or check what the customer already owns.
final restored = await Purchases.restorePurchases();
final customer = await Purchases.getCustomerInfo();
```

Handle a failed purchase by mapping the exception to a typed code:

```dart
try {
  await Purchases.purchasePackage(pkg);
} on RevenueCatException catch (e) {
  final code = PurchasesErrorHelper.getErrorCode(e);
  if (code != PurchasesErrorCode.purchaseCancelledError) {
    // surface the error
  }
}
```

## Platform setup

RevenueCat is a service, so setup is mostly on **their** dashboard, not in your
app project.

### API keys

Grab your **public SDK keys** from [app.revenuecat.com](https://app.revenuecat.com)
→ **API keys** — an `appl_…` key for the iOS app and a `goog_…` key for the
Android app — and pass the platform-appropriate one to `configure`.

A key is **bound to one app id**. `configure`, `getCustomerInfo`, and `logIn`
work with any valid key, but **offerings and purchases only return data for the
app that key belongs to** — so the products and offering must exist in *your*
RevenueCat app. There is no universal key that shows offerings in an arbitrary
app.

### Products & offerings

To show packages or take a payment you also need products in the store **and** an
**offering** wired up in RevenueCat pointing at them:

- **Android** is the simplest loop — no Xcode, no StoreKit files. Create the
  subscriptions in **Google Play Console**, an offering in RevenueCat, and add
  your Google account under Play Console → **License testing** so test buys are
  free. Play Billing is then driven directly by `dn run`.
- **iOS** local testing goes through Xcode: add a **StoreKit Configuration file**
  to the Runner target with your offering's product ids, then select it under
  Edit Scheme ▸ Run ▸ Options ▸ **StoreKit Configuration**. Or test against an
  **App Store Connect** sandbox.

## Example

The [`example/`](./example) app is a complete configure → offerings → buy →
restore → customer-info harness — borrow from it freely.

It reads your **public SDK keys** from a gitignored `.dnkeys` (via
`dartnative_keys`). Copy the template and fill in the keys for the platform(s) you
test:

```bash
cd example
cp .dnkeys.example .dnkeys      # then add REVENUECAT_IOS_API_KEY / REVENUECAT_ANDROID_API_KEY
dn pub get
```

The example is an official demo — free to run, no license setup:

```bash
# Android — the simplest loop; drives Play Billing directly:
dn run -d <android-device>
```

`dn run` can't activate a StoreKit config, so **iOS** local testing runs from
Xcode:

```bash
dn build ios --config-only --debug
open ios/Runner.xcworkspace   # pick a simulator/device, ⌘R
```

`configure` and **Customer info** work with any valid key; **offerings and
purchases** stay empty until this key's RevenueCat app has products (see
[Platform setup](#platform-setup)). For hot reload after an Xcode launch, use
`dn attach`.

## Credits & license

Ported from [`purchases_flutter`](https://github.com/RevenueCat/purchases-flutter)
by RevenueCat, Inc. (MIT), on top of PurchasesHybridCommon — the RevenueCat SDK
does the real work on both platforms.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues
on the plugin's page.
