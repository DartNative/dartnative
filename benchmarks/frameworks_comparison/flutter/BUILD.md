# Building Everbloom (Flutter)

All commands run from the project root.

## Toolchain used

| Tool | Version |
|---|---|
| Flutter | 3.35.7 (stable, framework `adc9010625`, engine `035316565a`) |
| Dart | 3.9.2 |
| Xcode | 26.6 (17F113), iOS SDK 26.5 |
| CocoaPods | 1.16.2 |
| JDK | OpenJDK 21.0.6 |
| Android Gradle Plugin / Gradle / Kotlin | 8.9.1 / 8.12 / 2.1.0 |
| Android compileSdk / minSdk / NDK | 36 / 24 / 27.0.12077973 |

## Build modes

| Target | Mode |
|---|---|
| iOS device (benchmarked) | **Release** (Dart AOT, arm64, optimizations on, no VM service or hot reload) |
| iOS Simulator | **Debug** (Dart JIT). Flutter supports only debug mode on the simulator; `--profile` and `--release` give "not supported for simulators". |
| Android | **Release** APK (AOT), signed with the debug key |

## 1. Install dependencies

```sh
flutter pub get
flutter build ios --release --config-only   # writes ios/Flutter/Generated.xcconfig and runs pod install
(cd ios && pod install)
```

## 2. iOS device release build

Signed (automatic signing with the team in `DEVELOPMENT_TEAM`):

```sh
export DEVELOPMENT_TEAM=XXXXXXXXXX
flutter build ios --release --config-only
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/ios-device \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic build
```

Without `DEVELOPMENT_TEAM` (code signing disabled):

```sh
flutter build ios --release --config-only
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/ios-device \
  CODE_SIGNING_ALLOWED=NO build
```

Output: `build/ios-device/Build/Products/Release-iphoneos/Runner.app`

## 3. Install and launch on a connected iPhone

```sh
xcrun devicectl list devices
DEVICE=<identifier from the list>
xcrun devicectl device install app --device "$DEVICE" \
  build/ios-device/Build/Products/Release-iphoneos/Runner.app
xcrun devicectl device process launch --device "$DEVICE" --terminate-existing \
  --environment-variables '{"SHOP_API_URL":"http://192.168.1.20:8787/api"}' \
  dev.whiskerrs.shopbench.flutter
```

Leave out `--environment-variables` to use the default endpoint (`https://apparel-large-catalog.mock.shop/api`).
The `SHOPBENCH home_ready` line appears in Console.app for the device (process `Runner`).

## 4. iOS Simulator build

```sh
flutter build ios --simulator --debug
```

Output: `build/ios/iphonesimulator/Runner.app`

```sh
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
SIMCTL_CHILD_SHOP_API_URL=http://127.0.0.1:8787/api \
  xcrun simctl launch --terminate-running-process booted dev.whiskerrs.shopbench.flutter
```

Leave out `SIMCTL_CHILD_SHOP_API_URL=…` to use the default endpoint. To watch the log marker:

```sh
xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "SHOPBENCH"'
```

## 5. Android release APK

Default endpoint:

```sh
flutter build apk --release
```

Custom endpoint (a build-time setting, read via `--dart-define`):

```sh
flutter build apk --release --dart-define=SHOP_API_URL=http://192.168.1.20:8787/api
```

From the Android emulator, the host Mac is `10.0.2.2` (for example `--dart-define=SHOP_API_URL=http://10.0.2.2:8787/api`).

Output: `build/app/outputs/flutter-apk/app-release.apk`

```sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n dev.whiskerrs.shopbench.flutter/.MainActivity
```
