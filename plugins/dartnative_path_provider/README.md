# dartnative_path_provider

Synchronous, FFI-backed app directories for DartNative apps — documents, support, cache,
and temp paths on iOS and Android, with no `MethodChannel` and no `await`.

## Why you'll like it

- **Synchronous** — every call returns a `String` path directly, not a
  `Future<Directory>`. No `await`, no plugin-channel round-trip.
- **Both platforms** — iOS and Android from one import; the right native source is
  resolved at runtime.
- **Drop-in** — same names as `path_provider`, so porting is mostly deleting `await`.

## Highlights

- **`getApplicationDocumentsDirectory()`** — user documents that should be backed up.
- **`getApplicationSupportDirectory()`** — app-support files the user shouldn't touch.
- **`getApplicationCacheDirectory()`** — cache files, longer-lived than temp.
- **`getTemporaryDirectory()`** — transient cache the OS may purge.

## Install

```yaml
dependencies:
  dartnative_path_provider: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_path_provider/dartnative_path_provider.dart';

final docs    = getApplicationDocumentsDirectory();  // backed-up user documents
final support = getApplicationSupportDirectory();     // app-support files
final cache   = getApplicationCacheDirectory();       // longer-lived cache
final tmp     = getTemporaryDirectory();              // purgeable cache

final db = File('$docs/app.db');
```

No `await` — paths are resolved synchronously over FFI. The plugin ships its own
native code on both platforms: a Swift bridge compiled into the app on iOS
(`DynamicLibrary.process()`), and its own `libdartnative_path_provider.so` on
Android.

## Platform setup

No config files or manifest entries on either platform. The one requirement:
Android **minSdk 26** — set it in `android/app/build.gradle.kts`:

```kotlin
android { defaultConfig { minSdk = 26 } }
```

## Example

The [`example/`](./example) app resolves and shows the directories — borrow from it
freely.

Run it:

```sh
cd example
dn pub get
dn run -d <device-id>
```

The example is an official demo — free to run, no license setup. Always use
`dn` for run/build/pub commands.

## Credits & license

API-compatible with [`path_provider`](https://pub.dev/packages/path_provider)
(BSD-3-Clause), reworked to synchronous FFI.

Distributed via [dartpub.dev](https://dartpub.dev) — file issues on the plugin's page.
