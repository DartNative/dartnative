# Architecture

Every cross-platform framework eventually makes the same trade-off: how much of the native platform do you preserve, and how much do you replace?

Flutter replaces everything below the widget layer. React Native preserves the native views but routes every update through a JavaScript runtime in a separate thread. Both choices leave a gap between your code and the platform — and that gap shows in scrolling, in text input, in keyboard behavior, in animation latency, in the subtle feel of every interaction.

DartNative closes the gap. This document explains how.

---

## The Big Picture

```
┌─────────────────────────────────────────────────────────────────┐
│  Your Dart code  (Column, Text, ListView, setState…)            │
├─────────────────────────────────────────────────────────────────┤
│  DartNative  ·  diffs the widget tree and applies the changes   │
│                 to the platform, once per frame                 │
├─────────────────────────────────────────────────────────────────┤
│  UIKit (iOS)  ·  UIView, UILabel, UIScrollView, UITextField…    │
│  Android Views  ·  TextView, ScrollView, RecyclerView…          │
├─────────────────────────────────────────────────────────────────┤
│  Yoga  ·  CSS Flexbox layout engine                             │
├─────────────────────────────────────────────────────────────────┤
│  GPU composite to screen                                        │
└─────────────────────────────────────────────────────────────────┘
         ▲ everything runs on the platform main thread
```

Every layer runs on the same thread. There are no queues, no bridges, no thread hops. A `setState()` call on a button tap diffs the tree, updates the native views, lays them out and commits the frame in one synchronous call stack, before the next vsync.

Take a messaging app, one of the most demanding UI patterns in mobile: a live list of messages, a text input pinned to the keyboard, new items animating in as the user types. When the user taps Send, the tap callback runs in the same run-loop turn, the new message diffs into a handful of view changes, those changes reach the platform in one call, layout runs, and the frame commits. Dart's part of that is a diff and one call.

---

## Real Views, One Tree

Every widget that paints or lays out is a real platform view: a `Text` is a `UILabel` or a `TextView`, a `ListView` a real scroll view, a `TextField` the platform's own text input. DartNative keeps one Dart tree and one native tree, and applies the difference between two builds directly to the native views. React Native's New Architecture keeps a third tree in between: the C++ shadow tree that Fabric lays out on the JavaScript thread and then mounts onto host views on the UI thread. DartNative has no shadow tree and no mount step. The Dart tree drives the native views, and Yoga lays those views out in the same call. A frame that inserts a chat message touches dozens of views; they all reach the platform in one call.

---

## Layout — Yoga

All layout in DartNative is computed by **Yoga** (Meta), the same CSS Flexbox engine used by React Native.

Flutter's layout widgets map onto flexbox: `Column` and `Row` are flex directions, `Expanded` is grow and shrink, `Padding` is padding, `Align` and `Center` are nodes that place their child, and `MainAxisAlignment` is `justifyContent`. Flutter's sizing rules are enforced on top, so layouts land where Flutter puts them.

### Why Yoga beats Auto Layout at scale

Auto Layout is a constraint-satisfaction system. More views mean more constraint equations, and the solver's time complexity grows as **O(n²)** in the worst case. A deeply-nested layout with many constraints can be slow to compute.

Yoga is a tree traversal. Its cost is linear in the number of nodes for typical trees, regardless of nesting depth. A chat screen with 40 visible message bubbles, each containing text, avatars, and padding, computes all frames before the solver in a constraint system would finish evaluating the first group.

| | Auto Layout | Yoga |
|---|---|---|
| Algorithm | Cassowary constraint solver | Tree walk |
| Complexity | O(n²) worst case | Linear for typical trees |
| Invalidation | Constraint graph propagation | Dirty-flag per subtree |
| Used by | UIKit Storyboard / Xcode Interface Builder | React Native, DartNative |

---

## Scrollable widgets

DartNative provides Flutter-compatible scroll widgets plus a native **Fast family** for large lists and grids:

