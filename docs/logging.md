# Logging

DartNative unifies Swift and Dart log output into a single terminal stream — no more switching between Xcode and VS Code to correlate native-side behavior with Dart state.

```
dnLog()  ──► dn run stdout  ──► VS Code terminal
```

---

## Setup

The log bridge is **active by default**. Every `dnLog()` call in Swift and every `print()` / `dnLog()` call in Dart appears in your `dn run` terminal with no configuration required.

For file persistence (useful for CI, TestFlight, or Xcode-direct-launch scenarios), wrap your `main()` with `DartNativeLogger.run()`:

```dart
import 'package:dartnative/dartnative.dart';

void main() {
  DartNativeLogger.run(
    () {
      DartNativePluginRegistrant.registerAll();
      runApp(const MyApp());
    },
    verbose: true,      // enable framework-internal logs
    saveToFile: true,   // tee all output to a file on disk
  );
}
```

If `saveToFile` is `true`, the file path is printed at startup:

```
[DartNativeLogger] session log file: /tmp/dartnative_session.log
```

All sessions **append to this one fixed-path file**, each opening with a
`=== dartnative session <time> ===` header — so the pull path never changes
and a crashed session's tail is still on disk after the relaunch. Size is
**self-capped with nothing to configure**: the newest couple of megabytes of
history are always kept and older lines are pruned, so `saveToFile: true` is
safe to leave enabled in production builds.

---

## Usage

### Dart

```dart
import 'package:dartnative/dartnative.dart';

// App-level log — always emitted.
dnLog('[MyScreen] user tapped button');
```

### Swift / Kotlin (native side)

```swift
// In any Swift bridge file — always emitted, thread-safe.
dnLog("[MyPlugin] gesture recognised at \(point)")
```

### C / Objective-C plugins

```objc
// Resolved at runtime — no linking required.
void DNAppendLog(const char * _Nonnull ptr);
DNAppendLog("MyPlugin: callback fired");
```

---

## File persistence

File logging is designed for **non-interactive sessions** — CI runners, TestFlight, or when launching directly from Xcode without `dn run`. The default path uses the app's temporary directory:

```
${Directory.systemTemp.path}/dartnative_session.log
```

Pass an explicit path to use a predictable location:

```dart
DartNativeLogger.run(
  () { /* ... */ },
  saveToFile: true,
  filePath: '/path/to/app/documents/session.log',
);
```

Retrieve the file from a physical device:

```bash
xcrun devicectl device copy from --device <udid> \
  --domain-type appDataContainer --domain-identifier <your.bundle.id> \
  --source tmp --destination ./device_logs
```

`--source tmp` matches the default path above. If you set a custom
`filePath`, point `--source` at that location inside the app's container
instead — e.g. `--source Documents/session.log`.

---

## Why `saveToFile` can save you: debugging App Store / TestFlight builds

The hardest bugs are the ones that only exist in the binary your users get.
An archived (`dn build ipa`) build is post-processed differently from what
`dn run --release` installs, so an app can boot perfectly in every local run
and still fail when installed from TestFlight or the App Store. When that
happens you are nearly blind:

- Release builds print **no Dart output** to any console — `print()` and
  `dnLog()` go nowhere you can see.
- You can't attach a debugger or the VM service to a store build.
- If the failure happens during startup, there's no UI to inspect and often
  no crash report (a hang or a swallowed exception leaves the process alive
  on a frozen splash screen).

`saveToFile: true` is the escape hatch: every `dnLog()` — including native
lines forwarded by the log bridge, and calls made from native-triggered
callbacks like gestures — is persisted to a session file **inside the app's own
sandbox**, in release builds too. (Use `dnLog()`, not bare `print()`, in code
you need to capture: a `print()` from a native callback reaches the terminal
but isn't written to the file.) That file survives
the launch and can be pulled from the device afterwards:

```bash
xcrun devicectl device copy from --device <udid> \
  --domain-type appDataContainer --domain-identifier <your.bundle.id> \
  --source tmp --destination ./device_logs
```

Two properties make this production-safe and genuinely useful in a crisis:

- **Retention** (above) caps disk usage and keeps the most recent
  previous session — the log of the launch you're chasing is
  still there when you go looking for it.
- **The data container survives reinstalls.** A TestFlight install's sandbox
  isn't directly readable, but installing a dev-signed build of the same app
  over it gives you access to the same container — including the session logs
  the TestFlight build already wrote.

Real-world case: a production app passed every local run but hung on its
splash screen when installed from TestFlight (an archive-only
symbol-stripping issue). The persisted session logs showed each broken launch
had written only the session header — proof that `main()` died before its
first log line — which narrowed the failure to startup plugin registration
and led straight to the fix. Without `saveToFile`, the only signal would have
been a black screen.

**Recommendation:** ship with `saveToFile: true`, and log a short breadcrumb
between the awaits in your `main()` — in a store-build failure, the last
breadcrumb in the pulled log names the step that died. The pattern from a
production app (the same one from the case above — the breadcrumbs cost ~1 ms
total):

```dart
Future<void> main() async {
  await DartNativeLogger.run(
    () async {
      // Boot breadcrumbs: cheap one-liners that land in the persisted session
      // log so a TestFlight/App Store build that dies in main() shows exactly
      // which step it reached — release builds print nothing to the console.
      DartNativePluginRegistrant.registerAll();
      dnLog('[boot] plugins registered');

      registerSkiaFactories();
      DartNativeFontRegistrant.registerAll();
      dnLog('[boot] skia + fonts registered');

      await AppKeys.load(); // bundled config
      dnLog('[boot] config loaded');

      await SharedPrefs.instance.initialize();
      dnLog('[boot] prefs ready');

      await AppCache.initialize();
      dnLog('[boot] app cache ready');

      try {
        await Firebase.initializeApp();
      } catch (e) {
        dnLog('[boot] firebase init error: $e');
      }
      dnLog('[boot] firebase ready');

      dnLog('[boot] runApp');
      runApp(const App());
    },
    saveToFile: true, // production-safe: old session logs are pruned automatically
  );
}
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Swift logs not appearing in terminal | Make sure `DartNativePluginRegistrant.registerAll()` runs first in `main()` |
| Log file not created | Ensure `saveToFile: true` is set; check startup output for error messages |
| Log file empty on device | Use an explicit `filePath` pointing to the app's Documents directory |

---

## API Reference

### `dnLog(String message)`

App-level log — always emitted. Prefer this over bare `print()`. When
`saveToFile` is on, `dnLog` is persisted to the log file from **any** context —
including native callbacks (tap gestures, focus, scroll) that run outside the
`run` zone. A bare `print()` from such a callback still reaches the terminal but
is **not** written to the file, so always use `dnLog` in code you may need to
debug from a pulled log.

### `DartNativeLogger`

| Method | Description |
|--------|-------------|
| `DartNativeLogger.run(body, {verbose, saveToFile, filePath})` | Run [body] inside a zone that tees all `print()` calls to stdout and optionally to the fixed-path, size-capped session file |
| `DartNativeLogger.flush()` | Flush buffered output to disk. Also runs automatically when the app is backgrounded, so a session killed while suspended keeps its most recent lines — you rarely call it directly. |
| `DartNativeLogger.close()` | Close log file (further prints go to stdout only) |
| `DartNativeLogger.filePath` | Path of active log file, or `null` |
| `DartNativeLogger.isSavingToFile` | Whether file logging is active |
