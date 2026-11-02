# Work in the background

In Flutter you move heavy work off the UI with `compute` or `Isolate.run`.
DartNative does both jobs with less work on the UI thread: `compute` works
as in Flutter and runs on `runInBackground`, and `runInBackground` takes the
place of `Isolate.run`.

## Coming from Flutter

| In Flutter | In DartNative |
|---|---|
| `compute(parseItems, bytes)` | unchanged: `compute` runs on `runInBackground` |
| `Isolate.run(() => parseItems(bytes))` | `runInBackground(() => parseItems(bytes))`: change one word |

```dart
import 'package:dartnative/dartnative.dart';

// Flutter
final items = await Isolate.run(() => parseItems(bytes));

// DartNative
final items = await runInBackground(() => parseItems(bytes));
```

`Isolate.run` still works in DartNative, at its usual cost. It is part of
Dart itself, not of Flutter, so DartNative leaves it as Dart documents it
and offers the lighter path under its own name, and under Flutter's
`compute`.

## Why it is lighter on the UI

`Isolate.run` starts a new background isolate from the UI isolate on every
call, and the UI thread pays for that setup each time. Flutter's `compute`
calls `Isolate.run`.

`runInBackground` keeps a background isolate ready: a helper isolate,
started on the first call, starts the next one away from the UI. A call
sends the work in one message and gets the result back in one, without a
copy, as with `Isolate.run`.

## What it saves

The same code in a DartNative app and a Flutter app, on the same phones, in
release builds: a public transport stops file (61 KB and 234 KB) read into
objects on a background isolate.

| UI thread busy per call | Xiaomi 11 Lite 5G NE | iPhone 16 Pro |
|---|---|---|
| Flutter's `compute` | 0.189 ms | 0.049 ms |
| DartNative's `compute` | 0.124 ms, **1.5× less** | 0.031 ms, **1.6× less** |

Three calls at once: **1.7× less** on Android and **1.8× less** on iPhone.

Both are already low. At 120 Hz a frame has 8.3 ms: Flutter's `compute` uses
about 2% of one on Android, and less than 1% on iPhone. The
gain adds up when an app makes many background calls while it draws, for
example one per row of a scrolling list.

- **Speed:** the result arrives as soon as with `Isolate.run`, and the total
  CPU is about the same.
- **Large results:** for a result of 1 MB or more the two are level, because
  receiving the objects costs the same either way.
- **A worker pool:** one you build and size yourself gets about the same on
  the UI thread. `compute` needs nothing.

## The same rules as `Isolate.run`

- The function's captured values are copied to the background isolate.
  Write it as a function of its own that captures only the values it
  needs.
- Something that can't be sent, such as an open file or a socket, completes
  the future with an `ArgumentError`.
- An error the function throws completes the future with that error.
- `compute` takes Flutter's `debugLabel` and leaves it unused: its
  background isolate is ready before the call, and profiles show it as
  `runInBackground worker`.

## Built on it

`jsonDecodeInBackground` and `dartnative_http`'s `getJson` run on
`runInBackground`. See [JSON](json.md) and the
[JSON benchmark](../benchmarks/json/README.md) for the
whole request, compared with Flutter apps.
