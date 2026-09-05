# Liquid Glass, the real one

The finished code for the [Liquid Glass tutorial](https://dartnative.com/tutorials/liquid-glass):
the iOS 26 material as a widget — interactive glass capsules with Dart
children, the fluid merge (`GlassEffectGroup`), regular vs clear styles,
a frosted bar, and a pushed screen with the clear large-title bar.
Graceful fallback everywhere else.

```sh
dn pub get
dn run
```

The two screens under [`lib/screens/liquid_glass/`](lib/screens/liquid_glass/)
are byte-identical copies of the DartNative playground's Liquid Glass
demos ([`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart)
is the playground's shared UI kit, also verbatim) —
[`lib/main.dart`](lib/main.dart) adds only a thin two-row launcher. When
the playground demos improve, this tutorial updates by copying the files
again. Verified against dartnative `^1.0.0`.
