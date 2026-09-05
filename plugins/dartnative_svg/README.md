# dartnative_svg

Render SVGs natively in DartNative — from a bundled asset, a raw XML string, a file, or a
URL. Crisp at any size, drawn by the platform's own SVG engine. iOS and Android.

## Why you'll like it

- **Native rendering** — SVGKit on iOS, AndroidSVG on Android, through Core Animation /
  `android.graphics.Canvas` — sharp at any scale, no rasterization.
- **Five sources** — bundled asset, raw XML, a file, a network URL, or in-memory bytes.
- **Just a widget** — drop `SvgPicture.asset('icon.svg')` anywhere.

## Highlights

- **`SvgPicture.asset(path)`** — render a bundled SVG (declared under `flutter.assets:`).
- **`SvgPicture.string(xml)` / `.file(path)` / `.network(url)` / `.memory(bytes)`** — other sources.
- **`fit`** (`SvgFit`) and **`colorTint`** — control scaling and recoloring.

## Install

```yaml
dependencies:
  dartnative_svg: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_svg/dartnative_svg.dart';
```

A bundled asset:

```dart
SvgPicture.asset('assets/logo.svg', fit: SvgFit.contain);
```

Raw XML or a network URL:

```dart
SvgPicture.string('<svg viewBox="0 0 24 24">…</svg>');
SvgPicture.network('https://example.com/icon.svg');
```

## Platform setup

Assets, strings, files, and in-memory bytes need no setup. Network URLs need a little:

### iOS

Nothing for HTTPS. For `SvgPicture.network('http://…')` over plain **HTTP**, add an ATS exception
to `Info.plist`.

### Android

For `SvgPicture.network(…)`, add the internet permission to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

> Network SVGs are fetched once on mount and **not cached on disk** yet — they re-download each time
> the widget mounts.

## Example

The [`example/`](./example) app renders SVGs from each source — borrow from it freely.

## Credits & license

Renders with [SVGKit](https://github.com/SVGKit/SVGKit) (iOS) and
[AndroidSVG](https://github.com/BigBadaboom/androidsvg) (Android); the `SvgPicture` API will
feel familiar from `flutter_svg`.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
