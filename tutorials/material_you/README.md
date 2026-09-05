# Material 3 & dynamic color

The finished code for the [Material You tutorial](https://dartnative.com/tutorials/material-you):
an app accented by the device's wallpaper-derived palette (`DynamicColor`),
with real M3 badges (`Badge` on a tab and a bar action), the native
hide-on-scroll bottom bar from one generic field
(`TabBarScrollBehavior.minimizeOnScrollDown`), and a Palette tab that lays
the five system tonal palettes and the M3 color roles bare.

Dynamic color needs Android 12+; elsewhere `DynamicColor` returns `null`
and the app falls back to a fixed seed accent. Badges and the
hide-on-scroll field lower to the iOS equivalents from the same Dart.

```sh
dn pub get
dn run
```

The three screens under [`lib/screens/material3/`](lib/screens/material3/)
are BYTE-IDENTICAL copies of the DartNative playground's Material 3 demos
(dynamic color, live badges, hide-on-scroll bar), and
[`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is the
playground's shared UI kit, also verbatim — when the playground demos
improve, this tutorial updates by copying the files again. The only code
written for the tutorial is [`lib/main.dart`](lib/main.dart), a thin
three-row launcher. Verified against dartnative `^1.0.0`.
