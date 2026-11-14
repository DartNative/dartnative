# Building Everbloom (Whisker)

All commands run from the project root of a clean checkout, in `bash`/`zsh`.
`gen/` (native projects) and `build/` (Xcode derived data) are generated and
git-ignored.

## 1. Install dependencies

Prerequisites: macOS with Xcode 27 (command line tools selected), Android
Studio (Android SDK, NDK 27.x and its bundled JDK; Whisker finds them under
`~/Library/Android/sdk` without `ANDROID_HOME`/`JAVA_HOME`), and rustup.

```sh
rustup toolchain install stable
rustup target add aarch64-apple-ios aarch64-apple-ios-sim aarch64-linux-android
cargo install whisker-cli --version 0.17.0 --locked
whisker doctor            # every check should pass
cargo fetch               # Rust dependencies (pinned by Cargo.lock)
```

The Swift (SwiftPM) and Android (Gradle/Maven) dependencies are resolved by
`xcodebuild` / Gradle on the first build.

## 2. iOS device release build (benchmarked)

Generate the Xcode project from `whisker.rs`, then build Release for
`generic/platform=iOS` (arm64). The Xcode build phase compiles the Rust crate
in release mode (`whisker build-ios --configuration Release`, `lto = true`,
`codegen-units = 1`); hot reload / the dev server are not part of this build.

```sh
cargo run --bin whisker-config --features whisker-config -- ios
```

Signed, with `DEVELOPMENT_TEAM` set (automatic signing):

```sh
export DEVELOPMENT_TEAM=ABCDE12345   # your Apple team ID
xcodebuild -project gen/ios/Everbloom.xcodeproj -scheme Everbloom \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath build/device \
  -skipPackagePluginValidation -skipMacroValidation \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic \
  build
```

Without a team (code signing disabled):

```sh
xcodebuild -project gen/ios/Everbloom.xcodeproj -scheme Everbloom \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath build/device \
  -skipPackagePluginValidation -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Resulting app: `build/device/Build/Products/Release-iphoneos/Everbloom.app`

(`-skipPackagePluginValidation -skipMacroValidation` let a headless build use
Whisker's SwiftPM codegen plugin and Swift macro; `whisker` itself passes the
same flags.)

## 3. Install and launch on a connected iPhone

```sh
xcrun devicectl list devices                     # note the device identifier
DEVICE=<device-identifier>
xcrun devicectl device install app --device "$DEVICE" \
  build/device/Build/Products/Release-iphoneos/Everbloom.app
xcrun devicectl device process launch --device "$DEVICE" \
  --terminate-existing \
  --environment-variables '{"SHOP_API_URL":"http://192.168.1.20:8787/api"}' \
  dev.whiskerrs.shopbench.whisker
```

`SHOP_API_URL` is read at launch; when unset or empty the app uses
`https://apparel-large-catalog.mock.shop/api`. The `SHOPBENCH home_ready`
marker is written with `NSLog` and appears in Console.app for the device.

## 4. iOS Simulator build (verification)

Mode: **Release configuration** for the simulator (`iphonesimulator` SDK,
`aarch64-apple-ios-sim` Rust target, release Rust profile) — the most
production-like mode Whisker supports there; same generated project as the
device build, no dev server or hot reload.

```sh
cargo run --bin whisker-config --features whisker-config -- ios
xcodebuild -project gen/ios/Everbloom.xcodeproj -scheme Everbloom \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/sim \
  -skipPackagePluginValidation -skipMacroValidation \
  build
```

Resulting app: `build/sim/Build/Products/Release-iphonesimulator/Everbloom.app`

Install and launch on the booted simulator, with the endpoint override:

```sh
xcrun simctl install booted build/sim/Build/Products/Release-iphonesimulator/Everbloom.app
SIMCTL_CHILD_SHOP_API_URL=http://192.168.1.20:8787/api \
  xcrun simctl launch --terminate-running-process booted dev.whiskerrs.shopbench.whisker
# log marker:
xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "SHOPBENCH"'
```

## 5. Android release APK

Mode: Gradle `release` build type (Rust compiled in release mode for
`arm64-v8a`), signed with the local debug keystore through the
`WHISKER_ANDROID_*` variables the generated Gradle project reads.

The endpoint is a **build-time** setting on Android: export `SHOP_API_URL`
before building (omit it for the default mock.shop endpoint). Cargo tracks the
variable, so changing it rebuilds the Rust library.

```sh
cargo run --bin whisker-config --features whisker-config -- android
export SHOP_API_URL=http://192.168.1.20:8787/api   # optional
cd gen/android && \
  WHISKER_ANDROID_KEYSTORE="$HOME/.android/debug.keystore" \
  WHISKER_ANDROID_KEYSTORE_PASSWORD=android \
  WHISKER_ANDROID_KEY_ALIAS=androiddebugkey \
  WHISKER_ANDROID_KEY_PASSWORD=android \
  ./gradlew :app:assembleRelease && cd ../..
```

(If `~/.android/debug.keystore` does not exist yet, create it with
`keytool -genkeypair -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -validity 10000 -dname "CN=Android Debug,O=Android,C=US"`.)

Resulting APK: `gen/android/app/build/outputs/apk/release/app-release.apk`

```sh
adb install -r gen/android/app/build/outputs/apk/release/app-release.apk
adb shell am start -n dev.whiskerrs.shopbench.whisker/.MainActivity
```

## 6. Build modes and toolchain versions

| Target | Mode |
|---|---|
| iOS device | Xcode `Release`, `generic/platform=iOS` (arm64), Rust release profile with LTO |
| iOS Simulator | Xcode `Release`, `iphonesimulator`, Rust release profile with LTO |
| Android | Gradle `release`, arm64-v8a, Rust release profile with LTO, debug-keystore signing |

Versions of the benchmarked build (2026-11-11), after the move to Xcode 27
described in `results/xcode27/README.md`:

- Xcode 27.2, iOS 27.2
- Whisker 0.17.0 (`whisker`, `whisker-cli`, `whisker-cng`), whisker-router
  0.14.4, whisker-image / -svg / -input / -keyboard / -safe-area /
  -web-browser 0.14.5;
  Whisker iOS SwiftPM package 0.1.20 (`shop-native/Package.swift`)

Versions the AI run used:

- macOS 26.5.1, Xcode 26.6 (17F113), iOS Simulator runtime 26.5 (iPhone 17 Pro)
- Rust 1.96.0 (stable), cargo 1.96.0
- Whisker 0.16.0 (`whisker`, `whisker-cli`, `whisker-cng`, `whisker-plugin`),
  whisker-router 0.14.3, whisker-image / -svg / -input / -keyboard /
  -safe-area / -web-browser 0.14.4; Whisker iOS SwiftPM package 0.1.19,
  Android SDK artifacts 0.1.21/0.1.26
- Gradle 8.11.1 (wrapper), JDK 21.0.6 (Android Studio JBR), Android
  compileSdk 34 / minSdk 24 / targetSdk 34, NDK 27.x
- Android emulator: `Medium_Phone` AVD
