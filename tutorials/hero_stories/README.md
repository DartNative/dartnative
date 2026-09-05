# A story viewer with Hero

The finished code for the [Hero tutorial](https://dartnative.com/tutorials/hero-stories):
the Instagram story-viewer pattern — tapping a named avatar morphs it into a
fullscreen viewer (`Hero` + `RouteTransition.none`), and dragging the viewer
down runs the same morph in reverse, collapsing it back into the avatar.

```sh
dn pub get
dn run
```

[`lib/screens/hero_demo.dart`](lib/screens/hero_demo.dart) is a
BYTE-IDENTICAL copy of the DartNative playground's Hero demo
([`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is the
playground's shared UI kit, also verbatim), with its two images bundled
under `assets/`. [`lib/main.dart`](lib/main.dart) is a thin entry that
registers the plugins and launches the screen. When the playground demo
improves, this tutorial updates by copying the files again. Verified
against dartnative `^1.0.0`.
