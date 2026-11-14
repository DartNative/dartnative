# Building Everbloom

Run every command from the project root. Outputs go to `build/` (and Cargo's `target/`, `ios/rust/target/`).

## 1. Install dependencies

Required: macOS with Xcode 26 (iOS SDK and an iOS simulator runtime), Homebrew, rustup, and for Android the Android
SDK with platform 35, build-tools and an NDK.

```sh
# Native Shell's CLI, 0.4.0 (the app's NSH crates are pinned to the same version)
brew install longbridge/tap/nsh

# Rust 1.98.1 with the iOS and Android targets (rust-toolchain.toml selects it)
rustup toolchain install 1.98.1 --profile minimal \
  --target aarch64-apple-ios aarch64-apple-ios-sim aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

# Rust crates (NSH comes from its Git tag v0.4.0)
cargo fetch --locked
cargo fetch --locked --manifest-path ios/rust/Cargo.toml

# Android SDK parts (ANDROID_HOME defaults to ~/Library/Android/sdk)
"${ANDROID_HOME:-$HOME/Library/Android/sdk}/cmdline-tools/latest/bin/sdkmanager" \
  "platforms;android-35" "build-tools;36.0.0" "ndk;29.0.14206865" "platform-tools"
```

`ios/Everbloom.xcodeproj` is committed; it was generated from `ios/project.yml` with xcodegen, which is only needed to
regenerate it (`cd ios && xcodegen generate`).

## 2. iOS device release build (benchmarked)

Signed, with automatic signing for the team in `DEVELOPMENT_TEAM`:

```sh
export DEVELOPMENT_TEAM=ABCDE12345   # your Apple team ID
xcodebuild -project ios/Everbloom.xcodeproj -scheme Everbloom -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/ios-device \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" build
```

Without a team (signing disabled):

```sh
xcodebuild -project ios/Everbloom.xcodeproj -scheme Everbloom -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/ios-device \
  CODE_SIGNING_ALLOWED=NO build
```

The app: `build/ios-device/Build/Products/Release-iphoneos/Everbloom.app`

The Xcode target's "Build Rust" phase (`ios/build-rust.sh`) builds the Rust half with
`cargo build --release --target aarch64-apple-ios` (fat LTO, one codegen unit) before Xcode links it. The first build
compiles NSH and takes a few minutes.

## 3. Install and launch on a connected iPhone

```sh
xcrun devicectl list devices                      # note the device's identifier
DEVICE=<device identifier>
xcrun devicectl device install app --device "$DEVICE" \
  build/ios-device/Build/Products/Release-iphoneos/Everbloom.app
xcrun devicectl device process launch --device "$DEVICE" --terminate-existing \
  --environment-variables '{"SHOP_API_URL":"http://192.168.1.20:8787/api"}' \
  dev.whiskerrs.shopbench.nsh
```

Leave out `--environment-variables` (or pass an empty value) to use `https://apparel-large-catalog.mock.shop/api`.
The app writes `SHOPBENCH home_ready` with `os_log` once Home shows its content (Console.app, the device's log).

## 4. iOS Simulator build (verification)

Same project, Release configuration, simulator SDK (arm64):

```sh
xcodebuild -project ios/Everbloom.xcodeproj -scheme Everbloom -configuration Release \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ios-sim build
```

The app: `build/ios-sim/Build/Products/Release-iphonesimulator/Everbloom.app`

```sh
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true    # or any booted simulator
xcrun simctl install booted build/ios-sim/Build/Products/Release-iphonesimulator/Everbloom.app
SIMCTL_CHILD_SHOP_API_URL=http://127.0.0.1:8787/api xcrun simctl launch --terminate-running-process booted dev.whiskerrs.shopbench.nsh
# the log marker:
xcrun simctl spawn booted log stream --style compact --predicate 'eventMessage CONTAINS "SHOPBENCH"'
```

Without `SIMCTL_CHILD_SHOP_API_URL` the app uses mock.shop.

Optional, the UI tests used during development (flows, identifiers, error and Retry, keyboard scrolling):

```sh
xcodebuild test -project ios/Everbloom.xcodeproj -scheme Everbloom \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/ios-test \
  -skip-testing:EverbloomUITests/ErrorStateTests
```

(`ErrorStateTests` expects a server to start on `127.0.0.1:8787` while the error shows.)

## 5. Android release APK

```sh
./android/package.sh
```

The APK: `build/android/Everbloom.apk` (arm64-v8a and armeabi-v7a, signed with the debug key).

The endpoint is a build-time setting: set `SHOP_API_URL` while building, for example

```sh
SHOP_API_URL=http://192.168.1.20:8787/api ./android/package.sh
SHOP_API_URL=http://10.0.2.2:8787/api ./android/package.sh      # the host machine, from the emulator
```

Unset or empty, the app uses mock.shop. Install and launch:

```sh
adb install -r build/android/Everbloom.apk
adb shell am start -n dev.whiskerrs.shopbench.nsh/com.longbridge.nsh.AppActivity
```

`android/package.sh` runs `nsh package --target android` (NSH's release runtime with the app's Rust root in
`libnsh.so`), then links the APK again with `android/AndroidManifest.xml`, NSH's manifest plus cleartext HTTP and
portrait orientation, aligns it (16 KB pages) and signs it.

## 6. Build modes and toolchain

| Build | Mode |
|---|---|
| iOS device | Xcode Release configuration (`-Os` for `main.m`, stripped, dead-code stripped); Rust `--release` with fat LTO, `codegen-units = 1`, `opt-level = 3`; NSH's Rust backend without QuickJS, no dev server, no hot reload, no debug overlay |
| iOS Simulator | The same Release configuration and Rust release profile, for `aarch64-apple-ios-sim`: the most production-like mode, identical to the device build but for the target |
| Android | `nsh package --target android`: NSH's release runtime (`AppActivity`, no dev server), the Rust crate in release mode; debug-key signed |

Versions used:

- macOS 26.5.1, Xcode 26.6 (iOS SDK 26.5), iOS Simulator runtime 26.5 (iPhone 17 Pro)
- Native Shell 0.4.0 (CLI `nsh 0.4.0 (e626a8d)`, crates from `https://github.com/longbridge/nsh` tag `v0.4.0`)
- Rust 1.98.1 (`rust-toolchain.toml`)
- Android SDK platform 35, build-tools 37.0.0, NDK 29.0.14206865, emulator 37.1.11 with an Android 37.1 arm64 image;
  OpenJDK 21 (`keytool`)
- xcodegen 2.45.4 (only to regenerate the Xcode project)
