# dartnative_url_launcher

Open URLs from DartNative — web links, `mailto:`, `tel:`, `sms:`, and deep links into
other apps. A familiar `launch` / `canLaunch` API, plus a smart opener that routes
common services (YouTube, Maps, Spotify, …) straight to their app when it's installed.
iOS and Android, one API.

## Why you'll like it

- **Smart app-routing** — `UrlLauncherHelper.open(url)` opens the native app (YouTube,
  Maps, Spotify, Amazon, social) when present, and falls back to the browser.
- **Familiar API** — `launch` / `canLaunch`, like Flutter's `url_launcher`.
- **iOS + Android** — one Dart API for both.

## Highlights

- **`DartNativeUrlLauncher.launch(url)`** — open a URL in the default app; returns success.
- **`DartNativeUrlLauncher.canLaunch(url)`** — is there an app that can handle it?
- **`UrlLauncherHelper.open(url)`** — smart opener: native-app-first with browser fallback,
  returns `(success, note)` telling you which path it took.

## Install

```yaml
dependencies:
  dartnative_url_launcher: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_url_launcher/dartnative_url_launcher.dart';
```

Open a link:

```dart
await DartNativeUrlLauncher.launch('https://dartnative.com');
await DartNativeUrlLauncher.launch('mailto:hi@example.com?subject=Hello');
await DartNativeUrlLauncher.launch('tel:+15551234567');
```

Check first:

```dart
if (DartNativeUrlLauncher.canLaunch('sms:+15551234567')) {
  await DartNativeUrlLauncher.launch('sms:+15551234567');
}
```

Smart open — routes to the app, falls back to the browser:

```dart
final (ok, note) = await UrlLauncherHelper.open('https://youtu.be/dQw4w9WgXcQ');
print(note); // "YouTube app"  or  "browser (YouTube app not installed)"
```

## Platform setup

### iOS

`canLaunch` can only see **custom app schemes** you declare in `ios/Runner/Info.plist`.
`http`, `https`, `mailto`, `tel`, and `sms` need nothing; the smart opener's app schemes do:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>youtube</string>
  <string>comgooglemaps</string>
  <string>amazon</string>
</array>
```

### Android

Same rule: `http`, `https`, `mailto`, `tel`, and `sms` need nothing, the plugin
declares them for you. On Android 11+ (API 30) an app only sees the apps it
queries for, so a **custom scheme** you open needs a query in
`android/app/src/main/AndroidManifest.xml` for `canLaunch` to resolve it:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="youtube" />
  </intent>
</queries>
```

## Example

The [`example/`](./example) app opens web, mail, tel, and a few app deep links — borrow
from it freely.

## Credits & license

Adapted from Flutter's
[`url_launcher`](https://github.com/flutter/packages/tree/main/packages/url_launcher)
(BSD-3-Clause) — reworked to FFI, with the smart app-router added.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on
the plugin's page.
