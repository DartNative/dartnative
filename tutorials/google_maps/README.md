# A native map

The finished code for the [maps tutorial](https://dartnative.com/tutorials/google-maps):
a real GMSMapView / MapView in the widget tree via
`dartnative_google_maps` — markers, camera moves, map types, gestures.

API keys required (one per platform, provided natively — never in Dart).
Handle them the way the plugin's example app does: keys live in
**gitignored files**, flow into the build, and are never committed.

**iOS** — `Secrets.xcconfig → Info.plist → AppDelegate`:

1. Create `ios/DartNative/Secrets.xcconfig` (gitignored) with your key:
   `MAPS_API_KEY = AIza...`
2. Add to both `ios/DartNative/Debug.xcconfig` and `Release.xcconfig`:
   `#include? "Secrets.xcconfig"`
3. In `ios/Runner/Info.plist`:
   `<key>GMSApiKey</key> <string>$(MAPS_API_KEY)</string>`
4. In `AppDelegate.swift`, hand the key to the SDK before anything uses it
   (`import GoogleMaps`, then in `didFinishLaunchingWithOptions` before the
   `super` call):

   ```swift
   if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !key.isEmpty {
     GMSServices.provideAPIKey(key)
   }
   ```

   Without this call the first map view aborts with `GMSServicesException`
   — the key handoff is app-side by design (keys vary per environment and
   are your secret to manage; the plugin never auto-reads them).

**Android** — `secrets.properties → build.gradle.kts → manifest placeholder`:

1. Create `android/secrets.properties` (gitignored) with your key:
   `MAPS_API_KEY=AIza...`
   (`secrets.properties`, NOT `local.properties` — the dn tool rewrites
   `local.properties` on every run and drops unknown keys, which yields an
   empty placeholder → auth failure → a white map.)
2. In `android/app/build.gradle.kts`, read it and feed the placeholder
   (plus `import java.util.Properties` at the top):

   ```kotlin
   val mapsApiKey: String = run {
       val props = Properties()
       val f = rootProject.file("secrets.properties")
       if (f.exists()) f.inputStream().use { props.load(it) }
       props.getProperty("MAPS_API_KEY") ?: ""
   }
   // inside android { defaultConfig { ... } }:
   manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
   ```

3. In `AndroidManifest.xml`, inside `<application>`:

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${MAPS_API_KEY}"/>
   ```

The Google Maps SDK also needs **iOS 15.0+**: set `platform :ios, '15.0'`
in `ios/Podfile` (the generated shell defaults lower) and match the iOS
Deployment Target in Xcode, or `pod install` refuses to build.

The plugin README walks through creating restricted keys in the Google
Cloud console; its example app ships with all of this wiring in place to
copy from.

```sh
dn pub get
dn run
```

The whole app is one file: [`lib/main.dart`](lib/main.dart).
Verified against dartnative `^1.0.0`.
