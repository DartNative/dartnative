# Build a plugin

The finished code for the [build-a-plugin tutorial](https://dartnative.com/tutorials/build-a-plugin):
the demo app for `dartnative_share` — the **open-source** official plugin
the article builds from scratch. The plugin's full source (Dart FFI
bindings, Swift `@_cdecl` bridge, Kotlin + JNI bridge, and the
hot-restart-safe `shareWithResult` callback) lives in this repo at
[`plugins/dartnative_share`](../../plugins/dartnative_share).

```sh
dn pub get
dn run
```

On Android, set `minSdk = 26` in `android/app/build.gradle.kts` first —
`dartnative_compressor`'s floor (the generated shell defaults to 24 and
the manifest merge fails).

[`lib/share_demo.dart`](lib/share_demo.dart) is a BYTE-IDENTICAL copy of
the share plugin's example app: pick photos/videos from the gallery
(`dartnative_media_picker`, with video poster frames via
`dartnative_compressor`), type a caption, then **Share text only**,
**Share text with result** (watch the status line report the picked
target — or the dismissal), or **Share picked items**. Only the thin
[`lib/main.dart`](lib/main.dart) entry is tutorial-specific, so
improvements to the plugin example flow into this tutorial by copying the
file again. Verified against dartnative `^1.0.0`.
