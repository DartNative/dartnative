# Native video playback

The finished code for the [video tutorial](https://dartnative.com/tutorials/video-player):
two player screens on the real AVPlayer / ExoPlayer via
`dartnative_video_player` — the ready-made `VideoPlayerWithControls` widget
(fullscreen and rotation handled), and YouTube-style controls built from
scratch on the raw `VideoPlayer` + controller: drag-to-seek scrubber,
auto-hiding transport, volume toggle.

Requires **Android minSdk 26** — `dartnative_video_player`'s minimum (the
committed `android/app/build.gradle.kts` already sets it).

```sh
dn pub get
dn run
```

The two screens under [`lib/screens/media/`](lib/screens/media/) are
BYTE-IDENTICAL copies of the DartNative playground's Video Playback and
Custom Controls demos ([`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart)
is the playground's shared UI kit, also verbatim) — when the playground
demos improve, this tutorial updates by copying the files again.
[`lib/main.dart`](lib/main.dart) adds only a thin two-row launcher.
Verified against dartnative `^1.0.0`.