| Widget | Backed by | Best for |
|--------|-----------|----------|
| `ListView` / `ListView.builder` | `UIScrollView` + Yoga (all cells live) | Short, static lists (< ~50 items) |
| `FastList` | `UITableView` / `RecyclerView` recycling | Long or image-heavy lists |
| `FastGrid` | `UICollectionView` / `RecyclerView` + `GridLayoutManager` | Long uniform grids |
| `MasonryFastGrid` | staggered collection / layout manager | Pinterest-style variable-height grids |

### FastList — real recycling

`FastList` is a real `UITableView` / `RecyclerView`: cells recycle as they scroll off-screen, scrolling stays smooth at any length, and index jumps are exact. The item builder runs for every item on mount, so paginate via `onScroll` when N is huge. By default every built cell is held for the widget's lifetime; set **`keepAliveCount`** and only a sliding window around the viewport holds content, independent of `itemCount`. Pair it with `Image.cacheWidth`/`cacheHeight` (decode at cell size) for image lists.

**Programmatic scrolling:**

```dart
final controller = FastListController();
FastList(
  controller: controller,
  itemCount: messages.length,
  itemBuilder: (context, index) => MessageBubble(messages[index]),
)

// Smooth scroll to item N (animated)
controller.scrollToItem(messages.length - 1);

// Jump instantly (no animation)
controller.jumpToItem(0);
```

`scrollToItem` is a single native call; no Dart runs per scroll frame.

### FastGrid & MasonryFastGrid

The same model in two dimensions: `FastGrid` for uniform grids, `MasonryFastGrid` for variable-height, Pinterest-style ones. Both are real recycling collection views with the same memory model and the same `keepAliveCount`, driven by a `FastGridController`.

---

## Scroll Events — Native → Dart

`ScrollController` receives every scroll position update from the native scroll view synchronously, in the same call the platform makes on the main thread, and notifies its listeners right there. There is no polling, no timer, no latency.

```dart
final controller = ScrollController();

void _onScroll() {
  if (controller.remainingScroll < 200 && !_loading) {
    _loading = true;
    // fetch more items…
  }
}

ListView.builder(
  controller: controller,
  itemCount: items.length,
  itemBuilder: (_, i) => ItemWidget(items[i]),
)
```

---

## Navigation — Real Platform Navigation

DartNative's `Navigator` API is a drop-in replacement for Flutter's Navigator, backed by `UINavigationController` on iOS and a native view stack on Android. Push, pop, and transition are real platform navigation events — system slide animations, interactive back swipe, system back gesture, and native navigation bars are all 100% native.

### Why Flutter navigation looks wrong

Flutter draws its navigation transitions using Impeller. `CupertinoPageRoute` and `PageRoute` are Dart re-implementations of GPU-compositor animations. The differences are visible on both platforms:

| Aspect | Flutter | DartNative |
|--------|---------|-------------|
| Animation driver | Dart `AnimationController` → Impeller | Core Animation render server (GPU) |
| Timing curve | Approximated cubic bezier | Exact `UINavigationController` spring |
| Interactive back gesture (iOS) | Dart pan recognizer + manual animation | `UIScreenEdgePanGestureRecognizer` (system) |
| Navigation bar | Custom-drawn `CupertinoNavigationBar` | Real `UINavigationBar` + `UIBarButtonItem` |
| 120 Hz ProMotion | Vsync-bound, can drop frames | GPU compositor driven, no per-frame CPU cost |
| Status bar style | Manual override per route | Automatic per-VC `preferredStatusBarStyle` |

### Push / pop

```dart
Navigator.push(
  context,
  PageRoute(builder: (_) => const SettingsScreen()),
);

Navigator.pop(context);
Navigator.pushReplacement(context, PageRoute(builder: (_) => const HomeScreen()));
Navigator.popUntil(context, (route) => route.isFirst);
```

