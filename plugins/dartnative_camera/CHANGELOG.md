## 1.1.0

- Read QR codes and barcodes through the camera with `startCodeScan`, while
  the preview and photos keep working.
- On Android, `FlashMode.torch` now works.
- On iOS, `startImageStream` no longer stops the app.

## 1.0.3

- On Android, a camera result that arrives during a hot restart no longer
  reaches the restarted app.

## 1.0.2

- Apps now build for the iOS simulator with Xcode 26.
- The plugin prints nothing at launch or on each photo unless verbose logging
  is on.

## 1.0.1

- On iOS, apps now build with Xcode 27.

## 1.0.0

- First release: show a live camera preview, take photos, record video and
  stream frames on iOS and Android.
