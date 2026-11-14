# Building Everbloom (React Native)

Run every command from the project root on a clean checkout.

## Toolchain used

| Tool | Version |
|---|---|
| React Native | 0.88.1 (New Architecture, Hermes; React 19.3.0) |
| @react-native-community/cli | 20.2.0 |
| Node.js / npm | 26.13.0 / 11.20.0 (RN requires Node >= 22.11) |
| Xcode | 26.6 (17F113), iOS 26.5 simulator runtime |
| CocoaPods | 1.16.2 |
| JDK | OpenJDK 21.0.6 (Android Studio JBR) |
| Gradle / Android Gradle Plugin | 9.4.1 / 9.2.1 |
| Android SDK | compileSdk 37, targetSdk 36, minSdk 24, build-tools 37.0.0, NDK 27.1.12297006 |

Android builds need `ANDROID_HOME` (for example `~/Library/Android/sdk`) and `JAVA_HOME` pointing at JDK 17–21.

## 1. Install dependencies

```sh
npm ci
(cd ios && pod install)
```

`pod install` also runs React Native codegen for the app's native module (`specs/NativeShopBench.ts`).
If you prefer the Gemfile's pinned CocoaPods: `bundle install && (cd ios && bundle exec pod install)`.

## 2. iOS device release build (benchmarked)

Mode: **Release** configuration, `arm64` iOS device SDK (`iphoneos`), optimizations on, Hermes bytecode bundle embedded in the app (no Metro, no dev menu or hot reload).

Signed, with automatic signing for the team in `DEVELOPMENT_TEAM`:

```sh
export DEVELOPMENT_TEAM=XXXXXXXXXX   # your Apple team ID
xcodebuild -workspace ios/Everbloom.xcworkspace -scheme Everbloom \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath ios/build -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic \
  build
```

Without a team (unsigned, compile check):

```sh
xcodebuild -workspace ios/Everbloom.xcworkspace -scheme Everbloom \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath ios/build CODE_SIGNING_ALLOWED=NO \
  build
```

Resulting app: `ios/build/Build/Products/Release-iphoneos/Everbloom.app`

## 3. Install and launch on a connected iPhone

```sh
xcrun devicectl list devices                       # find the device identifier
DEVICE=<device-identifier>
xcrun devicectl device install app --device "$DEVICE" \
  ios/build/Build/Products/Release-iphoneos/Everbloom.app
xcrun devicectl device process launch --device "$DEVICE" --terminate-existing \
  --environment-variables '{"SHOP_API_URL":"http://192.168.1.20:8787/api"}' \
  dev.whiskerrs.shopbench.reactnative
```

Leave out `--environment-variables` to use the default endpoint (`https://apparel-large-catalog.mock.shop/api`).
The app writes `SHOPBENCH home_ready` to the unified log (via `os_log`) once Home has loaded content.

## 4. iOS Simulator build (verification)

Mode: **Release** configuration for the simulator SDK (`iphonesimulator`). This is the most production-like mode React Native supports on the simulator: same optimized native code and embedded Hermes bundle as the device build, no Metro or dev tools.

```sh
xcodebuild -workspace ios/Everbloom.xcworkspace -scheme Everbloom \
  -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ios/build \
  build
```

Resulting app: `ios/build/Build/Products/Release-iphonesimulator/Everbloom.app`

Install and launch on the booted simulator, with an endpoint override:

```sh
xcrun simctl install booted ios/build/Build/Products/Release-iphonesimulator/Everbloom.app
SIMCTL_CHILD_SHOP_API_URL=http://192.168.1.20:8787/api \
  xcrun simctl launch --terminate-running-process booted dev.whiskerrs.shopbench.reactnative
```

Watch for the log marker:

```sh
xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "SHOPBENCH"'
```

## 5. Android release APK

Mode: **release** build type (`assembleRelease`), Hermes bytecode bundle embedded, signed with the debug keystore that ships with the template.

```sh
(cd android && ./gradlew assembleRelease)
```

Resulting APK: `android/app/build/outputs/apk/release/app-release.apk`

The endpoint is a build-time setting. Set the `SHOP_API_URL` environment variable (or pass the Gradle property `-PSHOP_API_URL=…`) when building. Leave it out to use the default endpoint:

```sh
(cd android && SHOP_API_URL=http://192.168.1.20:8787/api ./gradlew assembleRelease)
# or: (cd android && ./gradlew assembleRelease -PSHOP_API_URL=http://10.0.2.2:8787/api)
```

Change the value with `./gradlew clean` first, or Gradle may reuse the old `BuildConfig`. On the emulator, `10.0.2.2` is the host Mac.

Install and launch:

```sh
adb install -r android/app/build/outputs/apk/release/app-release.apk
adb shell am start -n dev.whiskerrs.shopbench.reactnative/.MainActivity
```

## 6. Build modes summary

| Target | Configuration | JS |
|---|---|---|
| iOS device (benchmarked) | Xcode `Release`, `iphoneos` arm64 | Hermes bytecode embedded (`main.jsbundle`) |
| iOS Simulator | Xcode `Release`, `iphonesimulator` | Hermes bytecode embedded |
| Android | Gradle `release` (debug keystore) | Hermes bytecode embedded |
