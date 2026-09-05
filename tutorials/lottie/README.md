# Lottie in the hierarchy

The finished code for the [Lottie tutorial](https://dartnative.com/tutorials/lottie):
a sticker grid streaming 78 live animated `.zip` bundles from a CDN on the
native `lottie-ios` / `lottie-android` engines, inside a windowed `FastGrid`.

Requires **Android minSdk 26** — `dartnative_lottie`'s minimum (the
committed `android/app/build.gradle.kts` already sets it).

```sh
dn pub get
dn run
```

[`lib/screens/lottie/lottie_grid_demo.dart`](lib/screens/lottie/lottie_grid_demo.dart)
is a BYTE-IDENTICAL copy of the DartNative playground's Lottie grid demo
(`lib/screens/home/demo_ui.dart` is the playground's shared UI kit, also
verbatim). Only the thin [`lib/main.dart`](lib/main.dart) entry is
tutorial-specific, so improvements to the playground screen flow into this
tutorial by copying the file again. Verified against dartnative `^1.0.0`.