Each pushed screen is its own root: `setState()` on Screen B never touches Screen A.

### Pop — the platform's own animation

`Navigator.pop()` plays the platform's own slide-out animation. The outgoing screen stays intact for the whole animation, so there is no white flash.

### Hot restart — navigation stack preserved

Flutter preserves the navigation stack across hot reload but not hot restart. DartNative preserves it across **hot restart** too: register your routes by name, and after a restart the stack is rebuilt from the route map before the first frame.

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  registerRoutes({
    '/settings': (_) => const SettingsScreen(),
    '/chat': (_) => const ChatScreen(),
  });
  runApp(const HomeScreen());
}
```

### Navigation comparison

| Capability | Flutter | React Native | DartNative |
|---|---|---|---|
| Animation is GPU-compositor-driven | ❌ | ✅ (native screens) | ✅ |
| Exact platform animation curve | ❌ | ✅ | ✅ |
| Interactive back gesture | Dart gesture handler | Native | Native |
| Navigation bar is real platform control | ❌ | ✅ (native-stack, react-native-navigation) | ✅ |
| High refresh-rate stutter-free (120 Hz) | ❌ | ✅ | ✅ |
| Drop-in Flutter Navigator API | ✅ | ❌ | ✅ |
| Each screen is its own root | N/A | N/A | ✅ |
| Hot restart preserves navigation stack | ❌ | ❌ | ✅ |

---

## Keyboard Animation — Identical to UIKit

DartNative matches the native UIKit keyboard animation with zero per-frame CPU overhead and the exact system curve — not an approximation.

### Why Flutter stutters

Flutter renders its entire UI into a single native `UIView`. When the keyboard appears, iOS reports a new `viewInsets` to Flutter on every frame of the keyboard animation. Flutter's response on each frame:

1. Read the new `viewInsets`.
2. Re-run layout for everything that depends on the insets.
3. Re-rasterize the affected regions.
4. Composite and display.

Because `viewInsets` arrives mid-frame and Flutter acts on it at the next vsync, the content trails the keyboard. On complex screens the layout cost stacks on top of this, against the 8 ms budget at 120 Hz.

### Why React Native stutters

Stock React Native reacts to keyboard events on the JavaScript thread and lays out from there through Yoga before the UI thread can move anything. On 120 Hz displays the content trails the keyboard.

[`react-native-keyboard-controller`](https://github.com/kirillzyusko/react-native-keyboard-controller) + Reanimated worklets is a significant improvement: it eliminates the JavaScript thread roundtrip by running transform computation directly on the UI thread via Reanimated shared values. For most apps this produces noticeably smoother animation and is the right solution for an RN team today.

Two gaps remain relative to DartNative:

1. **Imperative per-frame vs. declarative GPU.** Worklets are still CPU-driven per frame: each frame the worklet reads the current keyboard position and sets view transforms. DartNative hands the whole move to the GPU compositor as one declarative animation, riding with the keyboard's own slide — zero CPU per frame, zero phase lag. On 120 Hz ProMotion under load, the worklet approach can produce a 1-frame phase lag and subtle curve approximation drift (worklets sample position values rather than using the exact curve the keyboard uses).

2. **One animation vs. many.** DartNative's bar and body are driven by the keyboard's own system animation, in one transaction, in perfect lockstep. In React Native, the text input, scroll view, and toolbar are separate `UIView` instances each needing their own animated property driven by the worklet, so their changes can land in slightly different sub-frame windows on complex screens at high refresh rates.

### How DartNative solves it

Dart runs on the main thread, so keyboard notifications arrive in the right execution context to begin with — no thread hop, no waiting for the next vsync.

Chat-style screens have their input bar and body move with the keyboard's own system animation, the way Apple Messages' input bar does. The bar isn't merely synchronized with the keyboard; it is animated *by the same system animation*, which also carries it correctly through interactive dismiss and rotation. And when the focused field lives in the body — a form rather than a chat — the content lifts exactly as much as the field is actually obscured and no more, riding the same GPU animation: zero CPU per frame, zero phase lag, the exact system curve.

| Capability | Flutter | React Native (stock) | RN + keyboard-controller | DartNative |
|---|---|---|---|---|
| Animation curve matches system keyboard | ❌ | ❌ | ≈ sampled | ✅ exact |
| Zero per-frame CPU cost | ❌ | ❌ | ❌ | ✅ |
| No thread hop for keyboard events | ❌ | ❌ | ✅ (native listener) | ✅ |
| 120 Hz ProMotion stutter-free | ❌ | ❌ | ≈ | ✅ |

---

## Image Loading — Zero Dart CPU

`Image.network()` sends the URL to native once via FFI. Everything else — download, decode, caching, display — happens entirely on the native side.

### How Flutter does it

Flutter fetches with Dart's own `HttpClient`, which does not use the OS cache, decodes inside its engine, and uploads a texture for its renderer to draw. It has no built-in disk cache: community packages like `cached_network_image` are required.

### How DartNative does it

`Image.network()` hands the URL and the target size to the platform once. Download, caching, sized decode and display all happen natively. Four properties make this fast:

1. **Zero Dart-side download or decode.** The system HTTP stack and its disk and memory cache fetch the bytes; the platform's hardware-accelerated decoder turns them into pixels.
2. **Decode at display size.** `cacheWidth`/`cacheHeight` decode the image AT the target pixel size (a 280 px thumb costs ~0.3 MB instead of a full-res ~2.5 MB) — the single biggest memory lever for image lists.
3. **Image bytes never touch Dart.** Only the URL crosses the language boundary.
4. **Bounded decode.** A burst of images can never saturate the cores and starve the main thread mid-animation.

### Image cache

The platform HTTP cache (`URLCache`) is active by default. DartNative extends it with an explicit API:

```dart
// Configure at startup
ImageCache.configure(
  maxMemoryBytes: 150 * 1024 * 1024,  // 150 MB NSCache
  maxDiskBytes:   500 * 1024 * 1024,  // 500 MB URLCache
);

