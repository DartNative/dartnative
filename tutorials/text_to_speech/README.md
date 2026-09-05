# On-device text-to-speech

The finished code for the [TTS tutorial](https://dartnative.com/tutorials/text-to-speech):
neural speech synthesis running entirely on the phone with
`dartnative_supertonic_tts` (SuperTonic-3 — a pure-Dart, all-ONNX pipeline on
`dartnative_onnxruntime`; 31 languages, 10 voices) — streamed chunk-by-chunk
into `dartnative_audio`'s `PcmStreamPlayer` for instant first-audio.

The ~144 MB model downloads automatically on first use and is cached; the
screen includes a delete control to reclaim the space.

Requires **iOS 16.0+** — `dartnative_onnxruntime`'s minimum deployment
target — and **Android minSdk 26** — `dartnative_path_provider`'s minimum
(the committed `ios/Podfile`, Xcode project and
`android/app/build.gradle.kts` already set both).

```sh
dn pub get
dn run
```

The screens under [`lib/screens/media/`](lib/screens/media/) are
BYTE-IDENTICAL copies of the DartNative playground's SuperTonic demo — the
full demo screen plus its 31-language full-screen picker
(`lib/screens/home/demo_ui.dart` is the playground's shared UI kit, also
verbatim). Only the thin [`lib/main.dart`](lib/main.dart) entry is
tutorial-specific, so improvements to the playground screens flow into this
tutorial by copying the files again. Verified against dartnative `^1.0.0`.
