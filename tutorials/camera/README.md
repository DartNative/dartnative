# A camera screen

The finished code for the [camera tutorial](https://dartnative.com/tutorials/camera):
a full photo + video camera on the real AVFoundation / CameraX pipelines via
`dartnative_camera` — live native preview with built-in tap-to-focus and
pinch-to-zoom, flash, flip, aspect-ratio selector, photo capture with
aspect crop (`dartnative_image_crop`), video recording with a REC timer and
frame-0 thumbnail (`dartnative_compressor`), sound cues (`dartnative_audio`),
and capture straight to the gallery.

Platform setup before running:
- **iOS**: `Info.plist` needs `NSCameraUsageDescription`,
  `NSMicrophoneUsageDescription`, and the two Photos keys
  (`NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`
  for the gallery save + browse features) — this repo's
  [`Info.plist`](ios/Runner/Info.plist) ships all four; copy them into
  your own app. Missing the camera key is an instant crash on first open.
- **Android**: set `minSdk = 26` in `android/app/build.gradle.kts` —
  `dartnative_compressor`'s floor (the generated shell defaults to 24 and
  the manifest merge fails). The plugin's manifest DECLARES `CAMERA` and
  `RECORD_AUDIO`, but Android 6+ also needs a runtime request — add the
  permission block from this repo's
  [`MainActivity.kt`](android/app/src/main/kotlin/com/dartnative/tutorials/camera/MainActivity.kt)
  (mirrors the camera plugin example's) to your activity's `onCreate`, or
  the grant stays denied and the camera fails to open.
- Use a physical device; simulators have no camera.

```sh
dn pub get
dn run
```

The screen — [`lib/screens/media/camera_demo.dart`](lib/screens/media/camera_demo.dart)
— is a byte-identical copy of the playground's camera demo
(`lib/screens/home/demo_ui.dart` is the playground's shared UI kit, also
verbatim); [`lib/main.dart`](lib/main.dart) is just a thin launcher. Updates
are literal file copies from the playground. Verified against dartnative
`^1.0.0`.
