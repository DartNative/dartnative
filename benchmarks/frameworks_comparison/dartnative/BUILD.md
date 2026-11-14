# Building Everbloom (DartNative)

All commands run from the project root. `dn` is the DartNative tool (Flutter-like commands).

## Toolchain used

| Tool | Version |
|---|---|
| DartNative | 1.7.0 |
| Plugins | dartnative_http 1.1, dartnative_url_launcher 1.0 |
| Xcode | 27.2 (27B5028f), iOS 27.2 SDK; simulator iPhone 17 Pro, iOS 27.2 |
| CocoaPods | 1.16.2 |
| JDK | OpenJDK 17.0.8.1 |
| Android | compileSdk / minSdk / NDK from the DartNative Gradle plugin (`dartnative.compileSdkVersion` etc.) |

## Build modes

| Target | Mode |
|---|---|
| iOS device (benchmarked) | **Release** (Dart AOT, arm64, optimizations on, no VM service or hot reload) |
| iOS Simulator | **Debug** (Dart JIT). DartNative, like Flutter, builds only debug for the simulator: `--profile` and `--release` stop with "Profile/Release mode is not supported for simulators". |
| Android | **Release** APK (AOT), signed with the debug key |

## Licence

No licence key is needed to build and run this app. Any machine can build and run DartNative's
official demos with no account and no key, and this app's bundle id,
`dev.whiskerrs.shopbench.dartnative`, is on that list, for debug and release builds alike. To build
your own apps, get a license at dartpub.dev/framework; the Community license is free.

## 1. Install dependencies

```sh
dn pub get
```

`dn pub get` fetches the DartNative packages and the two plugins' native artifacts, and writes
`lib/dartnative_plugin_registrant.dart` and `ios/DartNative/Generated.xcconfig`. CocoaPods runs as part
of the iOS builds below.

## 2. iOS device release build

The build that was measured. `dn` signs it with your development certificate, as `flutter build ios`
does:

```sh
dn build ios --release
```

Output: `build/ios/iphoneos/Runner.app` (13.9 MB), where `tools/measure.py` reads it.

Signed with the Apple team in `DEVELOPMENT_TEAM` (automatic signing), through `xcodebuild`:

```sh
dn build ios --release --config-only
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/ios-device \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic build
```

Output: `build/ios-device/Build/Products/Release-iphoneos/Runner.app`.

With `DEVELOPMENT_TEAM` unset, the build runs with code signing disabled (`CODE_SIGNING_ALLOWED=NO`):

```sh
dn build ios --release --no-codesign
```

Output: `build/ios/iphoneos/Runner.app`, unsigned. Both were built with DartNative 1.7.0.

## 3. Install and launch on a connected iPhone

```sh
xcrun devicectl list devices
DEVICE=<identifier from the list>
xcrun devicectl device install app --device "$DEVICE" \
  build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device "$DEVICE" --terminate-existing \
  --environment-variables '{"SHOP_API_URL":"http://192.168.1.20:8787/api"}' \
  dev.whiskerrs.shopbench.dartnative
```

Leave out `--environment-variables` to use the default endpoint (`https://apparel-large-catalog.mock.shop/api`).
The `SHOPBENCH home_ready` line appears in Console.app for the device (process `Runner`, message
`dartnative: SHOPBENCH home_ready`).

## 4. iOS Simulator build

```sh
dn build ios --simulator --debug
```

Output: `build/ios/iphonesimulator/Runner.app`

```sh
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
SIMCTL_CHILD_SHOP_API_URL=http://127.0.0.1:8787/api \
  xcrun simctl launch --terminate-running-process booted dev.whiskerrs.shopbench.dartnative
```

Leave out `SIMCTL_CHILD_SHOP_API_URL=…` to use the default endpoint. To watch the log marker:

```sh
xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "SHOPBENCH"'
```

## 5. Android release APK

Default endpoint:

```sh
dn build apk --release
```

Custom endpoint (a build-time setting, read with `String.fromEnvironment`):

```sh
dn build apk --release --dart-define=SHOP_API_URL=http://192.168.1.20:8787/api
```

From the Android emulator, the host Mac is `10.0.2.2` (for example `--dart-define=SHOP_API_URL=http://10.0.2.2:8787/api`).

Output: `build/app/outputs/dn-apk/app-release.apk`. Built and run on a Xiaomi 11 Lite 5G NE
(Android 14): Home loads from the replay server, and the line reaches logcat as
`I dartnative: SHOPBENCH home_ready`.

```sh
adb install -r build/app/outputs/dn-apk/app-release.apk
adb shell am start -n dev.whiskerrs.shopbench.dartnative/.MainActivity
```
