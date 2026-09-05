# dartnative_sqlite

SQLite for DartNative — a `sqflite`-style database API (`execute` / `query` / transactions /
batches) over the device's SQLite through the pure-Dart `sqflite_common_ffi`. No platform
channels, nothing to configure. iOS and Android.

## Why you'll like it

- **Familiar `sqflite`-style API** — `execute` / `insert` / `query` / `rawQuery` / batches.
- **Pure Dart** — runs against the device's SQLite via `sqflite_common_ffi`.
- **Transactions & batches** — group writes efficiently, with `ConflictAlgorithm` for upserts.

## Highlights

- **`Sqlite.open(path, version: 1)`** → a `SqliteDatabase`.
- **`db.execute` / `rawInsert` / `rawUpdate` / `rawDelete`**, **`db.query` / `rawQuery`**.
- **`db.batch()`** — batched writes.

## Install

```yaml
dependencies:
  dartnative_sqlite: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

## Quick look

```dart
import 'package:dartnative_sqlite/dartnative_sqlite.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';

final docsDir = getApplicationDocumentsDirectory();
final db = await Sqlite.open('$docsDir/app.db', version: 1);

await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
await db.rawInsert("INSERT INTO users (name) VALUES ('Ada')");

final rows = await db.rawQuery('SELECT * FROM users'); // List<Map<String, Object?>>
```

## Platform setup

**None** — just add the dependency to your `pubspec.yaml` (above) and `dn pub get`. No iOS or
Android configuration is required.

## Example

The [`example/`](./example) app creates a table and reads it back — borrow from it freely.

Run it:

```sh
cd example
dn pub get
dn run -d <device-id>
```

The example is an official demo — free to run, no license setup. Always use `dn` for
run/build/pub commands — not the underlying SDK CLI.

## Credits & license

A thin facade over
[`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) (BSD-2-Clause).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