// Per-image cache policy
Image.network(url, cachePolicy: ImageCachePolicy.memoryOnly);

// Pre-warm before the screen opens
await precacheImage(NetworkImage(heroUrl));

// Evict / clear
ImageCache.evict(NetworkImage(url));
ImageCache.clearAll();
```

| Capability | Flutter | DartNative |
|---|---|---|
| Disk cache | ❌ (needs package) | ✅ URLCache built-in |
| Per-image cache policy | ❌ | ✅ `standard` / `memoryOnly` / `none` |
| `precacheImage()` | ✅ (engine decode) | ✅ (native decode, zero Dart CPU) |
| Image bytes cross the language boundary | ✅ (always) | ❌ (never) |

---

## Where DartNative Differs From React Native

Both DartNative and React Native (New Architecture) use Yoga for layout. The difference is everything around it — and the clearest place to see it is *where Yoga runs*. Per React Native's own threading model, layout executes on the JavaScript thread and only mounting happens on the UI thread; in DartNative, layout and mounting are the same call stack on the main thread.

```
React Native (New Arch — JSI + Fabric)           DartNative
──────────────────────────────────────           ───────────

┌───────────────┐                        ┌─────────────────────┐
│ JS / BG THREAD│                        │     MAIN THREAD     │
│               │                        │                     │
│  Hermes       │                        │   Dart (AOT)        │
│  React diff   │                        │     ↓               │
│  Shadow tree  │                        │   Reconciler        │
│  Yoga layout  │                        │     ↓               │
│  commit      ─┼──── thread hop ─────►  │   view changes      │
└───────────────┘                        │     ↓               │
                                         │   FFI calls         │
