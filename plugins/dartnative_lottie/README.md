# dartnative_lottie

Play Lottie animations natively in DartNative — from a bundled asset, runtime JSON, or a
URL — driven by Airbnb's Lottie engine. iOS and Android.

## Why you'll like it

- **The real Lottie engine** — `lottie-ios` and `lottie-android`, so animations play through
  Core Animation / the Android view system (smooth, hardware-friendly).
- **A frames renderer for the many** — a sticker keyboard or a chat thread shows dozens of
  animations at once; `renderCache: RenderCache.raster` draws each once, off the main thread,
  and plays bitmaps. Every cell shows at once, a sticker plays what has been drawn while the
  rest is drawn behind it, and an animation seen before is read back rather than drawn,
  across launches.
- **Three sources** — bundled asset, runtime JSON string, or a remote URL (with caching).
- **Play it your way** — autoplay + loop, or drive it imperatively with a `LottieController`.

## Highlights

- **`Lottie(asset: …)` / `Lottie(json: …)` / `Lottie(url: …)`** — the animation widget.
- **`loop`, `autoplay`, `speed`, `fit`** (`LottieFit`), and **`cachePolicy`** (`LottieCachePolicy.disk` / `.none`) inline.
- **`renderCache`** (`RenderCache.none` / `.raster`) — how the animation is drawn. `none`, the default, is the platform's animation engine: on iOS a layer tree built once per view and played by the render server with no per-frame work, right for a few animations on a screen and for large ones. `raster` is for many small animations at once: every frame is rendered once, off the main thread, at the size the widget shows it, kept compressed in memory and on disk, and played as bitmaps. A view costs nothing to build, and the main thread's share of playback is one bitmap per view per frame. An animation is rendered in order from its first frame, a few animations at a time: the ones on screen first, the highest on screen before the lower, so a grid completes the way it is read. A widget on an animation still being rendered shows its first frame at once, then plays the frames that exist and loops over them until the rest arrive, when it follows the clock; an animation that leaves the screen keeps rendering behind the ones that replaced it, so anything shown once ends up whole. Frames are kept compressed on disk for every animation, keyed by the file's contents so a reinstall finds them again, and in memory for the ones nobody is showing, up to 128 MB. Playback follows the file's frame rate up to the display's; scrubbing lands on the nearest frame. Same name and choice as the Flutter Lottie package. The same renderer on iOS and Android.
- **`LottieController`** — `play()` / `pause()` / `stop()` / `setProgress(0..1)` / `setLoopMode(LottieLoopMode…)`, plus a `progress` `ValueNotifier`.
- **`LottieCache.preload([urls])`** — warm `.json` / `.zip` / `.lottie` URLs ahead of time; watch `LottieCache.progressStream`.
- **`LottiePreWarm.warmAssets([paths], size: …, renderCache: …)`** — get bundled animations ready at the size they will show at, ahead of their first use. For `RenderCache.raster` it renders their frames ahead on both platforms, after anything on screen, so the first widget decodes instead of drawing. For the animation engine, iOS only, it builds each off-screen and keeps the built view for the first widget that shows it, on the same budgeted queue grid cells use, so warming a screen of stickers never stalls a frame.
- **One warning per file that the engine approximates** — iOS renders through Core Animation, which simplifies a few features (a trim on a filled shape, an animated dash pattern). A file with such layers is named once in the log, whether or not logging is verbose, with the count of layers concerned. It still plays at full speed; the line tells you which asset to check. The frames renderer draws every feature as written.

## Install

```yaml
dependencies:
  dartnative_lottie: ^1.3.0   # from dartpub.dev
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

A sticker in a grid of thirty, frames rendered once and played as bitmaps:

```dart
Lottie(asset: 'assets/stickers/7.json', loop: true, renderCache: RenderCache.raster);
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
The frames renderer draws with Samsung's [`rlottie`](https://github.com/Samsung/rlottie)
(MIT, with parts under their own permissive licences) and, on Android, compresses frames
with [LZ4](https://github.com/lz4/lz4) (BSD 2-Clause); all reproduced in the plugin's
`THIRD_PARTY_NOTICES`.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
