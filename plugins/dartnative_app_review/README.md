# dartnative_app_review

In-app review prompt + store listing for DartNative apps (iOS + Android), over
FFI — no Flutter platform channels.

- **iOS** wraps `AppStore.requestReview(in:)` (iOS 16+), falling back to
  `SKStoreReviewController` on older versions.
- **Android** wraps the [Play In-App Review API](https://developer.android.com/guide/playcore/in-app-review)
  (`ReviewManager`).

## Usage

```dart
import 'package:dartnative_app_review/dartnative_app_review.dart';

final review = InAppReview.instance;

// The quota-limited native prompt — trigger it after a positive moment.
if (await review.isAvailable()) {
  await review.requestReview();
}

// An always-works "Rate us" action (not quota-limited). Opens THIS app's page —
// appStoreId is your app's App Store id (iOS only; Android uses its own package).
await review.openStoreListing(appStoreId: '1234567890');
```

`AppReviewFFIBindings.loadSymbols()` must run once at startup — the generated
`DartNativePluginRegistrant.registerAll()` does this for you.

## Two paths: quick stars vs. a full review

- **`requestReview()`** — the **system star sheet**: the user picks a rating and
  that's it. Apple/Google render it, so it **can't** be customized (no title,
  message, or buttons) and it's quota-limited. Frictionless, but no written
  feedback.
- **`openStoreListing()`** — opens the store's **review composer**, where the
  user leaves a **complete review**: stars **plus** a title and a written
  message. Not quota-limited — the reliable "Rate us" call to action.

## `requestReview()` is quota-limited

Both Apple and Google **heavily throttle** `requestReview()` and never tell you
whether the prompt was actually shown. Follow their guidance:

- **Do** call it after the user has had a genuinely positive experience (e.g.
  finished a task, sent a number of messages) — sparingly.
- **Don't** wire `requestReview()` to a "Rate us" button. A button that
  silently does nothing (quota exceeded) is a bad experience. Use
  `openStoreListing()` for a reliable call to action instead.

Apple: <https://developer.apple.com/design/human-interface-guidelines/ratings-and-reviews>
Google: <https://developer.android.com/guide/playcore/in-app-review#when-to-request>

## API

| Method | iOS | Android |
|---|---|---|
| `isAvailable()` → `Future<bool>` | `true` on iOS 10.3+ | `true` if Play Store installed |
| `requestReview()` → `Future<void>` | `AppStore.requestReview` / `SKStoreReviewController` | Play In-App Review flow |
| `openStoreListing({appStoreId})` → `Future<void>` | App Store review page (`appStoreId` **required**) | the app's own Play listing (package name) |

## Platform setup

### iOS
No setup required. `appStoreId` (App Store Connect → General → App Information →
Apple ID) is required for `openStoreListing`.

### Android
No setup required — the plugin pulls in `com.google.android.play:review`.
**Testing note:** `requestReview()` does nothing on a debug build / freshly
sideloaded app. Test it via a Play **internal testing** track (or internal app
sharing) — see the upstream
[testing guide](https://github.com/britannio/in_app_review#testing-read-carefully).

## Credits & license

Adapted from [`in_app_review`](https://github.com/britannio/in_app_review)
(MIT) — the StoreKit and Play In-App Review calls, reworked from
method channels to an FFI `@_cdecl` / JNI bridge. Commercial plugin
distributed via [dartpub.dev](https://dartpub.dev).
