# dartnative_hive

[Hive](https://pub.dev/packages/hive_ce) for DartNative — a fast, pure-Dart key–value
database with a one-line native init. Same API on iOS and Android.

## Why you'll like it

- **Pure-Dart speed** — Hive (community edition), no platform channels.
- **One-line init** — `Hive.initDartNative(docsDir)` and you're set.
- **The full Hive API** — the code of hive_ce 2.20.1, ported into this package and behaving
  the same: boxes, type adapters, lazy boxes, keys in sorted order, box events. hive_ce's own
  tests pass on it.
- **Fast, safe writes** — boxes are stored in memory-mapped files, a mechanism built into
  iOS and Android. A `put` hands the value to the operating system before it returns, so
  nothing is lost if the app crashes or is killed.

## Highlights

- **`Hive.initDartNative(docsDirPath, {subDir, mmap})`** — point Hive at a storage directory.
- **`Hive.openBox(name)`** + **`box.put` / `box.get` / `box.delete`** — the usual Hive API.

## Install

```yaml
dependencies:
  dartnative_hive: ^2.0.0   # from dartpub.dev
```

```bash
dn pub get
```

## Quick look

```dart
import 'package:dartnative_hive/dartnative_hive.dart';

// Point Hive at your app's documents directory, once at startup
// (getApplicationDocumentsDirectory() from dartnative_path_provider):
Hive.initDartNative(documentsPath);

final box = await Hive.openBox('settings');
await box.put('theme', 'dark');
final theme = box.get('theme'); // 'dark'
```

## Type adapters

To store your own classes and enums, generate their adapters with
[dartnative_hive_generator](https://dartpub.dev/plugins/dartnative_hive_generator):

```yaml
dev_dependencies:
  dartnative_hive_generator:
    hosted: https://dartpub.dev
    version: ^2.0.0
  build_runner: ^2.5.4
```

```bash
dn pub run build_runner build
```

Its README shows the annotations. Adapters written by hand work as they do in any Hive app.

## Platform setup

### iOS

No native setup required.

### Android

No native setup required.

## Fast, safe writes

Boxes are stored in memory-mapped files, a mechanism built into iOS and Android: the file's
contents sit in memory that belongs to the operating system, not to the app, and the system
writes them to storage itself. A `put` copies the value there before it returns, even if its
future is never awaited. From that moment the value is safe: nothing is lost if the app
crashes, is closed from the app switcher, or is stopped by the system. A small value takes
under a microsecond.

The one event the system cannot cover is a sudden loss of power before it has written the
data to storage, which can lose the latest writes of any app that writes files. When a value
must survive even that, `await box.flush()`: it returns once the data is on the device's
storage.

Reads are a lookup in memory.

On hive_ce's own benchmark, 1,000 awaited `box.add` calls of a ten-field object take
1.61 ms on an iPhone 16 Pro, against 22.8 ms for hive_ce in a Flutter app on the same
phone; 100,000 take 0.17 s against 2.34 s.

![hive_ce's benchmark on an iPhone 16 Pro: dartnative_hive is 13 to 57 times faster than hive_ce in a Flutter app, from 10 to 100,000 writes](https://github.com/user-attachments/assets/87e1bd8c-85d3-4c99-843d-5d5095051e2e)

Writes and reads of a short string, on 1 key and on 1000 keys, on the same phone:

![Writes and reads on an iPhone 16 Pro: writes 44 times faster on 1 key and 15 times faster on 1000 keys; reads about the same, a lookup in memory in both](https://github.com/user-attachments/assets/30d884b0-5249-41ea-9e73-9c460ceaea83)

A mid-range Android phone shows gains of the same size, measured against hive_ce's own
file storage on that phone: 16 to 97 times faster on hive_ce's benchmark, and 23 to 49 times
faster on awaited writes of a short string.

The example's
[`benchmarks/`](https://github.com/DartNative/dartnative/tree/main/plugins/dartnative_hive/example/benchmarks) folder has every number and how it was measured.

To use hive_ce's own file storage instead, where a `put` is safe once its future
completes, pass `mmap: false`:

```dart
Hive.initDartNative(documentsPath, mmap: false);
```

The file format is the same either way, so existing boxes open in both modes. The
example's Benchmark screen times writes and reads in both modes on your own device.

## Example

The [`example/`](https://github.com/DartNative/dartnative/tree/main/plugins/dartnative_hive/example) app opens a box and round-trips a value, and its Benchmark
screen times every kind of write and read in both modes — borrow from it freely.

Run it:

```sh
cd example
dn pub get
dn run -d <device-id>
```

The example is an official demo — free to run, no license setup. Always use `dn` (not the
underlying SDK CLI) for run/build/pub commands.

## Credits & license

Built on the source of [`hive_ce`](https://pub.dev/packages/hive_ce), the community
edition of Hive, ported into this package; its licence is in `THIRD_PARTY_NOTICES`.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
