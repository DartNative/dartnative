# Skia (dartnative_skia)

**Skia** is the industry-standard 2D graphics engine — the same one that renders
Chrome and Android. `dartnative_skia` compiles **Skia Graphite**
(Skia's modern GPU backend — Metal on iOS, Vulkan on Android) into your app and
exposes it as a `CanvasSurface` widget you draw into from Dart.

Skia is powerful but **not free**: every frame is GPU work outside the
platform's own view compositing, so it adds binary size and costs more per
frame than a native view. Use it only when you genuinely need a
canvas.

---

## When NOT to use it

For most drawing you don't need Skia at all: `dartnative` ships a native
**`CustomPaint`** (backed by Core Graphics on iOS and `android.graphics.Canvas`
on Android) plus native backends for blur, animation, and gradients — all
rendered by the platform at **zero binary cost**. If your screen matches one of
these, skip `dartnative_skia`:

| Use case | Use instead |
|----------|-------------|
| Standard UI — buttons, lists, text, navigation | [widgets](widgets.md) |
| Shapes, paths, lines, clipping in a region | `CustomPaint` (native) |
| Blurred backdrop (panel over busy content) | `BackdropFilter` |
| Blurring the widget's own content (frosted text/icon) | `ImageFiltered` |
| Implicit + explicit animations | `Animated*` / transition widgets |
| Gradient backgrounds, image display, pinch-zoom | `BoxDecoration`, `Image`, `Transform` |

---

## When to use it

Reach for the canvas only when there's no native equivalent:

| Use case | Tier |
|----------|------|
| SkSL / GLSL-style GPU shaders, generative art | bare |
| Particle systems / high-density real-time 2D (100s–1000s of moving elements) | bare |
| Exotic blend modes or mesh rendering (`drawVertices`) | bare |
| Pixel-identical output across iOS & Android | bare |
| Shaped text you must draw *inside* a Skia canvas — HarfBuzz, BiDi, Arabic/CJK | full |

> **Charts and text are usually native, not Skia.** Simple charts, graphs, and
> diagrams draw fine with the native `CustomPaint` (paths, lines, fills, text) —
> reach for Skia only if a chart needs custom GPU shaders or thousands of
> animated points. And **text is best rendered with `Text` widgets or
> `CustomPaint`** (they already handle BiDi, Arabic, CJK); the Skia `full` tier
> exists only for shaped text you need *inside* a Skia canvas — e.g. a label
> baked into a shader effect.

---

## Tiers

`dartnative_skia` comes in two tiers; the package you install today carries
**full**. Choose the smallest tier that covers your use case. You can always
upgrade later.

| Tier | iOS, added to the app | Android (`libdartnative_android.so` arm64-v8a) | What you get |
|------|----------------------|-------------------------------------------------|--------------|
| **bare**   | ~4 MB   | 4.2 MB  | **Canvas** + SkSL runtime shaders + Graphite (Metal/Vulkan); basic Latin text |
| **full**   | 9.1 MB  | 17.6 MB | Everything in **bare** + **rich shaped text** (HarfBuzz, SkParagraph, BiDi, Arabic/CJK/RTL, full ICU) |

**Not sure which to pick?** Take **bare**. It covers canvas drawing, shaders
and Latin text at less than half the size. Move to **full** only when text
you draw *inside* a Skia canvas needs shaping, which shows as boxes instead
of glyphs.

Two different things get called the default, so both in plain words:
**full** is what an app gets when the key says nothing, and **bare** is the
recommendation. The tier is one key in your pubspec:

```yaml
# pubspec.yaml, top level, beside dependencies
dartnative_skia:
  variant: bare    # or full; not yet honoured, see "What you get today"
```

**What you get today:** the published package carries the **full** tier and
the `variant` key does not yet switch between them, so an iPhone app gets
the 9.1 MB framework either way. Tier selection is coming; until it lands,
budget for **full**. The iOS figure is the embedded framework in a release
build for a device, measured; the bare estimate is from the source tree's
own tier and is not yet shipped.

**Android carries Skia either way.** On Android the library is compiled into
the platform binding, so an app pays for it whether or not it depends on
`dartnative_skia`; the shipped binding carries the **full** tier, so the
Android column above is what each tier would cost, not a choice you make
today. Adding the dependency there buys you the `CanvasSurface`
widget, not extra bytes. Skipping it saves app size on iOS only.

---

## Setup

A new app does not depend on Skia. Adding it is two steps, and both are
needed: the dependency alone gives you the package, the call is what makes
`CanvasSurface` build. Skia adds about 9 MB to an iPhone app, so add it when
you want a canvas, not before.

### 1. Add the dependency

```yaml
# pubspec.yaml
dependencies:
  dartnative: ^1.0.0
  dartnative_ios: ^1.0.0
  dartnative_android: ^1.0.0
  dartnative_skia: ^1.0.0
```

### 2. Register the canvas widget in `main`

`registerSkiaFactories()` teaches the framework how to build a
`CanvasSurface`. Without it a `CanvasSurface` in your tree throws. Call it
once, right after the plugin registrant and before `runApp`:

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  registerSkiaFactories();
  runApp(const MyApp());
}
```

Then run `dn pub get`. Nothing else: no Podfile and no Gradle changes.

**Removing it again** is the same two steps backwards, plus one: drop the
dependency, drop the import and the `registerSkiaFactories()` call, then run
`dn pub get`, which rewrites `dartnative_plugin_registrant.dart` for you.
That file is generated, so never edit it by hand.

---

## Basic usage

```dart
import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CanvasSurface(
          width: 300,
          height: 300,
          painter: _RainbowPainter(),
        ),
      ),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  double _time = 0;

  @override
  void paint(Canvas canvas, Size size) {
    _time += 0.016;
    final paint = Paint();

    // Draw a gradient circle that pulses
    for (int i = 0; i < 8; i++) {
      final t = i / 8.0;
      paint.color = Color.fromARGB(255, (255 * (1 - t)).round(), 90, (255 * t).round());
      final r = size.width * 0.4 * (1 - t * 0.5);
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        r * (0.8 + 0.2 * math.sin(_time + t * 3.14)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainbowPainter old) => true;
}
```

---

## SkSL Shaders

SkSL (Skia Shading Language) compiles at runtime to Metal (iOS) or
Vulkan/SPIR-V (Android). Write one shader, run on both platforms.

```dart
const String _blobSksl = r'''
uniform float2 u_resolution;
uniform float  u_time;

half4 main(float2 fragCoord) {
  float2 uv = fragCoord / u_resolution;
  float  d  = length(uv - 0.5);
  float  w  = sin(d * 20.0 - u_time * 3.0) * 0.5 + 0.5;
  return half4(w * 0.2, w * 0.5, w, 1.0);
}
''';

class _ShaderPainter extends CustomPainter {
  final RuntimeEffect _effect = RuntimeEffect.make(_blobSksl)!;
  double _time = 0;

  @override
  void paint(Canvas canvas, Size size) {
    _time += 0.016;
    final shader = _effect.makeShader(
      [size.width, size.height, _time],
    );
    canvas.drawPaint(Paint()..shader = shader);
    shader.dispose();
  }

  @override
  bool shouldRepaint(_ShaderPainter old) => true;
}
```

> **Tip**: `RuntimeEffect.make()` compiles the shader on first call. Cache
> the `RuntimeEffect` as a field; only call `makeShader()` per frame.

---

## Rich text rendering (full tier)

> Only needed for text drawn *inside* a Skia canvas. For normal on-screen text,
> use `Text` widgets or the native `CustomPaint` — they already handle BiDi,
> Arabic, and CJK. Don't pull in the Skia full tier just for labels.

For shaped text with HarfBuzz — Arabic, CJK, RTL layouts — drawn onto a
`CanvasSurface`:

```dart
// Rich shaped text, the full tier
final paragraph = ParagraphBuilder(
  ParagraphStyle(
    textDirection: TextDirection.rtl,
    fontSize: 24,
    fontFamily: 'Noto Sans Arabic',
  ),
)
  ..addText('مرحبًا بالعالم')
  ..build()
  ..layout(ParagraphConstraints(width: 300));

canvas.drawParagraph(paragraph, Offset(0, 50));
```

For simple Latin text, `SkFont` is always available in every tier and needs
no extra setup.

---

## Frame pump

`CanvasSurface` repaints on the display's own rhythm — every vsync, at up to
120 Hz on ProMotion iPhones and iPads. For content that doesn't animate, use
`CanvasSurface.static` (or `animating: false`): it renders once and repaints
only when the widget updates or the device rotates, costing no GPU or battery
in between — and when every surface on screen is static, the frame driver
stops completely. To stop an animating surface that's merely hidden, wrap it
in `Visibility`.

GPU work runs off the main thread, so even a heavy per-pixel shader won't
block scrolling, touch, or layout.

### When a canvas stops updating

A canvas that stops painting is silent: the widget is still there, nothing
throws, and nothing appears in the log. `CanvasDiagnostics.now()` says what
the frame loop is doing and why each surface dropped its last frame.

```dart
print(CanvasDiagnostics.now());
```

```text
CanvasDiagnostics(driver: vsync, surfaces: 1, ticks: 4217 (16ms ago),
                  frames: 4213 (16ms ago), skipped: none)
```

Read it in this order:

- **`driver: none, stopped`** with every surface static and already painted
  is normal. The loop shuts down when nothing needs a frame and starts again
  by itself when something does.
- **`app backgrounded`** means the loop is stopped on purpose. It resumes
  when the app returns.
- **Ticks climbing but frames not** means the loop is healthy and the
  surfaces are skipping. `skipped` says why: `routeCovered` (a screen is
  open above this one, which is deliberate), `zeroSize` (the layout gives
  the canvas no room), `measuring` (a frame spent on an automatic height),
  `surfaceNotRegistered` or `surfaceNotReady` (the native view is not ready
  yet, normal for the first frames after mount), `noPainter` (no painter was
  given).
- **Neither climbing, with a surface waiting**, is the loop failing to
  deliver. Set `kCanvasDriverWatchdog = true` before the canvas mounts: the
  framework then checks once a second and, if the loop is armed but silent,
  logs a line beginning `[CanvasSurface] frame driver armed but silent` and
  restarts it. It is off by default. If you see that line, send it with
  this snapshot.

Include this snapshot when reporting a canvas problem.

---

## API reference

| Class / function | Description |
|-----------------|-------------|
| `CanvasSurface` | Widget that hosts a GPU canvas. Calls `painter.paint()` every display frame while animating (see Frame pump) |
| `CanvasDiagnostics` | `CanvasDiagnostics.now()` — the frame loop's state and why each surface dropped its last frame (see Frame pump) |
| `kCanvasDriverWatchdog` | Off by default. Set true to have the framework watch for a frame loop that is armed but delivering nothing, and restart it |
| `CanvasSkipReason` | Why a surface skipped a frame: `none`, `routeCovered`, `noPainter`, `surfaceNotRegistered`, `zeroSize`, `measuring`, `surfaceNotReady` |
| `CustomPainter` | Base class — implement `paint(Canvas, Size)` |
| `Canvas` | Drawing surface. `drawRect`, `drawCircle`, `drawPath`, `drawImage`, `drawParagraph`, `drawPaint`, `save`/`restore`, `clipRect`, `scale`, `translate`, `rotate` |
| `Paint` | Stroke/fill style. `color`, `strokeWidth`, `style`, `shader`, `blendMode`, `imageFilter` |
| `Path` | Vector path. `moveTo`, `lineTo`, `cubicTo`, `arcTo`, `close` |
| `RuntimeEffect` | Compiled SkSL shader. `make(sksl)`, `makeShader(uniforms)`, `makeShaderWithChildren(uniforms, children)` |
| `Shader` | Result of `RuntimeEffect.makeShader()` — attach to `Paint.shader` |
| `SkiaImage` | GPU-resident image. Create via `SkiaImage.fromBytes()` or `SkiaPictureRecorder` |
| `SkiaPictureRecorder` | Offscreen canvas → `SkiaImage`. Use as child shader input |
| `SimpleParagraph` | Quick Latin text with font size and color — no shaping, available in all tiers |
| `ParagraphBuilder` | Full shaped text (full tier). HarfBuzz + BiDi |

---

## Tier selection guide

```
Do you need shaped text *inside* the canvas (Arabic, CJK, RTL, HarfBuzz)?
  ├── Yes  → full   ← what an app gets when the key says nothing
  └── No (shapes + shaders only)  → bare   ← the recommendation
```

---

## Troubleshooting

**Canvas is blank / shows a black rectangle**
- Confirm `dartnative_skia` is in `pubspec.yaml` dependencies.
- Check `shouldRepaint()` — if it always returns `false`, the first frame
  will render but subsequent frames won't.
- **Android**: check logcat for `[DN-Skia]` lines and look for `FAILED` to
  see where the GPU setup stopped. Also confirm the device supports Vulkan
  (API level 26+ / Vulkan 1.1).

**Canvas briefly blank at startup (Android)**
- A surface that is not yet attached to the window renders nothing and
  resolves itself once it appears in the view hierarchy.
- For anything persistent, capture `adb logcat -s DN-Skia VV` and look for
  `FAILED` lines to see where the GPU setup stopped. The lines appear once a
  `CanvasSurface` is on screen; none at all before that is normal.

**`RuntimeEffect.make()` returns null**
- SkSL compilation failed. Print or log the error string from
  `RuntimeEffect.makeWithError(sksl)` to get the compiler message.

**Text looks incorrect / not shaped (Arabic/CJK displays as boxes)**
- Switch to the `full` tier — the `bare` tier uses `SkFont` which
  only handles Latin/ASCII without HarfBuzz shaping.

See also: [troubleshooting.md](troubleshooting.md)
