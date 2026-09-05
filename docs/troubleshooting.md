# Troubleshooting

Common issues and their fixes for DartNative app development.

---

## `dn run` fails with "Connection closed before full header was received"

### Symptom

`dn run -d <device-udid>` builds and installs the app successfully but fails at the last step:

```
Error connecting to the service protocol: failed to connect to
http://127.0.0.1:<port>/<authCode>/ HttpException: Connection closed
before full header was received
```

The app launches fine on the device. Xcode's "Product > Run" works.

### Root cause

`dn run` uses `iproxy` to forward the Dart VM service port over USB via `usbmuxd`. On macOS 15+ with iOS 17+ devices, `usbmuxd` can enter a stale state where it loses track of the device — typically after repeated installs, heavy Xcode sessions, or sleep/wake cycles. When `usbmuxd` loses the device, `iproxy` reports "No connected/matching device found" and the connection fails.

Note: `xcrun devicectl list devices` uses the CoreDevice framework and will still show the device even when `usbmuxd` has lost it. This is why Xcode works but `dn run` doesn't.

### Fix

**Restart the iPhone (or iPad).** This forces fresh USB negotiation and re-registers the device with `usbmuxd`. This resolves the issue in ~90% of cases.

If that doesn't work, try in order:

1. **Unplug and replug the USB cable.** Tap "Trust" on the device if prompted.
2. **Restart `usbmuxd`:**
   ```bash
   sudo launchctl kickstart -k system/com.apple.usbmuxd
   ```
3. **Restart your Mac.**

---

## White screen on launch — license error

### Symptom

App builds and installs. The device shows a blank white screen (or a dark error card) with logs:
```
DartNative License Error: No DartNative license found.
```

### Root cause

`runApp()` validates the license before rendering anything. Official demos
(the playground, tutorials, plugin examples) never need a license — the free
trial starts automatically — so this screen means you're building **your own**
app (your own bundle id) without an active license key.

### Fix