┌───────────────┐                        │     ↓               │
│  MAIN THREAD  │                        │   UIKit             │
│  Fabric mount │                        │     ↓               │
│  UIKit        │                        │   Yoga layout       │
│  GPU frame    │                        │     ↓               │
└───────────────┘                        │   commit            │
                                         │     ↓               │
                                         │   GPU frame         │
Thread hops:  1+ per frame               └─────────────────────┘
JS overhead:  bytecode interpreter + GC
                                         Thread hops:  0
                                         Layout engine: Yoga (same!)
                                         Dart overhead: no interpreter, no JIT
```

| Dimension | React Native | DartNative |
|---|---|---|
| Language runtime | Hermes — JavaScript compiled to bytecode ahead of time, then interpreted (no JIT) | Dart AOT — compiled to native machine code |
| Thread model | JS thread → main thread | Main thread only |
| FFI mechanism | JSI (direct C++ references, still cross-thread) | Dart FFI (direct C call, same thread) |
| Mutation batching | Fabric commit pipeline | One batch per frame |
| Layout engine | Yoga | Yoga — the same one |

The runtime row is the one worth reading twice: **both** runtimes compile ahead
of time, so "AOT vs JIT" is not the difference. Hermes deliberately has no JIT —
it ships bytecode and interprets it, which is why it starts fast. The difference
is what each one executes: interpreted bytecode versus native machine code.

Deliberately absent from that table: gesture-latency and cold-start rows. We
don't publish comparison numbers we haven't measured ourselves with a stated
device and method.

### Why this is faster — and where it isn't

The New Architecture removed React Native's worst bottleneck, the serialized
async bridge. Four structural differences remain — each checkable by reading
either project, no benchmark required:

1. **Native machine code, not interpreted bytecode.** Hermes has no JIT by
   design: it ships bytecode and interprets it. Dart AOT compiles the same work
   to native instructions — a per-operation cost paid on every frame.
2. **No thread boundary.** Per React Native's
   [threading model](https://reactnative.dev/architecture/threading-model), the
   UI thread is "the only thread that can manipulate host views," while render
   *and layout* run on the JavaScript thread, and the next tree "mounts on the
   next tick of the UI Thread." A React state update is scheduled onto the UI
   thread; a DartNative one is already there. (Their C++ State path can run on
   any thread, but that serves component internals, not app logic.)
3. **Synchronous input.** A tap calls straight into Dart on the main thread in
   the same run-loop turn — touch, state change and view update in one frame.
4. **Scrolling never enters the language runtime.** `FastList` is a real
   `UITableView` / `RecyclerView`; React Native's list virtualization is
   JavaScript-driven, so a fast fling can outrun it.

**Where we're even:** real native views, the same Yoga engine (no
layout-algorithm advantage for anyone), batched mounts, native image loading,
and Hermes's no-JIT startup — all good design. Reanimated worklets close much
of the animation gap too.

The claim is not that React Native is slow. It's that its design requires a
boundary between the language your app is written in and the thread your UI
lives on. DartNative removes that boundary rather than optimizing around it.

---

## Debug Tools

### Unified log stream

In React Native, JavaScript logs live in Metro and native logs in Xcode or logcat. In DartNative the native side logs into the same stream as Dart's `print()`: the `dn run` terminal you already have open.

```
dartnative: [Dart]  home screen mounted
flutter: [Swift] created UILabel
dartnative: [Dart]  3 changes queued
flutter: [Swift] keyboard tracking attached
```

Enable verbose logging in Dart:

```dart
dnVerboseLog = true;   // before runApp()
```

| Capability | Flutter | React Native | DartNative |
|---|---|---|---|
| Dart logs in IDE terminal | ✅ | ✅ | ✅ |
| Swift/Kotlin logs in IDE terminal | device log lines | ❌ Xcode / logcat | ✅ |
| Unified Dart + native stream | ❌ | ❌ | ✅ |
| Thread overhead for log forwarding | — | — | zero |

### Other debug tools

| Tool | How to enable |
|------|--------------|
| Verbose Dart logs | `dnVerboseLog = true` before `runApp()` |
| Hot restart | `R` (capital) in `dn run` — restarts Dart and replays navigation. Lowercase `r` is hot reload |

### Persisting logs to a file — `DartNativeLogger`

The `dn run` pipe only captures output when you launch through the `dn` CLI. For on-device captures (Xcode launch, tap-to-open, CI, customer field reports), wrap `runApp` in the framework-level logger:

```dart
import 'package:dartnative/dartnative.dart';

