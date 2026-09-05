# dartnative_video_player

A high-performance video player for DartNative — backed by the platform's own engines
(AVPlayer on iOS, ExoPlayer on Android) with byte-limited pre-caching. iOS and Android.

## Why you'll like it

- **Native playback engines** — AVPlayer and ExoPlayer do the decoding, so playback is smooth
  and battery-friendly, with the formats each platform supports out of the box.
- **Smart pre-caching** — start buffering the next clip ahead of time, with a byte budget so
  you control how much it pulls.
- **Bring your own controls** — ship the built-in controls, or overlay your own Dart UI on top
  of a clean video surface.

## Highlights

- **`VideoPlayerController(dataSource: …)`** — drive `play` / `pause` / `seekTo` / `setVolume` /
  `setSpeed` / `setLooping`.
- **`VideoDataSource.network(url, {headers, cacheConfig})`** / **`.file(path)`** — stream or
  play local files; pass a `VideoCacheConfig` to pre-cache.
- **`VideoPlayer(controller: …)`** — the player widget; set `aspectRatio`, `fit`, and
  `showControls`.
- **Ready-made controls** — `VideoPlayerWithControls` (player + controls), or `VideoOverlayControls` /
  `VideoBottomBarControls`, themed via `VideoControlsTheme`.

## Install

```yaml
dependencies:
  dartnative_video_player: ^1.0.0   # from dartpub.dev
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

**Play a network video**

```dart
import 'package:dartnative_video_player/dartnative_video_player.dart';

final controller = VideoPlayerController(
  dataSource: VideoDataSource.network('https://example.com/clip.mp4'),
  autoPlay: true,
);

// In your build():
VideoPlayer(
  controller: controller,
  aspectRatio: 16 / 9,
);
```

**Control playback**

```dart
controller.play();
controller.pause();
controller.seekTo(const Duration(seconds: 30));
controller.setSpeed(1.5);
controller.setVolume(0.8);
controller.setLooping(true);
```

**Play a local file**

```dart
final controller = VideoPlayerController(
  dataSource: VideoDataSource.file('/path/to/video.mp4'),
);
```

**Pre-cache ahead of time**

```dart
VideoDataSource.network(
  url,
  cacheConfig: const VideoCacheConfig(useCache: true, preCacheSize: 5 * 1024 * 1024),
);
```

> The player is a native view rendered through DartNative's view bridge
> (ViewType **1000**), so it sits naturally inside your Dart layout.

## Platform setup

### iOS

HTTPS URLs play out of the box. To play an **HTTP (non-TLS)** URL, add an App Transport
Security exception for that host in your app's `Info.plist`.

### Android

Requires **minSdk 26** — set it in `android/app/build.gradle.kts`:

```kotlin
android { defaultConfig { minSdk = 26 } }
```

The plugin's manifest already declares `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK` and
`FOREGROUND_SERVICE` — nothing to add. To play an **HTTP (cleartext)** URL on Android 9+,
enable cleartext traffic for that host (via `usesCleartextTraffic` or a network-security config).

## Example

The [`example/`](./example) app plays a network clip with custom controls and seeking — borrow
from it freely.

## Credits & license

Evolved from [`BetterPlayer`](https://github.com/jhomlala/betterplayer) (Apache-2.0) on Android,
substantially reworked for DartNative; native AVPlayer on iOS.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
