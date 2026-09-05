# Charts on the native canvas

The finished code for the [CustomPaint tutorial](https://dartnative.com/tutorials/native-canvas):
Flutter's `CustomPainter` API drawn by the platform's own 2D renderer
(Core Graphics on iOS, `android.graphics.Canvas` on Android) — eighteen
painter sections covering shapes, charts, gradient shaders, the full
paragraph pipeline (metrics, hit testing, struts, foreground paints),
`drawImage`/`drawImageRect`, and animated text.

```sh
dn pub get
dn run
```

[`lib/screens/custom_paint_demo.dart`](lib/screens/custom_paint_demo.dart)
is a BYTE-IDENTICAL copy of the DartNative playground's CustomPaint demo
([`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is the
playground's shared UI kit, also verbatim); [`lib/main.dart`](lib/main.dart)
adds only the thin entry point. When the playground screen improves, this
tutorial updates by copying the files again. Verified against dartnative
`^1.0.0`.
