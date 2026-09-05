# dartnative_shared_preferences

Simple key–value preferences for DartNative — `NSUserDefaults` on iOS, `SharedPreferences`
on Android — with the familiar `shared_preferences` API. iOS and Android.

## Why you'll like it

- **Familiar API** — `getInstance()`, then `getString` / `setBool` / …, like `shared_preferences`.
- **All the common types** — `String`, `int`, `double`, `bool`, `List<String>`.
- **Works from any isolate** — no platform channel, so reads and writes work outside the main isolate.
- **Zero setup** — backed by the platform's native defaults via the DartNative framework.

## Highlights

- **`SharedPreferences.getInstance()`** → the store.
- **`getString` / `getInt` / `getDouble` / `getBool` / `getStringList`** (+ `containsKey`).
- **`setString` / `setInt` / `setDouble` / `setBool` / `setStringList`**, plus `remove` / `clear` / `reload`.

> `getKeys()` (enumerate all keys) isn't available yet.

## Install

```yaml
dependencies:
  dartnative_shared_preferences: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

final prefs = await SharedPreferences.getInstance();

await prefs.setString('name', 'Ada');
await prefs.setBool('onboarded', true);

final name = prefs.getString('name');     // 'Ada'
final done = prefs.getBool('onboarded');  // true
```

## Platform setup

### iOS

No native setup required.

### Android

No native setup required.

## Example

The [`example/`](./example) app stores and reads a few settings — borrow from it freely.

## Credits & license

API mirrors Flutter's
[`shared_preferences`](https://github.com/flutter/packages/tree/main/packages/shared_preferences)
(BSD-3-Clause); the plugin ships its own native bridge — NSUserDefaults on iOS,
SharedPreferences on Android — over FFI, built on the DartNative framework's
runtime (FFI loader, and the Android application context).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