Subscribe at [dartpub.dev/framework](https://dartpub.dev/framework), copy your
license key (`dnk_…`), and run the config command once — after that `dn run`
just works:

```bash
dn config --license-key dnk_...
dn run -d <device-id>
```

Or pass the key per build without storing it:

```bash
dn build apk --release --dart-define=DN_LICENSE_KEY=dnk_...
```

---

## Emoji render as "?" boxes (iOS Simulator only)

### Symptom

Emoji in your app — in a `Text`, a `TextField`, or framework screens like the
license screen's key icon — render as empty boxes with a question mark on the
iOS Simulator.

### Root cause

Some iOS Simulator runtimes ship with the Apple Color Emoji font missing or
broken. DartNative renders text with real platform text views using the fonts
the OS provides, so a simulator without that font shows a "?" box for every
emoji — in every app in that simulator, not just yours. It's a Simulator font
gap, not an app issue.

### Fix

Nothing to fix in your app — real iPhones and Android devices render emoji
correctly with their own emoji fonts. To restore emoji in the Simulator,
update Xcode (which ships the Simulator runtimes).

---

## White screen on launch — license valid but UI never appears

### Symptom

App builds, installs, and runs. The Dart license validates ("License valid" in
logs). No crash. No error card. The device shows only a blank white screen.

### Root cause

`App(home: MyScreen())` provides theme and navigator inheritance but
**does not mount `home` natively**, so the screen stays white.

This is distinct from the license error (dark error card) and from the
in-place port problems below.

### Fix

Pass the root screen widget **directly** to `runApp()`:

```dart
// ✗ — home never reaches the native view hierarchy
runApp(App(title: 'My App', home: const MyScreen()));

// ✓
runApp(const MyScreen());
```

`App` is only needed when using named routes. For a single root screen, omit it.

> The playground (`playground/lib/main.dart`) calls `runApp(const DemosScreen())`
> directly and is the canonical working reference.

---

## Build or launch problems after porting a Flutter project in place

### Symptom

An app whose `ios/` folder came from a Flutter project builds but shows a white
screen with no crash, or fails to build with Swift errors about missing
DartNative symbols, `pod install` conflicts, or a deployment-target warning.

### Root cause

The iOS project still carries Flutter's bootstrap. A DartNative app starts
through two small delegate subclasses that the `dn create` scaffold provides,
and its Podfile installs every DartNative pod through the SDK's own helper.

### Fix

Make `ios/` match a `dn create` scaffold, which is the reference for every file:

- `Runner/AppDelegate.swift` subclasses `DartNativeAppDelegate` and
  `Runner/SceneDelegate.swift` subclasses `DartNativeSceneDelegate`, each a few
  lines. Keep the `UIApplicationSceneManifest` block in `Info.plist`; delete
  `UIMainStoryboardFile` if present.
- Take the scaffold's `Podfile` as is: `platform :ios, '14.0'`, the SDK
  podhelper, `dartnative_install_all_ios_pods`. Do not add `pod` lines by hand;
  pods are discovered from `pubspec.yaml`.
- Set `IPHONEOS_DEPLOYMENT_TARGET` to 14.0 in every configuration of
  `project.pbxproj`.

The simplest port is a fresh shell: `dn create` a new project and move `lib/`
and your assets into it.

---

## Icons rendering as "?" (CupertinoIcons / Material Symbols)

### Symptom

`Icon(Icons.*)` renders as `?` on device.

### Root cause

`Icons.*` constants use Flutter's classic Material Icons font, which DartNative
does not bundle. DartNative ships and registers `CupertinoIcons` and the
Material Symbols families; nothing else resolves.

### Fix

Replace `Icons.*` with the shipped classes:

| Instead of | Use |
|---|---|
| `Icons.close` | `CupertinoIcons.xmark` |
| `Icons.person` | `CupertinoIcons.person` |
| `Icons.arrow_back` | `CupertinoIcons.chevron_left` |
| `Icons.add` | `CupertinoIcons.add` |
| `Icons.delete` | `CupertinoIcons.trash` |
| any `Icons.*` | look up the same name in `MaterialSymbolsRounded.*` |

---

## Missing AppFrameworkInfo.plist

### Symptom

Build fails with:
```
PathNotFoundException: Cannot open file, path = '.../ios/Flutter/AppFrameworkInfo.plist'
```

### Fix

Copy the file from the DartNative playground or from any Flutter SDK example:

```bash
cp playground/ios/Flutter/AppFrameworkInfo.plist \
   ios/Flutter/AppFrameworkInfo.plist
```

Running `dn pub get` or `dn run` will auto-update its contents.

---

## `dn pub get` fails with "flutter_test not found" (exit code 69)

### Symptom

```
Because <app> depends on flutter_test from sdk which doesn't exist
(could not find package flutter_test in the Flutter SDK), version solving failed.
```

### Root cause

The `dn` toolchain does not include `flutter_test`. Apps created with `flutter create` include it in `dev_dependencies` by default.

### Fix

Remove `flutter_test` from `pubspec.yaml`:
```yaml
dev_dependencies:
  # flutter_test:         ← DELETE
  #   sdk: flutter        ← DELETE
```

Also delete `test/widget_test.dart` and the `test/` directory if they only contain the Flutter scaffold counter test. Then re-run `dn pub get`.

---

## `dn pub get` fails: "package X depends on flutter_web_plugins"

### Symptom

```
Because <app> depends on go_router X.Y.Z which requires flutter_web_plugins from sdk
which doesn't exist (could not find package flutter_web_plugins in the Flutter SDK),
version solving failed.
```

### Root cause

`dn` does not include `flutter_web_plugins`. Several popular packages depend on it, most notably `go_router`.

### Fix

Remove the offending package and replace its functionality:

| Remove | Replace with |
|---|---|
| `go_router` | `Navigator.push` / `Navigator.pop` / `Navigator.popUntil` |
| Other packages with `flutter_web_plugins` dependency | Check each individually |

---

## `setState` in gesture callbacks doesn't trigger a rebuild

### Symptom

Calling `setState()` inside `onTap`, `onPressed`, or other gesture callbacks appears to do nothing. The widget is not rebuilt. Sometimes `Timer` callbacks created in the same context fire out of order.

### Root cause

Gesture callbacks run synchronously inside the platform's own event, not as a Dart event-loop event. The microtask queue only drains after a real event-loop event, so a `Future.microtask` scheduled inside a gesture callback may not run until the next run-loop turn.

### Fix

Use `setState()` directly without any scheduling wrapper — this is always safe and preferred:

```dart
onTap: () => setState(() { _myState = newValue; }),
```

If you genuinely need to defer the state update (e.g. to wait for an async result), use `Timer.run` instead of `Future.microtask`:

```dart
// ✗ may feel "one frame late" in native callbacks
onTap: () => Future.microtask(() => setState(() { ... })),

// ✓ fires promptly after the current run-loop turn
onTap: () => Timer.run(() => setState(() { ... })),
```

---

## `sqflite` crashes or throws MissingPluginException

### Symptom

Adding `sqflite` to `pubspec.yaml` causes a crash at runtime or at `sqflite.openDatabase()`:

```
MissingPluginException(No implementation found for method getDatabasesPath
on channel com.tekartik.sqflite)
```

or a build-time linker error because the sqflite iOS plugin requires a Flutter engine present.

### Root cause

`sqflite` communicates through a Flutter MethodChannel, which DartNative apps do not have, so every platform method throws `MissingPluginException`.

### Fix

Replace `sqflite` with `dartnative_sqlite`, the official DartNative SQLite wrapper. It uses `sqflite_common_ffi` internally (direct FFI — no MethodChannel).

```yaml
# pubspec.yaml — remove sqflite, add dartnative_sqlite
dependencies:
  dartnative_sqlite:
    # from dartpub.dev
```

```dart
// Before (sqflite):
import 'package:sqflite/sqflite.dart';
final db = await openDatabase('app.db', version: 1, ...);

// After (dartnative_sqlite):
import 'package:dartnative_sqlite/dartnative_sqlite.dart';
Sqlite.ensureInitialized(); // call once at startup
final db = await Sqlite.open('${getApplicationDocumentsDirectory()}/app.db',
  version: 1, ...);
```

See the [`dartnative_sqlite`](https://dartpub.dev/plugins/dartnative_sqlite) page on dartpub.dev for the full API.

---

## Preferences background isolate fails silently

### Symptom

After spawning a background isolate, calls to `SharedPreferences.getInstance()` return unexpected values or appear to write values that the main isolate never sees.

### Root cause

This is **not an issue** with `dartnative_shared_preferences`. Unlike the Flutter `shared_preferences` package, it is backed by `NSUserDefaults` via Dart FFI and requires no platform-channel registration in secondary isolates. Any isolate can call `SharedPreferences.getInstance()` safely.

If values written in a background isolate are not visible on the main isolate, call `reload()` on the main isolate to refresh the in-memory snapshot from `NSUserDefaults`:

```dart
// Main isolate — after background work completes:
final prefs = await SharedPreferences.getInstance();
await prefs.reload();
final updatedValue = prefs.getString('background_result');
```

---

## Splash screen logo invisible (iOS)

### Symptom

The splash screen shows the correct background colour but the logo is not
visible — it appears as a blank area in the centre of the screen. The issue
persists regardless of which logo image is used.

### Root cause A — Template-image rendering (most common)

Xcode's `actool` auto-detects grayscale or near-monochrome PNGs as **template
images** (`"Template Mode": "automatic"` in `Assets.car`). Template images
are rendered in the view's `tintColor`, making the logo invisible against the
background.

**Fix:** in `LaunchImage.imageset/Contents.json`, add:
```json
"properties": {"template-rendering-intent": "original"}
```

### Root cause B — Image too large for `contentMode=center`

The storyboard sets `contentMode="center"` on the logo `UIImageView`, which
displays the image at its **native pixel size**. If the source image is wider
than the device, only the centre crop is visible. The `dartnative_splash`
generator scales images as `@Nx = source × N/4`.

### Root cause C — Splash screen dismissed by `makeKeyAndVisible()`

iOS shows the launch screen only until the window is up, before the Dart side
has drawn anything. DartNative keeps the splash on screen until the first frame
is ready, with a short minimum display time and the window background matched
to the splash colour, so there is no gap to fill by hand.

No manual configuration is needed — run `dart run dartnative_splash:setup`
after changing splash config in `pubspec.yaml`, then rebuild.

---

## Native-asset framework invalid signature (0xe8008014)

### Symptom

Installing the app on a physical iOS device fails with:

```
Failed to verify code signature of …/Runner.app/Frameworks/sqlite3.framework :
0xe8008014 (The executable contains an invalid signature.)
```

### Root cause

The `sqlite3` pub package (a transitive dependency of `sqflite_common_ffi` →
`dartnative_sqlite`) uses Dart's **native-assets** build hook to compile and
bundle `sqlite3.framework` at build time. The hook signs the resulting binary
**ad-hoc only** (`Signature=adhoc`, `TeamIdentifier=not set`). iOS's `installd`
rejects ad-hoc signed embedded frameworks during installation.

The same class of issue can affect any package that ships a pre-built or
build-hook-generated `.framework` without a real developer signature.

### Fix — automatic, via the standard DartNative Podfile

The standard DartNative Podfile handles this for every native-asset framework:
a build phase re-signs them with your app's identity before the IPA is
assembled. An app created with `dn create` already has it and needs nothing
beyond adding the dependency to `pubspec.yaml`. An app with an older Podfile
takes the scaffold's `post_install` block, then runs `pod install`.

### Verify

After a successful signed build, confirm the framework is properly signed:

```bash
codesign -dv build/ios/iphoneos/Runner.app/Frameworks/sqlite3.framework 2>&1 \
  | grep -E "TeamIdentifier|Authority"
# Should show your team ID and certificate, not "TeamIdentifier=not set"
```


---

## App stuck on splash screen after updating dartnative (iOS)

**Symptom:** After updating the `dartnative` package and running `pod install`, the app launches but never gets past the splash screen. No error is shown, the app is not crashed — it just hangs.

**Cause:** The native binary needs to be fully rebuilt after a framework update. If Xcode is using a cached build that doesn't match the new package version, startup fails silently before the splash can be dismissed.

**Fix:**

```bash
# 1. Clean the project
dn clean

# 2. Delete Xcode's build cache
rm -rf ~/Library/Developer/Xcode/DerivedData

# 3. Run again (this will trigger a full rebuild)
dn run -d <your-device-id> --dart-define=...
```

A full rebuild after the cache is cleared will resolve the issue.

---

## App breaks after switching between simulator/emulator and a real device

After building for the iOS Simulator or an Android emulator, a build for a
real device (or the other way round) can fail at runtime with native-library
load errors — on iOS, for example:

```
... incompatible platform (have 'iOS-simulator', need 'iOS')
```

If it occurs, the fix is:

```
dn clean
```

then rebuild.

---

## Flashing around the screen corners during a push or pop (iOS 26)

### Symptom

On iOS 26, pushing or popping a screen flashes white (or a colour that is
not the screen's) at the four corners, and sometimes in the gap between the
two screens, for the length of the transition. Both screens look right
before and after. Dark screens show it most.

### Root cause

An iOS 26 push does not slide two opaque rectangles: both screens become
cards with the display's corner radius, and the surface behind them shows
at the corners. That surface is a backdrop the navigator owns, painted with
the destination route's background colour, which the `Scaffold` reports.
A Scaffold with no `backgroundColor` reports the white default, so a screen
that paints its page colour inside the body, below the root, is dark at
rest and white in the backdrop.

### Fix

Declare the page colour on the Scaffold, and the trait on dark screens:

```dart
Scaffold(
  backgroundColor: Colors.black,
  brightness: Brightness.dark, // iOS 26 renders its scroll-edge fades in the trait
  body: content,
)
```

A plain full-bleed colour box at the body's root (`Container(color:)` or
`ColoredBox`, with no size, margin, constraints, alignment, radius, border,
shadow or gradient) is read as the page automatically; a colour painted any
deeper is not. A screen with no Scaffold reports nothing and keeps the
system backdrop (white in light mode, black in dark), so give it a Scaffold.
See "The screen's background belongs on the Scaffold" in the widgets guide.
