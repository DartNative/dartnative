# dartnative — Plugin Development Guide

This guide explains how to build a third-party plugin (e.g. a video player, map
view, or camera preview) on top of dartnative **without modifying the framework
source**. All four integration layers are open for extension by design.

> **Tip — already have a Flutter plugin? Port it, don't rewrite it.** If you
> maintain a Flutter plugin, start from your existing native
> code: keep the SDK-interaction logic as is, strip the method channels, and
> expose the same operations via FFI (iOS) / JNI (Android) as shown below.
> The SDK edge cases your plugin has accumulated over the years are the
> valuable part — carry them over.

---

## Overview of the four layers

```
┌─────────────────────────────────────────────────────────────────────┐
│  Dart (your plugin)                                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  1. Widget  (StatelessWidget / StatefulWidget)                │  │
│  │     Your public API surface — e.g. VideoPlayer(url: …)       │  │
│  └───────────────┬───────────────────────────────────────────────┘  │
│                  │ extends NativeElement                             │
│  ┌───────────────▼───────────────────────────────────────────────┐  │
│  │  2. NativeElement  (registered via registerElementFactory)    │  │
│  │     Converts widget props → CreateView + plugin mutations     │  │
│  └───────────────┬───────────────────────────────────────────────┘  │
│                  │ ViewType int + writePluginMutation                │
│  ┌───────────────▼───────────────────────────────────────────────┐  │
│  │  3. The framework's batch                                     │  │
│  │     CreateView(typeIndex) + your plugin mutations, untouched  │  │
│  └───────────────┬───────────────────────────────────────────────┘  │
└──────────────────┼──────────────────────────────────────────────────┘
                   │ FFI
┌──────────────────▼──────────────────────────────────────────────────┐
│  Swift (your plugin)                                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  4. DNPluginProvider  (registered via DNPluginRegistry)       │  │
│  │     createView(typeIndex:) + handleMutation(viewId:…)         │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

If your plugin has **no view** (it wraps system APIs that return values or fire
callbacks), you only write layers 1 and 4 — see
[Pure FFI plugins](#8-pure-ffi-plugins-no-view).

---

## 1. Claim your ViewType

Every native view type travels the wire as an integer `typeIndex`. You never
pick that integer yourself — you **claim a namespaced string key** (your
package name) and the framework assigns the index at runtime:

```dart
// In your plugin package — anywhere after registerAll() has run:
abstract final class VideoPlayerViewType {
  /// Assigned at runtime by the framework; the native side claims the
  /// same key and receives the same index.
  static final int player = ViewType.claim('com.example.video_player/player');
}
```

Your native side claims the **same key** and receives the **same index** —
both sides ask one process-global allocator, so they always agree, and two
plugins can never collide because package names are already globally unique.
The claim templates in [§3](#3-swift-side--dnpluginprovider-ios) (Swift) and
[§4](#4-kotlin-side--dnandroidpluginprovider-android) (Kotlin) show the
one-liner on each platform. Claim one key per view type your plugin provides
(`com.example.myplugin/player`, `com.example.myplugin/thumbnail`, …).

Indices stay stable for the process lifetime, including across hot
restarts, and are never re-used for a different key.

**Do not hardcode an integer.** Hardcoded indices collide silently across
plugins — whichever provider registered first wins, with no error, and the
wrong native view appears. Debug builds therefore **reject** any plugin
`typeIndex` that was not allocated by `ViewType.claim`.
`ViewType.claim` is the only supported way to obtain a plugin index.

---

## 2. Dart side — Widget + NativeElement

### 2a. Write the widget

```dart
import 'package:dartnative/dartnative.dart';

class VideoPlayer extends StatelessWidget {
  const VideoPlayer({super.key, required this.url, this.autoPlay = false});
  final String url;
  final bool autoPlay;

  @override
  Widget build(BuildContext context) => throw UnimplementedError(
    'VideoPlayer is a native leaf widget — build() is never called',
  );
}
```

NativeElement leaf widgets are never built; they go straight to
`DartNativeReconciler` via `registerElementFactory`.

### 2b. Write the NativeElement

`package:dartnative/plugin.dart` is the plugin surface: the element base
class, the view props, `PluginMutation`, `ViewType` and the layout mutations a
hosted view may need. It is the only import a plugin needs beyond
`dartnative.dart`.

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative/plugin.dart';

// Plugin-defined event tags (arbitrary integers, private to your plugin):
abstract final class _VideoEvent {
  static const int setUrl    = 1;
  static const int play      = 2;
  static const int pause     = 3;
  static const int seekMs    = 4;
  static const int setMuted  = 5;
}

class VideoPlayerElement extends NativeElement {
  VideoPlayerElement(VideoPlayer super.widget);

  VideoPlayer get _vp => widget as VideoPlayer;

  @override
  int get viewType => VideoPlayerViewType.player;   // claimed in §1

  @override
  ViewProps buildProps() => const FlexProps(direction: 0, grow: 1); // fill the slot

  @override
  void mount(Element? parent, UIKitReconciler reconciler) {
    super.mount(parent, reconciler);   // creates the native view
    _sendUrl(_vp.url);
    if (_vp.autoPlay) _sendPlay();
  }

  @override
  void update(Widget newWidget) {
    final old = _vp;
    super.update(newWidget);
    if (_vp.url != old.url) _sendUrl(_vp.url);
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _send(int tag, Uint8List data) =>
      emitMutation(PluginMutation(viewId!, tag, data));

  void _sendUrl(String url) =>
      _send(_VideoEvent.setUrl, Uint8List.fromList(utf8.encode(url)));

  void _sendPlay() => _send(_VideoEvent.play, Uint8List(0));

  void _sendPause() => _send(_VideoEvent.pause, Uint8List(0));

  void _sendSeek(int ms) {
    final bytes = ByteData(4)..setInt32(0, ms, Endian.little);
    _send(_VideoEvent.seekMs, bytes.buffer.asUint8List());
  }
}
```

