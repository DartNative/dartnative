# dartnative_system

App info and the home-screen badge for DartNative — read your app's name / version /
build, and set the app-icon badge count. iOS and Android, one API.

## Why you'll like it

- **App info in one call** — name, package id, version, and build number.
- **App badge** — set the icon badge (e.g. an unread count), clear it with `0`.
- **Both platforms, no setup.**

## Highlights

- **`PackageInfo.fromPlatform()`** → `appName`, `packageName`, `version`, `buildNumber`.
- **`AppBadgePlus.updateBadge(count)`** — set the app-icon badge (`0` clears it).
- **`AppBadgePlus.isSupported()`** — whether badging works on this device.

## Install

```yaml
dependencies:
  dartnative_system: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_system/dartnative_system.dart';
```

Read app info:

```dart
final info = await PackageInfo.fromPlatform();
print('${info.appName} ${info.version}+${info.buildNumber}');
```

Set (or clear) the app-icon badge:

```dart
if (await AppBadgePlus.isSupported()) {
  await AppBadgePlus.updateBadge(3); // show "3"
  await AppBadgePlus.updateBadge(0); // clear
}
```

> The iOS badge shows only if the user has allowed badges (notification permission).
> Android badge support depends on the launcher.

## Platform setup

### iOS

No native setup required.

### Android

No native setup required.

## Credits & license

Adapted from
[`package_info_plus`](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/package_info_plus)
(BSD-3-Clause) and [`app_badge_plus`](https://pub.dev/packages/app_badge_plus), reworked to FFI.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on
the plugin's page.
