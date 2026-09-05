# dartnative_splash

Native iOS and Android splash screens for DartNative apps, generated from a single
`pubspec.yaml` config block. One command, both platforms — including the Android 12+
SplashScreen API — with no native code to write.

## Why you'll like it

- **One config block** — set a background color and a logo once; the CLI generates
  every iOS and Android asset (all densities, light + dark).
- **Android 12+ done right** — emits the OS SplashScreen API theme plus an icon kept
  inside the circular-mask safe zone, so there's no grey flash and no clipped logo.
- **Build-time tool, native result** — the generator is pure Dart (a dev-dependency:
  no FFI, no platform channels, no runtime code added by the plugin). The splash itself
  is fully native — the OS draws it from the generated `LaunchScreen.storyboard` /
  theme XML / PNGs before your Dart entrypoint runs.

## Highlights

- **`dart run dartnative_splash:setup`** — reads your config and writes every asset.
- **iOS** — `LaunchScreen.storyboard` + the `LaunchImage` asset-catalog images.
- **Android** — `launch_background` (API < 31) **and** the Android 12+ SplashScreen API
  (`values-v31` / `values-night-v31` + `android12splash.png`), with Material3 launch themes.
- **Light + dark** — optional `dark_image` / `dark_background_color` variants.

## Install

```yaml
dev_dependencies:
  dartnative_splash: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

## Quick look

Add a `dartnative_splash:` block to your app's `pubspec.yaml`:

```yaml
dartnative_splash:
  background_color: "#000000"
  image: assets/logo/splash_logo.png
  # Optional dark-mode overrides:
  dark_background_color: "#000000"
  dark_image: assets/logo/splash_logo_dark.png
  # Platform toggles (both default to true):
  android: true
  ios: true
```

Generate the native assets (re-run any time you change the config or the logo):

```bash
dart run dartnative_splash:setup
```

The Android 12 safe-zone is enforced automatically — the logo is scaled to fit a
760 px CIRCLE on the 1200 × 1200 canvas, measured from the content's centre to
its farthest painted pixel (the mask is round, so fitting width and height alone
leaves the corners sticking out), and the content is centred rather than the
image, so lopsided transparent padding can't push it off centre.

## What it generates

### iOS

`LaunchScreen.storyboard` + the `LaunchImage` image set. No manual Xcode setup.

### Android

- `drawable-*/splash.png` + `drawable/launch_background.xml` — the API < 31 splash.
- `drawable/android12splash.png` + `values-v31/` / `values-night-v31/` — the Android 12+
  system splash, using the platform `windowSplashScreen*` attributes (**no**
  `androidx.core:core-splashscreen` dependency and no `installSplashScreen()` call).
- Material3 launch themes in `values/` / `values-night/`.

## Example

The [`example/`](./example) app shows the generated splash, then lands on a bare
welcome screen — borrow from it freely. The generated native assets are committed
under `example/android/app/src/main/res/`, so you can inspect exactly what the
setup command writes (legacy `launch_background`, the Android 12+ `android12splash.png`,
and the four `values*/styles.xml` launch themes).

Run it:

```bash
cd example

# 1. (Re)generate the splash assets from the config block in pubspec.yaml:
dart run dartnative_splash:setup

# 2. Launch on a device/emulator (Android shown; iOS works the same):
dn run
```

On a cold start you should see: solid background → logo (drawn by the OS
SplashScreen API on Android 12+, or `launch_background` on older devices) → the
welcome screen — no grey flash and no logo size jump. To change the splash, edit
the `dartnative_splash:` block in `example/pubspec.yaml` and re-run the setup command.

## Credits & license

Written from scratch for DartNative (not a port of `flutter_native_splash`).

Distributed via [dartpub.dev](https://dartpub.dev) — file issues on the plugin's page.
