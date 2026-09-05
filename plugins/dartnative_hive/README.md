# dartnative_hive

[Hive](https://pub.dev/packages/hive_ce) for DartNative — a fast, pure-Dart key–value
database with a one-line native init. Same API on iOS and Android (and anywhere Dart runs).

## Why you'll like it

- **Pure-Dart speed** — Hive (community edition), no platform channels.
- **One-line init** — `Hive.initDartNative(docsDir)` and you're set.
- **The full Hive API** — boxes, type adapters, lazy boxes — re-exported as-is.

## Highlights

- **`Hive.initDartNative(docsDirPath, {subDir})`** — point Hive at a storage directory.
- **`Hive.openBox(name)`** + **`box.put` / `box.get` / `box.delete`** — the usual Hive API.

## Install

```yaml
dependencies:
  dartnative_hive: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

## Quick look

```dart
import 'package:dartnative_hive/dartnative_hive.dart';

// Point Hive at your app's documents directory, once at startup:
Hive.initDartNative(documentsPath);

final box = await Hive.openBox('settings');
await box.put('theme', 'dark');
final theme = box.get('theme'); // 'dark'
```

## Platform setup

### iOS

No native setup required.

### Android

No native setup required.

## Example

The [`example/`](./example) app opens a box and round-trips a value — borrow from it freely.

Run it:

```sh
cd example
dn pub get
dn run -d <device-id>
```

The example is an official demo — free to run, no license setup. Always use `dn` (not the
underlying SDK CLI) for run/build/pub commands.

## Credits & license

A thin facade over [`hive_ce`](https://pub.dev/packages/hive_ce), the community edition of Hive.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
