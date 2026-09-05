# dartnative_google_maps

Google Maps for DartNative — a native map widget with markers, camera control, and gestures,
rendered on the platform's own Google Maps SDK (`GMSMapView` on iOS, `MapView` on Android). iOS and Android.

## Why you'll like it

- **A real native map widget** — drop `GoogleMaps` into your tree and you get a hardware-backed
  map, not a screenshot or a web view.
- **Markers, camera, gestures** — set the initial camera position, add and clear markers, and
  toggle zoom / scroll, all from Dart.
- **The map types you expect** — normal, satellite, terrain, and hybrid.

## Highlights

- **`GoogleMaps(initialCameraPosition: …)`** — the native map widget.
- **`CameraPosition(latitude, longitude, zoom)`** — where the map opens.
- **`Marker(id, latitude, longitude)`** — pass a `markers` list; tap callbacks via `onMarkerTap`.
- **`mapType`** — `MapType.normal` / `satellite` / `terrain` / `hybrid`.
- **`zoomGesturesEnabled` / `scrollGesturesEnabled`**, plus `onMapReady` and `onCameraMove`.

## Install

Requires **iOS 15.0+** (the Google Maps SDK's floor): set
`platform :ios, '15.0'` in `ios/Podfile` and match the iOS Deployment
Target in Xcode — new projects default lower and `pod install` will
refuse to build until both are raised.

```yaml
dependencies:
  dartnative_google_maps: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

Register and initialize once, in `main()`:

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  initializeGoogleMapsPlugin();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_google_maps/dartnative_google_maps.dart';

GoogleMaps(
  initialCameraPosition: const CameraPosition(
    latitude: 37.7749,
    longitude: -122.4194,
    zoom: 12,
  ),
  mapType: MapType.normal,
  markers: const [
    Marker(id: 'sf', latitude: 37.7749, longitude: -122.4194),
  ],
  onMarkerTap: (id) => print('tapped $id'),
  onCameraMove: (pos) => print('camera → ${pos.latitude}, ${pos.longitude}'),
);
```

## Setting up your API key

Google Maps needs an API key, **one per platform**, and the key is provided **natively** — never
passed in Dart. The bundled [`example/`](./example) already has all the wiring; you just create
your keys and drop them into two **gitignored** files, so nothing secret is ever committed.

### 1. Create the keys (Google Cloud console)

You need **two keys** — one for Android, one for iOS. In
[console.cloud.google.com](https://console.cloud.google.com/) (check you're in the right project),
open **APIs & Services → Credentials**, then **+ Create Credentials → API Key** twice:

**Android key**
1. Create the key, then **Edit API Key**.
2. **Application restrictions → Android apps → Add an item**:
   - **Package name** — e.g. `com.example.myapp`
   - **SHA-1 fingerprint** — from:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```
     (copy the `SHA1:` line). For release builds, add your release keystore's SHA-1 too.
3. **API restrictions → Restrict key → Maps SDK for Android → Save**.

**iOS key**
1. Create the key, then **Edit API Key**.
2. **Application restrictions → iOS apps → Add an item** → your **Bundle ID** (e.g. `com.example.myapp`).
3. **API restrictions → Restrict key → Maps SDK for iOS → Save**.

### 2. Give the keys to the app

The example already contains the wiring below — copy it into your app, then just create the two
gitignored files with your keys.

**iOS** — the key flows `Secrets.xcconfig → Info.plist → AppDelegate`:

```swift
// ios/Runner/AppDelegate.swift
import GoogleMaps
// inside application(_:didFinishLaunchingWithOptions:)
if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !key.isEmpty {
  GMSServices.provideAPIKey(key)
}
```
```xml
<!-- ios/Runner/Info.plist -->
<key>GMSApiKey</key>
<string>$(MAPS_API_KEY)</string>
```
```
# ios/DartNative/Debug.xcconfig and Release.xcconfig — add at the end:
#include? "Secrets.xcconfig"
```
```
# ios/DartNative/Secrets.xcconfig  ← gitignored; create it with your key
# (copy the example's ios/DartNative/Secrets.example.xcconfig template):
MAPS_API_KEY = your-ios-api-key
```

**Android** — the key flows `secrets.properties → manifestPlaceholders → manifest`
(a dedicated gitignored secrets file, NOT `local.properties`: the dn tool
rewrites `local.properties` on every run and drops unknown keys — an empty
placeholder means an auth failure and a white map):

```kotlin
// android/app/build.gradle.kts
import java.util.Properties
val mapsApiKey: String = run {
    val props = Properties()
    val f = rootProject.file("secrets.properties")
    if (f.exists()) f.inputStream().use { props.load(it) }
    props.getProperty("MAPS_API_KEY") ?: ""
}
// inside android { defaultConfig { … } }:
manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
```
```xml
<!-- android/app/src/main/AndroidManifest.xml, inside <application> -->
<meta-data android:name="com.google.android.geo.API_KEY" android:value="${MAPS_API_KEY}" />
```
```properties
# android/secrets.properties  ← gitignored; add your key:
MAPS_API_KEY=your-android-api-key
```

> Both `Secrets.xcconfig` and `secrets.properties` are gitignored, so your keys stay out of source
> control — the committed files only ever hold the `$(MAPS_API_KEY)` / `${MAPS_API_KEY}` placeholders.

## API reference

### GoogleMaps

The map widget. The API key is **not** a prop — set it natively (see above).

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `initialCameraPosition` | `CameraPosition` | — | Initial camera position (required) |
| `mapType` | `MapType` | `normal` | Map rendering type |
| `zoomGesturesEnabled` | `bool` | `true` | Enable pinch-to-zoom |
| `scrollGesturesEnabled` | `bool` | `true` | Enable pan / scroll |
| `markers` | `List<Marker>` | `[]` | Initial markers |
| `onMapReady` | `void Function()` | — | Called when the map is ready |
| `onMarkerTap` | `void Function(String)` | — | Called with the marker id on tap |
| `onCameraMove` | `void Function(CameraPosition)` | — | Called on camera movement |

`MapType`: `none` · `normal` · `satellite` · `terrain` · `hybrid`.

## Example

The [`example/`](./example) app shows a live map with markers and camera control — and the full,
working API-key wiring — borrow from it freely.

## Credits & license

Adapted from Flutter's official [`google_maps_flutter`](https://pub.dev/packages/google_maps_flutter)
(BSD-3-Clause), reworked to run natively on DartNative atop the Google Maps SDKs.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
