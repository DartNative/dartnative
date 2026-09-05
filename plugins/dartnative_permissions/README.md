# dartnative_permissions

Runtime permissions for DartNative — request camera, microphone, photos, location,
contacts, and notifications through the system dialogs (AVFoundation / Photos /
CoreLocation / Contacts on iOS, the runtime-permission APIs on Android). One API, both
platforms.

## Why you'll like it

- **Familiar** — `Permission.camera.request()`, `.status`, `openAppSettings()`, just like
  `permission_handler`.
- **One surface, both platforms** — the same `Permission` and `PermissionStatus` on iOS and
  Android; the plugin maps each to the right native API and OS version.
- **Honest statuses** — `granted`, `denied`, `permanentlyDenied`, `restricted`, plus
  `limited` for iOS 14+ and Android 14+ partial photo access.

## Highlights

- **`Permission.x.request()`** — show the system prompt, get back a `PermissionStatus`.
- **`Permission.x.status`** — read the current status without a dialog.
- **`Permission.x.isGranted` / `.isLimited`** — quick boolean checks.
- **`openAppSettings()`** — jump to the app's Settings page (iOS Settings / Android app info).

Permissions: `microphone`, `camera`, `photos`, `videos`, `notification`, `location`,
`locationWhenInUse`, `contacts`, `storage`, and the Android "special" pair
`ignoreBatteryOptimizations` / `accessNotificationPolicy` (open the system screen;
`granted` on iOS).

## Install

```yaml
dependencies:
  dartnative_permissions: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_permissions/dartnative_permissions.dart';
```

Request a permission:

```dart
final status = await Permission.microphone.request();
if (status.isGranted) {
  // start recording…
}
```

Check the current status without prompting, and route the user to Settings if they've
permanently denied it:

```dart
final status = await Permission.camera.status;
if (status.isPermanentlyDenied) openAppSettings();
```

Handle partial photo access:

```dart
final photos = await Permission.photos.request();
if (photos.isLimited) {
  // user shared a selected subset of their library
}
```

> `limited` means partial access: on iOS 14+ the user shared a selected subset of their
> photo library; on Android 14+ they granted "Selected photos" access. Treat it like
> `granted` for the photos the user picked.

## Platform setup

### iOS

For every permission you request, add its usage-description key to `ios/Runner/Info.plist` —
iOS shows it in the prompt and rejects apps that prompt without one:

| Permission | Info.plist key |
|---|---|
| `camera` | `NSCameraUsageDescription` |
| `microphone` | `NSMicrophoneUsageDescription` |
| `photos` | `NSPhotoLibraryUsageDescription` |
| `location`, `locationWhenInUse` | `NSLocationWhenInUseUsageDescription` |
| `contacts` | `NSContactsUsageDescription` |
| `notification` | *(none)* |

`storage` and `videos` have no iOS equivalent and always resolve to `granted`.

### Android

Declare the `<uses-permission>` entries your app uses in
`android/app/src/main/AndroidManifest.xml` — only declared permissions are ever requested:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>

<!-- Android 14+ partial ("Selected photos") access -->
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED"/>

<!-- Legacy storage, Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
```

## Example

The [`example/`](./example) app lists every permission with its live, colour-coded status —
tap a row to request it, and use "Open app settings" to jump to Settings. Borrow from it
freely.

## Credits & license

Ported from
[`permission_handler`](https://github.com/Baseflow/flutter-permission-handler)
(Baseflow, MIT), reworked to FFI.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on
the plugin's page.
