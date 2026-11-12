# dartnative_camera

Camera for DartNative — a live preview widget, photo capture, and video recording on the
device's native camera stack (AVFoundation on iOS, CameraX on Android).

## See it in action

https://github.com/user-attachments/assets/379b7cbb-8f7e-47e4-b623-f87a67c2e9cb

The viewfinder in photo mode, a switch to video, the phone turned
sideways while recording, and the clip saved to Photos.

This is the plugin's example app. Tap to focus, pinch to zoom, pick an
aspect ratio, and take a photo or record a video from the same screen.
Rotation is smooth, with no freeze or stutter. Photos and videos save
straight to the phone's gallery. The same example is in the [playground app](https://github.com/DartNative/dartnative/tree/main/playground) as Camera.

## Why you'll like it

- **A real preview widget** — drop `CameraPreview` into your tree and you get a hardware-backed
  viewfinder, with pinch-to-zoom and tap-to-focus on by default.
- **Photos and video from one controller** — `takePicture()`, `startVideoRecording()` /
  `stopVideoRecording()`, flash, zoom, focus and exposure points.
- **Reads QR codes and barcodes**: `startCodeScan()` reads codes on the device while the preview,
  photos and the flash keep working.
- **Frame streaming when you need it** — `startImageStream()` hands you `CameraImage` frames for
  ML or your own processing.

## Highlights

- **`DartNativeCamera.availableCameras()`** → the device's `CameraDescription`s (front / back).
- **`CameraController(description, ResolutionPreset.high, …)`** → `initialize()`, then drive
  capture, flash, zoom, focus and recording. Optionally pass `videoQuality: VideoQuality.fhd` —
  both are honoured on iOS and Android, and the controller uses the higher of the two.
- **`CameraPreview(controller: …)`** — the live viewfinder widget (pinch-to-zoom, tap-to-focus).
- **`takePicture()` / `startVideoRecording()` / `stopVideoRecording()`** — return a file path.
- **`startCodeScan(onCode: …)`** → your code runs once for each new code in view, with its text,
  its format and where it is on the preview; the returned `Stream<List<ScannedCode>>` has every
  code in view, for drawing frames; `stopCodeScan()`.
- **`startImageStream()`** → a `Stream<CameraImage>` of live frames; `saveToGallery(path)`.

## Install

```yaml
dependencies:
  dartnative_camera: ^1.1.0   # from dartpub.dev
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

**Read codes**

```dart
final codes = await controller.startCodeScan(
  formats: CodeFormat.all, // the default is QR codes only
  onCode: (ScannedCode code) async {
    // Once per new code: your app decides what it means.
    if (code.value.startsWith('https://shop.example.com/')) {
      await openProduct(code.value); // a code you accept: open your screen
    } else {
      await showAlert(context: context, title: 'No valid code detected.');
    }
  }, // no other code arrives until this returns
);
// Every code in view, for drawing a frame around each one:
codes.listen((List<ScannedCode> found) => setState(() => inView = found));
// …later…
await controller.stopCodeScan();
```

A code held in front of the camera reaches `onCode` once, and again only after it has been out
of view for a second. `corners` and `bounds` run from 0 to 1 across the preview, so an overlay
of any size can draw a frame around the code. Nothing is read while a video records, and
`setFlashMode(FlashMode.torch)` helps in the dark.

On iOS the system reads the codes. On Android, Google's ML Kit reads them, delivered through
Google Play services so it adds little to your app's size. ZXing reads until ML Kit is ready on
the phone, and on phones without Play services.

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

The [`example/`](./example) app lists the cameras, shows a live preview, captures both photos and
video, and reads codes: a link opens in the browser, and any other code shows its text in an
alert. Borrow from it freely.

**Try code scanning.** The example's `test_codes` folder has three codes. Run the example, tap
**Scan**, open a code on your computer's screen, and point the phone's camera at it:

| Code | It holds | What the example does |
|---|---|---|
| [QR code](https://raw.githubusercontent.com/DartNative/dartnative/main/plugins/dartnative_camera/example/test_codes/qr_opens_link.png) | `https://dartnative.com` | opens the link in the browser |
| [Code 128 barcode](https://raw.githubusercontent.com/DartNative/dartnative/main/plugins/dartnative_camera/example/test_codes/barcode_opens_link.png) | `https://dartpub.dev` | opens the link in the browser |
| [EAN-13 barcode](https://raw.githubusercontent.com/DartNative/dartnative/main/plugins/dartnative_camera/example/test_codes/ean13_shows_alert.png) | `5901234123457` | shows the number in an alert |

A frame appears around the code. Each code is handled once while it stays in view: back from the
browser, or after closing the alert, with the code still there, nothing happens again. Point the
camera away for a second and back, and the code is read again.

## Credits & license

Adapted from Flutter's official camera plugin — `camera_avfoundation` (iOS) and
`camera_android_camerax` (Android), BSD-3-Clause — reworked to run natively on DartNative.
Reading codes on Android uses [ZXing](https://github.com/zxing/zxing) (Apache-2.0) and Google's
ML Kit.

First-party DartNative plugin, free to use in any DartNative app. Distributed
through [dartpub.dev](https://dartpub.dev); report issues on the plugin's page.
