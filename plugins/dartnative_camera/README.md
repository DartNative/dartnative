# dartnative_camera

Camera for DartNative — a live preview widget, photo capture, and video recording on the
device's native camera stack (AVFoundation on iOS, CameraX on Android).

## Why you'll like it

- **A real preview widget** — drop `CameraPreview` into your tree and you get a hardware-backed
  viewfinder, with pinch-to-zoom and tap-to-focus on by default.
- **Photos and video from one controller** — `takePicture()`, `startVideoRecording()` /
  `stopVideoRecording()`, flash, zoom, focus and exposure points.
- **Frame streaming when you need it** — `startImageStream()` hands you `CameraImage` frames for
  ML, scanning, or your own processing.

## Highlights

- **`DartNativeCamera.availableCameras()`** → the device's `CameraDescription`s (front / back).
- **`CameraController(description, ResolutionPreset.high, …)`** → `initialize()`, then drive
  capture, flash, zoom, focus and recording. Optionally pass `videoQuality: VideoQuality.fhd` —
  both are honoured on iOS and Android, and the controller uses the higher of the two.
- **`CameraPreview(controller: …)`** — the live viewfinder widget (pinch-to-zoom, tap-to-focus).
- **`takePicture()` / `startVideoRecording()` / `stopVideoRecording()`** — return a file path.
- **`startImageStream()`** → a `Stream<CameraImage>` of live frames; `saveToGallery(path)`.

## Install

```yaml
dependencies:
  dartnative_camera: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

Register the plugin once, in `main()`:

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

**Pick a camera and start the preview**

```dart
import 'package:dartnative_camera/dartnative_camera.dart';

final cameras = await DartNativeCamera.availableCameras();
final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

final controller = CameraController(back, ResolutionPreset.high);
await controller.initialize();

// In your build():
CameraPreview(controller: controller);
```

**Take a photo**

```dart
final path = await controller.takePicture();   // file path to the JPEG
```

**Record video**

```dart
await controller.startVideoRecording();
// …later…
final videoPath = await controller.stopVideoRecording();
```

**Flash, zoom, focus**

```dart
controller.setFlashMode(FlashMode.auto);
controller.setZoomLevel(2.0);            // clamped 1×–8×
controller.setFocusPoint(0.5, 0.5);      // normalized point
```

**Stream frames**

```dart
final frames = await controller.startImageStream();
frames.listen((CameraImage image) {
  // image.bytes, image.width, image.height — feed your ML / scanner
});
// …later…
await controller.stopImageStream();
```

> The preview is a native view rendered through DartNative's view bridge
> (ViewType range **1020–1029**), so it composes with the rest of your Dart UI.

## Platform setup

### iOS

Add usage descriptions to your app's `Info.plist` — iOS shows the system permission prompt the
first time the camera (or microphone) is accessed:

```xml
<key>NSCameraUsageDescription</key>
<string>Used to take photos and record video.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used to record audio with video.</string>
```

(The microphone key is only needed if you record video with audio — the default.)

### Android

The plugin's manifest already declares `CAMERA` and `RECORD_AUDIO`, so there's nothing to add.
`initialize()` asks for them at runtime the first time (Android 6+); a refused grant throws a
`CameraException` with code `CameraAccessDenied`.

## Orientation — pin the UI, rotate only the capture

Camera UIs are **portrait-pinned** — Apple's Camera never rotates its
screen. The pin freezes ONLY the UI: rotating the device still captures
landscape photos and videos, because the capture pipeline follows the
physical orientation. Pin your camera screen on entry and release on exit:

```dart
// initState
SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
// dispose
SystemChrome.setPreferredOrientations(DeviceOrientation.values);
```

and feed the capture pipeline from `DeviceOrientationListener` (see the
example's `_onOrientation`). The example app is *also* portrait-only in its
project settings, so this mistake never shows there — but hosted in a
rotation-enabled app, an unpinned camera screen spins its chrome and
letterboxes the preview on rotation.

## Example

The [`example/`](./example) app lists the cameras, shows a live preview, and captures both
photos and video — borrow from it freely.

## Credits & license

Adapted from Flutter's official camera plugin — `camera_avfoundation` (iOS) and
`camera_android_camerax` (Android), BSD-3-Clause — reworked to run natively on DartNative.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
