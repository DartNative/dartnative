# Skia (dartnative_skia)

**Skia** is the industry-standard 2D graphics engine — the same one that renders
Chrome and Android. `dartnative_skia` compiles **Skia Graphite**
(Skia's modern GPU backend — Metal on iOS, Vulkan on Android) directly into your
app's binary and exposes it as a `CanvasSurface` widget you draw into from Dart.

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

`dartnative_skia` ships in two pre-built tiers. Choose the smallest tier
that covers your use case. You can always upgrade later.

| Tier | iOS (`Runner` arm64) | Android (`libdartnative_android.so` arm64-v8a) | What you get |
|------|----------------------|-------------------------------------------------|--------------|
| **bare**   | ~7.8 MB | 4.2 MB  | **Canvas** + SkSL runtime shaders + Graphite (Metal/Vulkan); basic Latin text |
| **full**   | ~20 MB  | 17.6 MB | Everything in **bare** + **rich shaped text** (HarfBuzz, SkParagraph, BiDi, Arabic/CJK/RTL, full ICU) |

**Not sure which to pick?** Start with **full** — it's the default and covers
the vast majority of canvas use cases including rich text rendering.

---

## Setup

### 1. Add the dependency

```yaml
# pubspec.yaml
dependencies:
  dartnative: ^1.0.0
  dartnative_skia: ^1.0.0
```

### 2. Select your tier

Add one line under `dartnative_skia:` in `pubspec.yaml`:

```yaml
dartnative_skia:
  variant: full   # bare | full  (default: full)
```

That's it. Both iOS (CocoaPods) and Android (Gradle) read this key
automatically — no Podfile or Gradle changes needed.

### 3. iOS — run pod install

```bash
cd ios && pod install
```

CocoaPods picks up the correct `libDNSkia_<tier>.a` from the archives bundled
in the `dartnative_skia` package, based on the variant above.

### 4. Android — build details

Gradle auto-detects the Skia package, reads the variant from `pubspec.yaml`,
and passes the right `.a` files to the CMake build. No extra `build.gradle`
changes needed.

**Verify Skia is linked:** check logcat for `[DN-Skia]` messages at app
launch. If they are absent, check that your pubspec includes the
`dartnative_skia` dependency (not just `dartnative_android`).

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
// Requires variant: full
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

---

## API reference

| Class / function | Description |
|-----------------|-------------|
| `CanvasSurface` | Widget that hosts a GPU canvas. Calls `painter.paint()` every display frame while animating (see Frame pump) |
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
  ├── Yes  → full  ← default
  └── No (shapes + shaders only)  → bare
```

---

## Troubleshooting

**Canvas is blank / shows a black rectangle**
- Confirm `dartnative_skia` is in `pubspec.yaml` dependencies.
- Run `pod install` after adding the package (iOS).
- Check `shouldRepaint()` — if it always returns `false`, the first frame
  will render but subsequent frames won't.
- **Android**: check logcat for `[DN-Skia]` lines and look for `FAILED` to
  see where the GPU setup stopped. Also confirm the device supports Vulkan
  (API level 26+ / Vulkan 1.1).

**Canvas briefly blank at startup (Android)**
- A surface that is not yet attached to the window renders nothing and
  resolves itself once it appears in the view hierarchy.
- For anything persistent, capture `adb logcat -s DN-Skia VV` and look for
  `FAILED` lines to see where the GPU setup stopped. No `[DN-Skia]` lines at
  all means the Skia library is not linked — check your dependencies.

**`RuntimeEffect.make()` returns null**
- SkSL compilation failed. Print or log the error string from
  `RuntimeEffect.makeWithError(sksl)` to get the compiler message.

**"Variant X not found" warning in Xcode build log**
- That tier's binary isn't present in your installed package. Re-run
  `dn pub get`; if the warning persists, report it to dev@dartnative.com.

**Text looks incorrect / not shaped (Arabic/CJK displays as boxes)**
- Switch to the `full` tier — the `bare` tier uses `SkFont` which
  only handles Latin/ASCII without HarfBuzz shaping.

See also: [troubleshooting.md](troubleshooting.md)
