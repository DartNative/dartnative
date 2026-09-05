# dartnative_image_crop

Crop, sample, and inspect images natively in DartNative — an interactive `Crop` widget plus
programmatic cropping that stays fast and memory-friendly on large photos. iOS and Android.

## Why you'll like it

- **Two ways to crop** — drop the interactive **`Crop`** widget, or crop programmatically
  with `cropImage(...)`.
- **Native + memory-friendly** — the heavy lifting happens in native code, so big images
  don't blow up your heap.
- **Inspect & downsample** — read an image's dimensions, or sample it down to a target size.

## Highlights

- **`Crop`** — an interactive crop widget (pan / zoom to frame the crop).
- **`DartNativeImageCrop.cropImage({file, area, scale})`** — crop to a normalized `Rect`.
- **`getImageOptions({file})`** — read the image's dimensions; **`sampleImage(...)`** — downsample.

## Install

```yaml
dependencies:
  dartnative_image_crop: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_image_crop/dartnative_image_crop.dart';
```

Crop programmatically — `area` is a normalized `Rect` (0–1):

```dart
final cropped = await DartNativeImageCrop.cropImage(
  file: file,
  area: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8), // centered 80%
);
```

Read dimensions first:

```dart
final opts = await DartNativeImageCrop.getImageOptions(file: file);
```

Or let the user frame it with the interactive widget:

```dart
Crop(/* … */); // pan & zoom to choose the crop
```

## Platform setup

### iOS

No native setup required.

### Android

No native setup required.

## Example

The [`example/`](./example) app crops a picked image both ways — borrow from it freely.

## Credits & license

Ported from [`image_crop`](https://github.com/lykhonis/image_crop) (lykhonis, Apache-2.0),
reworked to FFI.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
