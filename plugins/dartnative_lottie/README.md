# dartnative_lottie

Play Lottie animations natively in DartNative — from a bundled asset, runtime JSON, or a
URL — driven by Airbnb's Lottie engine. iOS and Android.

## Why you'll like it

- **The real Lottie engine** — `lottie-ios` and `lottie-android`, so animations play through
  Core Animation / the Android view system (smooth, hardware-friendly).
- **Three sources** — bundled asset, runtime JSON string, or a remote URL (with caching).
- **Play it your way** — autoplay + loop, or drive it imperatively with a `LottieController`.

## Highlights

- **`Lottie(asset: …)` / `Lottie(json: …)` / `Lottie(url: …)`** — the animation widget.
- **`loop`, `autoplay`, `speed`, `fit`** (`LottieFit`), and **`cachePolicy`** (`LottieCachePolicy.disk` / `.none`) inline.
- **`LottieController`** — `play()` / `pause()` / `stop()` / `setProgress(0..1)` / `setLoopMode(LottieLoopMode…)`, plus a `progress` `ValueNotifier`.
- **`LottieCache.preload([urls])`** — warm `.json` / `.zip` / `.lottie` URLs ahead of time; watch `LottieCache.progressStream`.

## Install

```yaml
dependencies:
  dartnative_lottie: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_lottie/dartnative_lottie.dart';
```

Play a bundled animation on a loop:

```dart
Lottie(asset: 'assets/loading.json', loop: true);
```

From JSON fetched at runtime, a bit faster:

```dart
Lottie(json: jsonString, autoplay: true, speed: 1.5);
```

Drive it imperatively:

```dart
final controller = LottieController();

Lottie(asset: 'assets/check.json', autoplay: false, controller: controller);

// later…
controller.play();
controller.setProgress(0.5);
```

## Platform setup

Assets and runtime JSON need no setup. `Lottie(url: …)` (and `LottieCache.preload`) fetch over the network:

### iOS

Nothing for HTTPS. For an **HTTP** URL, add an App Transport Security exception in `Info.plist`.

### Android

Requires **minSdk 26** — set it in `android/app/build.gradle.kts`:

```kotlin
android { defaultConfig { minSdk = 26 } }
```

Add the internet permission to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## Example

The [`example/`](./example) app plays animations from each source and drives one with a
controller — borrow from it freely.

## Credits & license

Powered by Airbnb's [Lottie](https://airbnb.io/lottie/) —
[`lottie-ios`](https://github.com/airbnb/lottie-ios) and
[`lottie-android`](https://github.com/airbnb/lottie-android) (Apache-2.0).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
