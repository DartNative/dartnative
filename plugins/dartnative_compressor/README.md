# dartnative_compressor

Compress images and videos in DartNative with the platform's native codecs — fast, and
without the memory blow-up of doing it in Dart. iOS and Android.

## Why you'll like it

- **Native codecs** — AVFoundation on iOS, MediaCodec on Android.
- **Images and videos** — quality presets for video, a 0–100 quality for images.
- **Batteries included** — pull metadata, generate a video thumbnail, save to the gallery,
  and cancel an in-flight job.

## Highlights

- **`compressVideo(file, {quality, customBitRate, onProgress})`** — re-encode a video
  (`VideoQuality.p480` / `p720` / `p1080` / `p1440`; `customBitRate` in Mbps; `onProgress` 0→1).
- **`compressImage(path, {quality, maxDimension, onProgress})`** — recompress an image
  (`quality` 0–100; `maxDimension` caps the longer side).
- **`getVideoInfo` / `getImageInfo`**, **`getVideoThumbnail`**, **`saveToGallery`**,
  **`cancelCompression(id)`**.

## Install

Requires **Android minSdk 26** (Android 8): set `minSdk = 26` in
`android/app/build.gradle.kts` — new projects default lower and the
manifest merge fails until it's raised.

```yaml
dependencies:
  dartnative_compressor: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_compressor/dartnative_compressor.dart';
```

Compress a video, then an image:

```dart
final smaller = await DartNativeCompressor.compressVideo(file, quality: VideoQuality.p720);
final thumb   = await DartNativeCompressor.compressImage('/path/photo.jpg', quality: 80);
```

Grab a thumbnail, then save the result to the gallery:

```dart
final poster = await DartNativeCompressor.getVideoThumbnail(file);
await DartNativeCompressor.saveToGallery(smaller!, mediaType: 'video');
```

## Platform setup

### iOS

Compression itself needs nothing. **`saveToGallery`** writes to Photos, so add an
add-only usage string to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save compressed media to your photo library.</string>
```

### Android

No native setup required.

## Example

The [`example/`](./example) app compresses a picked video + image and shows the size
savings — borrow from it freely.

## Credits & license

Built directly on **AVFoundation** (iOS) and **MediaCodec** (Android).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