### 2c. Register the factory

Call this once, before `runApp()`:

```dart
void initializeVideoPlayerPlugin() {
  DartNativeReconciler.registerElementFactory<VideoPlayer>(
    (w) => VideoPlayerElement(w),
  );
}
```

That's the whole Dart side. Next: the native provider that creates and
drives the view.

---

## 3. Swift side — `DNPluginProvider` (iOS)

Three steps. The pod self-registers; the app developer touches nothing.

**Step 1.** Create `ios/Classes/DN<Plugin>PluginProvider.swift` from the
template below. Edit the three `MY_*` constants + the `handleMutation`
switch body. Done.

**Step 2.** Add one line to your `<Plugin>FFIBindings.loadSymbols()`:

```dart
lib.lookupFunction<Void Function(), void Function()>(
  'DNMyPluginRegisterProvider',
)();
```

**Step 3.** Declare the registrant block in your `pubspec.yaml` (see
[§11](#11-plugin-registration-in-app-main)).

That's it. The official `dartnative_google_maps`, `dartnative_video_player`,
and `dartnative_webview` plugins follow exactly this shape.

### 3a. Copy-paste template

```swift
// ios/Classes/DNMyPluginProvider.swift
import UIKit
// import YourSDK   // AVFoundation, GoogleMaps, WebKit, …

private func dnLog(_ msg: String) { print("[DNMyPlugin] \(msg)") }

// EDIT ME ─────────────────────────────────────────────────────────────────
private let MY_TYPE_KEY = "com.example.myplugin/player"  // must match Dart ViewType.claim key
private let MY_EVENT_DO_FOO: Int32 = 1                   // must match Dart event tag
// ──────────────────────────────────────────────────────────────────────────

/// Claimed lazily on first use. Same key as the Dart side → same index,
/// assigned by the framework at runtime (collision-free — see §1).
private let MY_TYPE_INDEX: Int32 = {
    typealias ClaimFn = @convention(c) (UnsafePointer<CChar>) -> Int32
    guard let s = dlsym(dlopen(nil, RTLD_NOLOAD), "DNViewTypeClaim") else { return -1 }
    return MY_TYPE_KEY.withCString { unsafeBitCast(s, to: ClaimFn.self)($0) }
}()

/// Self-sizing container: pins its first subview to its own bounds.
/// Drop this if your view honours Yoga's frame natively.
private final class _Container: UIView {
    override func layoutSubviews() { super.layoutSubviews(); subviews.first?.frame = bounds }
    override func didAddSubview(_ s: UIView) {
        super.didAddSubview(s)
        if bounds.width > 0 || bounds.height > 0 { s.frame = bounds }
    }
}

private let _createView: @convention(c) (Int32) -> Int64 = { typeIndex in
    guard typeIndex == MY_TYPE_INDEX else { return 0 }
    return Int64(Int(bitPattern: Unmanaged.passRetained(_Container()).toOpaque()))
}

private let _handleMutation: @convention(c)
    (Int64, Int32, UnsafePointer<UInt8>?, Int32) -> Void =
{ viewId, eventTag, dataPtr, dataLen in
    guard let view = _viewFor(viewId) as? _Container else { return }
    switch eventTag {
    case MY_EVENT_DO_FOO:
        // decode dataPtr[0..<dataLen] and apply to `view`
        break
    default:
        dnLog("unknown eventTag=\(eventTag)")
    }
}

// ── Plumbing (do not edit) ────────────────────────────────────────────────
private typealias _GetViewFn = @convention(c) (Int64) -> Int64
private let _dnGetView: _GetViewFn? = {
    guard let s = dlsym(dlopen(nil, RTLD_NOLOAD), "DNViewRegistryGetView") else { return nil }
    return unsafeBitCast(s, to: _GetViewFn.self)
}()
private func _viewFor(_ id: Int64) -> UIView? {
    guard let fn = _dnGetView else { return nil }
    let p = fn(id); guard p != 0 else { return nil }
    return Unmanaged<UIView>.fromOpaque(UnsafeRawPointer(bitPattern: Int(p))!).takeUnretainedValue()
}

@_cdecl("DNMyPluginRegisterProvider")
public func DNMyPluginRegisterProvider() {
    guard let s = dlsym(dlopen(nil, RTLD_NOLOAD), "DNRegisterPluginProvider") else {
        dnLog("dlsym DNRegisterPluginProvider FAILED — is dartnative_ios linked?"); return
    }
    typealias _RegFn = @convention(c) (Int64, Int64) -> Void
    let reg = unsafeBitCast(s, to: _RegFn.self)
    reg(
        unsafeBitCast(_createView as @convention(c) (Int32) -> Int64, to: Int64.self),
        unsafeBitCast(_handleMutation as @convention(c)
            (Int64, Int32, UnsafePointer<UInt8>?, Int32) -> Void, to: Int64.self),
    )
}
```

> **Heads-up on `dnLog`.** If your pod already defines a module-level
> `dnLog` in another file, delete the `private func dnLog` line at the top —
> Swift treats `private` functions as file-private, so two unprefixed `dnLog`
> declarations across files in the same module collide.

### 3b. Why dlsym, not `import dartnative_ios`

Importing `dartnative_ios` from the plugin pod creates a circular CocoaPods
dependency (the framework loads plugins; plugins can't load the framework).
`dlsym(dlopen(nil, RTLD_NOLOAD), …)` resolves `DNRegisterPluginProvider` and
`DNViewRegistryGetView` from the already-linked process image at runtime —
zero compile-time coupling. Every official view plugin uses this trick.

### 3c. Never do this

| ❌                                                       | ✅                                       |
|:---------------------------------------------------------|:----------------------------------------|
| `DNPluginRegistry.shared.register(…)` in `AppDelegate`   | `@_cdecl` in the pod                    |
| Shipping a Swift file for app devs to drag into `Runner/` | Pod ships the file                      |
| Editing `Runner.xcodeproj/project.pbxproj`               | Nothing to edit                         |
| `import dartnative_ios` in the plugin pod               | `dlsym` lookup at runtime               |

---

## 4. Kotlin side — `DNAndroidPluginProvider` (Android)

Same shape as iOS, different mechanism. Android already has a built-in
plugin-registration hook (`FlutterPlugin.onAttachedToEngine`) that the
generated registrant calls automatically — so we use it instead of
`@_cdecl`+`dlsym`. App developers still touch nothing.

Three steps:

**Step 1.** Add the dependency in your plugin's `android/build.gradle.kts`:

```kotlin
dependencies {
    compileOnly("com.dartnative:dartnative_android")
    // …your SDK deps (e.g. ExoPlayer)…
}
```

**Step 2.** Create two Kotlin files in `android/src/main/kotlin/<pkg>/` —
the Bridge and the FlutterPlugin entry point (templates below).

**Step 3.** Declare the plugin class in your `pubspec.yaml`:

```yaml
flutter:
  plugin:
    platforms:
      android:
        package: com.dartnative.myplugin
        pluginClass: DartNativeMyPluginPlugin
      ios:
        ffiPlugin: true
```

> **Critical:** on Android use `package + pluginClass`, **NOT** `ffiPlugin:
> true`. `ffiPlugin: true` skips `FlutterPlugin` registration, so
> `JNI_OnLoad` never fires and your `register()` is never called. See
> [§10](#10-native-library-loading--core-rules) for the full explanation.

### 4a. Copy-paste template — Bridge

```kotlin
// android/src/main/kotlin/<pkg>/DNMyPluginBridge.kt
package com.dartnative.myplugin

import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.dartnative.DNAndroidPluginProvider
import com.dartnative.DNAppContext
import com.dartnative.DNPluginRegistry
import com.dartnative.DNViewRegistry

private const val TAG = "DNMyPlugin"

// EDIT ME ─────────────────────────────────────────────────────────────────
private const val MY_TYPE_KEY = "com.example.myplugin/player" // must match Dart ViewType.claim key
private const val MY_EVENT_DO_FOO: Int = 1                    // must match Dart event tag
// ──────────────────────────────────────────────────────────────────────────

object DNMyPluginBridge : DNAndroidPluginProvider {

    /** Same key as the Dart side → same index, assigned by the framework
     *  at runtime (collision-free — see §1). */
    private val myTypeIndex: Int by lazy { DNPluginRegistry.claimViewType(MY_TYPE_KEY) }

    /** Called by DartNativeMyPluginPlugin.onAttachedToEngine. */
    fun register() {
        DNPluginRegistry.register(this)
        Log.i(TAG, "MyPlugin provider registered")
    }

    override fun createView(typeIndex: Int): View? {
        if (typeIndex != myTypeIndex) return null
        val ctx = DNAppContext.get() ?: return null
        return FrameLayout(ctx).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
            // Add your SDK view as a child here, or in handleMutation.
        }
    }

    override fun handleMutation(viewId: Long, eventTag: Int, data: ByteArray) {
        val container = DNViewRegistry.view(viewId) as? FrameLayout ?: return
        when (eventTag) {
            MY_EVENT_DO_FOO -> {
                // decode `data` (little-endian) and apply to `container`
            }
            else -> Log.w(TAG, "unknown eventTag=$eventTag")
        }
    }
}
```

> **⚠️ Hosting a real SDK view (webview, map, video)?** Two non-obvious gotchas
> make a native view *load but render BLACK* on Android (while iOS looks fine):
> (1) it collapses to **width 0** in a `Column` (default
> `crossAxisAlignment: center`) unless the element emits
> `SetAlignSelf(viewId, 1)` in `mount()`; (2) a hardware-accelerated view
> (`WebView` / ExoPlayer `TextureView`) must be **returned directly from
> `createView` and parented once** — re-parenting it later (e.g. via
> `mainHandler.post`) renders it black.
>
> One more, easy to miss: **never store anything in `View.tag`** on a view the
> framework manages, your own included. The framework keeps its per-view
> state there, and whichever side writes last wins: a thumbnail provider
> that parked the asset id in the tag saw its bitmaps dropped once the
> framework re-set the tag. Keep plugin state on your own `View` subclass
> or in a map keyed by view id.

### 4b. Copy-paste template — FlutterPlugin entry point

```kotlin
// android/src/main/kotlin/<pkg>/DartNativeMyPluginPlugin.kt
package com.dartnative.myplugin

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Flutter plugin entry point — auto-registered by the generated registrant.
 * Its sole job is to fire DNMyPluginBridge.register() once per engine attach.
 */
class DartNativeMyPluginPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        DNMyPluginBridge.register()
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op (or unregister if your provider supports it).
    }
}
```

### 4c. Wire it into Dart `loadSymbols()`

If your plugin has additional JNI symbols (not just view registration), open
the `.so` from Dart:

```dart
static void loadSymbols() {
  if (_loaded) return;
  if (!Platform.isIOS && !Platform.isAndroid) return;   // platform guard
  _loaded = true;

  final lib = Platform.isAndroid
      ? DynamicLibrary.open('libdartnative_my_plugin.so')
      : DynamicLibrary.process();
  // … lib.lookupFunction(...) calls …
}
```

**If your plugin only provides a view (no extra FFI symbols), you don't even
need to call anything in `loadSymbols()` on Android** — `FlutterPlugin`
auto-registration handles everything. Keep the empty-but-guarded
`loadSymbols()` so the generated `DartNativePluginRegistrant` call is a no-op.

### 4d. Why `FlutterPlugin` instead of `@_cdecl`

Android has a first-class plugin-lifecycle hook (`FlutterPlugin`) that fires
when the engine attaches. The generated registrant instantiates every
plugin's `FlutterPlugin` class automatically — that's the Android equivalent
of iOS's "plugin pod links into the app". No `dlsym` gymnastics needed because
we can `import com.dartnative.*` directly from a `compileOnly` dependency.

### 4e. Never do this

| ❌                                                            | ✅                                                          |
|:--------------------------------------------------------------|:-----------------------------------------------------------|
| `DNPluginRegistry.register(…)` from `MainActivity` / `Application` | From `FlutterPlugin.onAttachedToEngine`              |
| `ffiPlugin: true` for plugins that have JNI / FlutterPlugin   | `package: …` + `pluginClass: …`                            |
| `implementation("com.dartnative:dartnative_android")`         | `compileOnly("com.dartnative:dartnative_android")` (app provides it) |
| Loading `libdartnative_android.so` via `System.loadLibrary` from the plugin | The framework loads its own `.so`; you only load yours |

---

## 5. Calling Dart from native — callback safety

> **Skip this section** unless your plugin's native code invokes a Dart
> callback. Pure-Dart plugins, and native code that only *returns values* to
> Dart, don't need any of it. This is the one genuinely sharp corner of
> native-interacting plugins — get it right once and everything else is
> straightforward.

### The danger, in plain words

When Dart hands a callback to native code, native does not receive a Dart
function — it receives a **plain C function pointer** that the Dart VM
generates. On a **hot restart** (capital `R` in the terminal) Dart throws the
whole program away and runs `main()` again, *inside the same OS process*.
Every such pointer from the old run is deleted — but your native code was not
restarted: a video player is still playing, a download is still in flight, a
listener is still registered. The moment any of them calls a deleted pointer,
the app dies instantly:

```
error: Callback invoked after it has been deleted.   → SIGABRT
```

This happens on iOS and Android alike, and it is debug-only (release apps
never hot-restart) — but it kills every debugging session, so it is a
must-fix. The framework cannot intercept the call for you; instead it gives
you two small patterns that make the crash impossible.

### Pick your pattern — one question

**Does native call your Dart function *after* your FFI call has returned?**

| Answer | Pattern | Where |
|---|---|---|
| **No** — fired synchronously *during* the call (a gesture, a text `onChanged`) | The **liveness gate** — two lines of Dart | Below |
| **Yes** — events, ticks, progress, async results, anything delivered later | The **dispatcher slot** | Summary below; full recipe with copy-paste Dart / Swift / Kotlin snippets in [plugin_async_callbacks.md](plugin_async_callbacks.md) |

### Synchronous callbacks — the liveness gate (MANDATORY)

For a callback fired **synchronously, in-frame** (gesture, text `onChanged`),
use the core gate instead of the raw API:

```dart
import 'package:dartnative/dartnative.dart' show DnCallbacks;

_dnMyPluginRegisterCallback(DnCallbacks.arm(nc));   // not nc.nativeFunction.address
DnCallbacks.disarmAndClose(nc);                     // not nc.close()
```

Why: a raw address outlives Dart's view of it (queued native work can fire it
AFTER `close()` → "Callback invoked after it has been deleted"), and the VM
recycles trampoline slots (a new callable on a previously-released address is
silently dead without arming). Review rule: `grep nativeFunction.address` in
your plugin must only match `DnCallbacks` call sites.

### Async callbacks (fired later) — the dispatcher slot (REQUIRED)

This covers **everything native delivers after your call returns**: one-shot
results (a network reply, a completion handler) and repeating streams (player
ticks, push events, sensors) alike. The shape, in four steps — no framework
internals needed:

1. **Dart creates ONE callback pointer for your whole plugin** (a single
   top-level dispatcher via `Pointer.fromFunction`) and hands its address to
   native. Every call carries a `token` (an int id) so one pointer serves many
   objects — Dart routes by token to the right handler/`Completer`/stream.
2. **Native stores the address in ONE variable — "the slot"** — and registers
   it with the framework once: iOS hands the slot's location to
   `DNRegisterAsyncDispatcherSlot(&slot)`; Android captures the framework's
   restart counter `DN_IsolateGen()` next to the pointer.
3. **Before every call into Dart, native re-checks**: slot still non-zero
   (iOS) / counter unchanged (Android) — otherwise drop the event. Always call
   on the **main thread**.
4. That's it. On hot restart the framework clears the slot and bumps the
   counter before any old pointer dies, so the check is always truthful, and
   the new session refills the slot when your plugin re-initialises.

Three rules make the guarantee hold — break any one and the crash returns:
**(1)** never copy the raw address into a closure, listener, or per-object
field; **(2)** register with the framework once; **(3)** re-check before every
single fire.

**Do NOT rely on** any of these look-alike fixes:

- a "stable" global `Pointer.fromFunction` on its own — its address is deleted
  with the rest of the program; without step 2 native still calls a dead
  pointer;
- a Dart-side token map — the app aborts on *entering* the dead pointer,
  before your lookup ever runs; the check must be native-side;
- Android's `DNViewRegistry.registerResetHook { … }` as the crash guard — reset
  hooks run when the **new** session starts, which is too late. Use them for
  what they're good at: **resource cleanup** (dispose players, cancel work
  left over from the old session). iOS equivalent: expose a `…DisposeAll()`
  FFI function and call it from your Dart `loadSymbols()`.

Full recipe with complete copy-paste snippets (Dart + Swift + Kotlin/C++),
payload/error conventions, and the alternatives (polling; native ports — the
latter required for worker isolates):
**[plugin_async_callbacks.md](plugin_async_callbacks.md)**.

---

## 6. Wire format — `PluginMutation`

The framework cannot know your plugin's operations — it has no
`AddMarkerMutation` because it doesn't know Google Maps exists.
`PluginMutation` is the **generic escape hatch**. The framework tells the
plugin: _"I'll give you a `viewId`, an integer `eventTag` you define, and a
raw `Uint8List` payload. Encode whatever you want. I will route it through my
mutation batch pipeline to your native provider without needing to understand
a single byte of it."_

Your element writes it with `writePluginMutation(viewId, eventTag, data)`;
your provider receives the same three values in `handleMutation`. The
bytes in between are yours alone.

With it, the framework stays generic and plugins are fully self-contained.

---

## 7. Error handling guidelines

- If `createView(typeIndex:)` receives an unknown type index, return `nil` —
  never crash.
- If `handleMutation` receives an unknown `eventTag`, log and return — never
  crash.
- Validate `data.count` before reading multi-byte values from the payload.
- Clean up native resources (e.g. `AVPlayer`, subscriptions) when the view is
  removed — override `unmount()` on the Dart element, and register hot-restart
  cleanup (see [§5](#5-calling-dart-from-native--callback-safety)).

---

## 8. Pure FFI plugins (no view)

Not all plugins need a `NativeElement`, `ViewType`, or `DNPluginProvider`. If
your plugin wraps system APIs that **return values** or **fire callbacks** (no
view involved), you write only layers 1 and 4 — a Dart API class and `@_cdecl`
Swift functions — and skip the mutation pipeline entirely. The official
`dartnative_system`, `dartnative_permissions`, `dartnative_share`, and
`dartnative_audio` plugins follow this shape.

### Dart side

```yaml
# pubspec.yaml — ALWAYS use pluginClass on Android, even for "pure FFI"
# plugins. See §10 for rationale.
flutter:
  plugin:
    platforms:
      ios:
        ffiPlugin: true
      android:
        package: com.dartnative.system
        pluginClass: DartNativeSystemPlugin
```

```dart
// Singleton bindings class — look up @_cdecl symbols at startup
class SystemFFIBindings {
  static final instance = SystemFFIBindings._();
  SystemFFIBindings._();

  late final Pointer<Utf8> Function() _getVersion;
  // …

  static void loadSymbols() {
    if (!Platform.isIOS) return;
    final lib = DynamicLibrary.process();
    instance._getVersion = lib.lookupFunction<
        Pointer<Utf8> Function(), Pointer<Utf8> Function()>('DNPackageInfoGetVersion');
    // … other symbol lookups
  }
}
```

### Swift side

```swift
// Cached strdup pointers — valid for app lifetime
private var _pkgVersionPtr: UnsafeMutablePointer<CChar> = strdup("")!

@_cdecl("DNPackageInfoGetVersion")
public func DNPackageInfoGetVersion() -> UnsafePointer<CChar> {
    // reads Bundle.main.infoDictionary once, caches result
    loadPackageInfoOnce()
    return UnsafePointer(_pkgVersionPtr)
}
```

### Pattern rules

- No `NativeElement`, `ViewType`, or `PluginMutation` needed.
- `DynamicLibrary.process()` finds `@_cdecl` symbols linked into the app binary.
- For string returns use cached `strdup` pointers (valid for app lifetime) —
  `Pointer<Utf8>.toDartString()` copies the bytes into a Dart `String`.
- For async callbacks use the dispatcher slot
  ([§5](#5-calling-dart-from-native--callback-safety)).
- For logging use `print("[MyPlugin] \(msg)")` — see
  [§12](#12-debugging-plugins).

---

## 9. FFI string lifetime — async listener callbacks

> **TL;DR**: When the Dart side uses `NativeCallable<…>.listener` to receive
> a `Pointer<Utf8>`, the native side **must heap-allocate the bytes with
> `strdup`** and the Dart side **must `calloc.free(ptr)` after copying**.
> Otherwise the buffer dies before Dart reads it and the listener receives
> an empty string. This rule does NOT apply to `isolateLocal`, which is
> synchronous.

### The trap

`NativeCallable<…>.listener` is **asynchronous** — invoking the trampoline
from native code queues a message onto the Dart isolate's event loop. The
Dart handler runs on a *later* iteration, after the native function has
already returned. If the native side handed Dart a `Pointer<Utf8>` whose
buffer was tied to the call stack (Swift `withCString { … }`, JNI
`GetStringUTFChars` + `ReleaseStringUTFChars`, C++ `std::string::c_str()`),
that buffer is freed before the Dart listener wakes up. `ptr.toDartString()`
then reads dangling memory — usually `""`, sometimes garbage, sometimes
the right value if the heap hasn't been touched yet (which is why this
bug is intermittent and easy to ship).

The sibling type — `NativeCallable<…>.isolateLocal` — is **synchronous**:
the Dart handler runs on the same stack frame before the trampoline
returns. `withCString` is safe there. The two call sites are visually
identical, so this rule has to be enforced by convention.

### Swift (iOS)

```swift
// ❌ BROKEN: buffer freed before Dart reads it.
private func _emit(_ cb: @convention(c) (UnsafePointer<CChar>) -> Void,
                   _ json: String) {
    json.withCString { cb($0) }
}

// ✅ FIXED: strdup → Dart owns the buffer.
private func _emit(_ cb: @convention(c) (UnsafePointer<CChar>) -> Void,
                   _ json: String) {
    if let cstr = strdup(json) {
        cb(cstr)
    }
}
```

For callbacks with multiple string args, `strdup` every one.

### C++ / JNI (Android)

```cpp
// ❌ BROKEN: std::string dies when the JNI function returns.
extern "C" JNIEXPORT void JNICALL
Java_..._nativeOnEvent(JNIEnv* env, jobject, jstring jstr) {
    std::string s = jstrToStd(env, jstr);
    g_listenerFn(s.c_str());
}

// ✅ FIXED: strdup, hand ownership to Dart.
extern "C" JNIEXPORT void JNICALL
Java_..._nativeOnEvent(JNIEnv* env, jobject, jstring jstr) {
    const char* c = jstr ? env->GetStringUTFChars(jstr, nullptr) : nullptr;
    char* heap = strdup(c ? c : "");
    if (jstr && c) env->ReleaseStringUTFChars(jstr, c);
    if (heap) g_listenerFn(heap);
}
```

### Dart — `calloc.free` is REQUIRED

The native side allocated; the Dart side now owns the buffer and is the
only party that can free it. Leaking is a permanent per-event waste of heap.

```dart
cb = NativeCallable<_StringCbC>.listener((Pointer<Utf8> ptr) {
  if (ptr == nullptr) return;
  final value = ptr.toDartString();
  calloc.free(ptr);                  // ← mandatory mirror of strdup
  controller.add(value);
});
```

For multi-pointer listeners, free *all* of them.

### Quick decision table

| Dart callback type                       | Native lifetime needed   |
| ---------------------------------------- | ------------------------ |
| `NativeCallable<…>.listener` (async)     | `strdup` (+ Dart frees)  |
| `NativeCallable<…>.isolateLocal` (sync)  | stack-allocated is fine  |

When in doubt, default to `strdup` + `calloc.free`. It's marginally more
expensive than `withCString` but it eliminates a class of intermittent bugs
that are extremely hard to debug from the symptom alone (an empty string in
Dart, no native error, no crash).

---

## 10. Native library loading — CORE RULES

> **Read this section once. It is the single source of truth.** It defines the
> exact contract between plugin authors and app developers on both platforms.
> Following it eliminates `LateInitializationError`, `undefined symbol`, and
> `SIGSEGV in _JavaVM::GetEnv` — the three most common dartnative bugs.

A dartnative plugin has **two layers** of native loading:

| Layer | Purpose | iOS | Android |
|-------|---------|-----|---------|
| **A — JVM/Process load** | Make symbols reachable by the JVM (Android) or stay statically linked into the app binary (iOS) | Static link via `ffiPlugin: true` (no runtime load needed) | `System.loadLibrary("name")` from a Java-side call site — only this fires `JNI_OnLoad` |
| **B — Dart symbol lookup** | Convert C function names into `Pointer<NativeFunction>` for `lookupFunction` | `DynamicLibrary.process()` | `DynamicLibrary.open('libname.so')` |

If either layer is missing on Android, the plugin will crash. If layer B is
missing on iOS, the first FFI call throws `LateInitializationError`.

### Rules for PLUGIN AUTHORS

#### A1. `pubspec.yaml` — declare both platforms correctly

```yaml
flutter:
  plugin:
    platforms:
      ios:
        ffiPlugin: true                      # iOS: always ffiPlugin: true
      android:
        package: com.dartnative.my_plugin     # Android: ALWAYS pluginClass —
        pluginClass: DartNativeMyPluginPlugin # never `ffiPlugin: true`
```

> ⚠️ **Never use `android: ffiPlugin: true` in dartnative plugins.**
> `ffiPlugin: true` on Android only bundles the `.so` — it does **not**
> generate any `System.loadLibrary` call. Without a `pluginClass`, the JVM
> never loads the library, `JNI_OnLoad` never fires, the C++ `g_jvm` stays
> NULL, and the first JNI callback crashes with `SIGSEGV` in `_JavaVM::GetEnv`.
> **Always declare `pluginClass` on Android, even for "pure FFI" plugins** —
> it costs you one ~30-line Kotlin file and gives every consumer a
> zero-config integration.

#### A2. Ship a Kotlin `FlutterPlugin` class that loads your `.so`

```kotlin
// android/src/main/kotlin/com/dartnative/my_plugin/DartNativeMyPluginPlugin.kt
package com.dartnative.my_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Registered automatically via pubspec.yaml `pluginClass`. The toolchain
 * emits an instantiation in the generated registrant; engine attach calls
 * onAttachedToEngine here, which is the only call site that fires
 * JNI_OnLoad for libdartnative_my_plugin.so.
 */
class DartNativeMyPluginPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            System.loadLibrary("dartnative_my_plugin")
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.e("DNMyPlugin",
                "Failed to load libdartnative_my_plugin.so: ${e.message}")
        }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
```

This class must do **only** `System.loadLibrary` — do not register
`MethodChannel`s, do not start services. dartnative plugins communicate
exclusively over FFI.

#### A3. Dart `loadSymbols()` — guard the platform, branch the loader

```dart
static void loadSymbols() {
  if (_loaded) return;
  if (!Platform.isIOS && !Platform.isAndroid) return;   // platform guard
  final lib = Platform.isAndroid
      ? DynamicLibrary.open('libdartnative_my_plugin.so')  // Android: separate .so
      : DynamicLibrary.process();                            // iOS: app binary
  _foo = lib.lookupFunction<_FooC, _FooD>('DNMyPluginFoo');
  _loaded = true;
}
```

Every plugin's `loadSymbols()` **must** start with a `Platform.is…` guard
because `DartNativePluginRegistrant.registerAll()` is called unconditionally
on every platform. If your plugin only supports iOS, guard with
`if (!Platform.isIOS) return;` — and mirror that for Android-only.

#### A4. Native build files

`android/CMakeLists.txt` — use `find_library`, NOT `find_package(JNI)`
(the NDK provides JNI headers automatically; `find_package` looks for a host
JDK and fails during cross-compilation):

```cmake
find_library(log-lib log)
find_library(android-lib android)
target_link_libraries(my_plugin ${log-lib} ${android-lib})
```

`android/build.gradle` — depend on `dartnative_android` for `DNAppContext`
and friends, and include the CMake config:

```groovy
android {
    compileSdkVersion 35
    externalNativeBuild {
        cmake { path "CMakeLists.txt" }
    }
}

dependencies {
    compileOnly project(':dartnative_android')
}
```

If your plugin requires Android system services (e.g. network state), document
the permissions the **app** must declare in its `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### Rules for APP DEVELOPERS (plugin consumers)

If the plugin author followed A1–A4, integration is **zero-config on both
platforms**:

```yaml
# your_app/pubspec.yaml
dependencies:
  dartnative_my_plugin: ^x.y.z
```

```bash
dn pub get   # also regenerates lib/dartnative_plugin_registrant.dart
```

```dart
DartNativePluginRegistrant.registerAll();   // one line in main() — covers ALL plugins
```

Do **not** touch `AppDelegate.swift` or `Application.kt` when adding a plugin
— plugin wiring is fully automatic on both platforms.

### Common errors → which rule fixes them

| Error | Platform | Cause | Fix |
|-------|----------|-------|-----|
| `LateInitializationError: Field '_foo'` | iOS / Android | `loadSymbols()` was never called | App developer: call `DartNativePluginRegistrant.registerAll()` in `main()` |
| `SIGSEGV in _JavaVM::GetEnv` at `JNI_OnLoad` time | Android | `.so` was loaded by `dlopen` (FFI), not by JVM — `JNI_OnLoad` never fired | Plugin author: add `pluginClass` (A1) + `FlutterPlugin` class (A2). NEVER use `android: ffiPlugin: true` |
| `undefined symbol: DNFooBar` from `lookupFunction` | Android | `loadSymbols()` used `DynamicLibrary.process()` instead of `.open('libname.so')` | Plugin author: branch by `Platform.isAndroid` (A3) |
| `Attempted to register plugin … but it was already registered` | Android | The app calls the generated registrant manually after engine construction | App developer: remove the manual call |
| Plugin works locally but `dn pub get` doesn't pick it up | Both | Registrant files stale | App developer: re-run `dn pub get` |

---

## 11. Plugin registration in app `main()`

Every dartnative plugin exposes a `loadSymbols()` method that must be called
before any FFI usage. Apps don't write one line per plugin — a generated file,
`lib/dartnative_plugin_registrant.dart`, consolidates all calls, and `main()`
needs exactly one line:

```dart
import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

### Plugin authors — declare yourself in `pubspec.yaml`

**This is mandatory for every dartnative plugin.** The registrant generator
discovers plugins by reading a `dartnative.registrant` block from each
plugin's own `pubspec.yaml` — there is no central registry, and adding a
plugin requires zero framework edits.

Add this block at the end of your plugin's `pubspec.yaml`:

```yaml
# dartnative plugin registrant — the generator discovers this block and
# emits the corresponding import + loadSymbols() call into the app's
# lib/dartnative_plugin_registrant.dart.
dartnative:
  registrant:
    imports:
      - package:my_plugin/my_plugin.dart
    calls:
      - MyPluginFFIBindings.loadSymbols();
```

Rules:

- **`imports`** — one or more Dart import URIs the generated file must add.
- **`calls`** — one or more statements (one per line, including the trailing
  `;`) that load the plugin's FFI symbols. Multiple calls are supported for
  plugins that expose more than one FFI bindings class.
- **Omit the block** if your package is Dart-only or has no `loadSymbols()`
  entry point — the generator silently skips it.

App developers regenerate the file by running `dn pub get` after adding or
removing a `dartnative_*` dependency.

### Init must be self-contained

`registerAll()` calls each plugin's registrant entries — nothing else. Two
consequences for plugin authors:

- **API keys and setup belong inside your init**, not as a separate call the
  app makes afterwards. Views can be created immediately after
  `registerAll()`; if your SDK needs a key first, take it in your init
  function (or an explicit early `configure()` you document).
- **Never require the app to call your init separately** — double
  initialisation causes ordering bugs and duplicate-registration warnings.

---

## 12. Debugging plugins

Enable framework-level verbose logging to see every mutation the framework
applies, including your `PluginMutation` events with their `eventTag` and
data length:

```dart
import 'package:dartnative/plugin.dart';

void main() {
  dnVerboseLog = true; // framework logs, including plugin mutations
  runApp(MyApp());
}
```

The flag defaults to `false` for production silence.

### Plugin logging

Plugin Swift/ObjC code writes to the Xcode console via `print()` / `NSLog()`.
No Dart registration needed.

```swift
// Swift — one-liner, visible in Xcode console and device log
private func dnLog(_ msg: String) {
    print("[MyPlugin] \(msg)")
}
```

Note that `dn logs` captures Dart VM logs only — native `print()` goes to the
device syslog (`idevicesyslog -u <udid> | grep MyPlugin` shows it live). If
you want plugin logs to appear in the `dn run` terminal alongside Dart output,
opt in by calling `DNAppendLog` — a symbol exported by `dartnative_ios`:

```swift
private typealias _AppendLogFn = @convention(c) (UnsafePointer<CChar>) -> Void
private let _dnAppendLog: _AppendLogFn? = {
    guard let sym = dlsym(RTLD_DEFAULT, "DNAppendLog") else { return nil }
    return unsafeBitCast(sym, to: _AppendLogFn.self)
}()

private func dnLog(_ msg: String) {
    let tagged = "[MyPlugin] \(msg)"
    print(tagged)
    tagged.withCString { _dnAppendLog?($0) }
}
```

This is opt-in. Most plugins only need `print()`.

---

## 13. Packaging and distribution

### Dart package

```yaml
# pubspec.yaml
name: dartnative_video_player
description: Video player plugin for dartnative.
dependencies:
  dartnative: ^1.0.0
```

Export the public API and declare your `loadSymbols()` in the
`dartnative.registrant` block ([§11](#11-plugin-registration-in-app-main)).

### Plugin podspec (iOS)

```ruby
Pod::Spec.new do |s|
  s.name             = 'dartnative_my_plugin'
  s.version          = '0.1.0'
  s.summary          = '...'
  s.license          = { :type => 'MIT' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.swift'
  s.swift_version    = '5.9'

  s.platform         = :ios, '14.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
```

- `s.platform = :ios, '14.0'` — must match the app Podfile's `platform :ios`
  version.
- `DEFINES_MODULE => 'YES'` — required for Swift module visibility.
- Static libs (`.a` files) go in `ios/` root, declared via
  `s.vendored_libraries`; closed-source Swift can ship as a vendored
  XCFramework instead of `source_files`.
- Add your SDK frameworks to `s.frameworks` (e.g. `AVFoundation`).

### Ship an example app

Scaffold it with `dn create` (see
[getting_started.md](getting_started.md)) and add your plugin as a path
dependency — never hand-build the native boilerplate from scratch, and never
use raw `flutter create` output (its `AppDelegate` doesn't set up the
dartnative root view, which yields a white screen). Two debugging tips that
save hours:

- **Android:** debug app-side build failures with `./gradlew assembleDebug`
  directly to see the real error. Common causes: a non-AppCompat launch
  theme, `minSdk` below 26, a missing `INTERNET` permission in the debug
  manifest.
- **iOS:** on `pod install` conflicts, delete `ios/Pods/` +
  `ios/Podfile.lock`, re-run `dn pub get`, then `pod install`. Never add
  manual `pod 'dartnative_…'` lines — pods are auto-discovered; manual
  entries cause "multiple dependencies with different sources".

---

## 14. Views with no intrinsic size inside a Stack

**The normal case:** every widget tells layout how big it wants to be —
`Text` measures its glyphs, `Image` its bitmap, containers take their size
from children or an explicit width/height. A `Stack` relies on that: it
sizes itself to its first non-`Positioned` child and places it according to
`Stack.alignment`.

**The edge case:** some native views have no size of their own — they are
sized purely by an **aspect ratio** ("give me a width and I'll compute my
height"; typical of video players and canvas surfaces). In most layouts
something upstream provides that width — a sized parent, an `Expanded`, your
own widget wrapper. Inside a `Stack` nothing does: no intrinsic size and no
width given means the ratio multiplies zero, and the view measures `0×0`.

**If your view is sized purely by aspect ratio**, declare it on your
element, and the Stack will hand it its full width to work from:

```dart
class VideoPlayerElement extends NativeElement {
  // Sized purely by aspect ratio → ask the Stack for its full width.
  @override
  bool get stretchAsStackFlowChild => true;
}
```

Leave the default (`false`) for any view with a real intrinsic size — the
framework can't infer this for you, because stretching automatically would
change layouts where the view is explicitly sized and `Stack.alignment`
should govern its placement.

---

*For the full system diagram, see [architecture.md](architecture.md).*