void main() {
  DartNativeLogger.run(
    () {
      DartNativePluginRegistrant.registerAll();
      runApp(const MyApp());
    },
    verbose: true,     // flips dnVerboseLog
    saveToFile: true,  // tees every print() to a log file on disk
  );
}
```

Every line, Dart and native alike, is timestamped and appended to a size-capped log file in the app's container; the path is announced on stdout at startup.

**See also**: [`logging.md`](logging.md) — setup, API reference, and troubleshooting for the log bridge and `DartNativeLogger`.

---

## Custom Painting

`CustomPaint` is native in the core package: Core Graphics on iOS, `android.graphics.Canvas` on Android. For GPU work — shaders, particle systems — the `dartnative_skia` package adds `CanvasSurface`, driven by the same `CustomPainter` API:

```dart
class MyPainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;
    canvas.drawCircle(size.center(Offset.zero), 50, paint);
  }
  bool shouldRepaint(MyPainter old) => false;
}

CanvasSurface(painter: MyPainter())
```

The `Canvas` interface is defined in the core `dartnative` package (no Skia dependency). The `dartnative_skia` package renders it with Skia on a GPU surface, repainting at the display's refresh rate while animating.

---

## Plugin Architecture

Third-party plugins extend DartNative at four independent layers without modifying framework source: an element factory for the plugin's widget, a namespaced view type key, plugin mutations that ride the same batch as everything else, and a native provider that the framework discovers when the plugin loads. See [plugin_development.md](plugin_development.md) for the full plugin author guide with a complete video player example.

### Pure FFI plugins (no view)

A second, simpler plugin pattern exists for system-level APIs with no `UIView`. These plugins write only `@_cdecl` Swift functions and `DynamicLibrary.process().lookupFunction` calls in Dart — no `NativeElement`, `PluginMutation`, or `DNPluginProvider` needed.

| Plugin | Replaces | Native API |
|--------|----------|------------|
| `dartnative_system` | `package_info_plus`, `app_badge_plus` | `Bundle.main.infoDictionary`, `UNUserNotificationCenter` |
| `dartnative_permissions` | `permission_handler` | `AVCaptureDevice`, `PHPhotoLibrary`, `CLLocationManager`, `UNUserNotificationCenter` |
| `dartnative_share` | `share_plus` | `UIActivityViewController` |
| `dartnative_audio` | `just_audio`, `record`, `flutter_sound` | `AVAudioEngine`, `AVAudioSession` |

---

## Credits

DartNative is built on the work of several open-source projects and teams:

- **[flutter_zero](https://github.com/knopp/flutter_zero)** by Matej Knopp — the project that established running Dart on the platform main thread with the rendering stack removed, and the starting point our Zero engine was forked from.
- **[Dart team at Google](https://dart.dev)** — the AOT compiler, `dart:ffi`, and the `flutter` toolchain that the `dn` CLI wraps.
- **[Yoga](https://www.yogalayout.dev)** (Meta) — the CSS Flexbox layout engine used for all layout computation.
- **[FlexLayout](https://github.com/layoutBox/FlexLayout)** — the UIKit/Yoga integration layer on iOS.
- **[Flutter](https://flutter.dev) and [React Native](https://reactnative.dev) teams** — years of pushing cross-platform mobile development forward, and an API design (Flutter's widget model) that proved worth being compatible with.
