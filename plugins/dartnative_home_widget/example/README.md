# home_widget_example

A **DartNative** app, made by `dn create`.

## Run it

```sh
dn pub get
dn run -d <device-id>
```

DartNative apps need a licence. Subscribe at
[dartpub.dev/framework](https://dartpub.dev/framework), copy your licence key
(`dnk_...`) from the Framework panel, and set it once:

```sh
dn config --license-key dnk_...
```

After that, `dn run` works on every platform. If you prefer not to store the
key, pass it on each run instead: `dn run --dart-define=DN_LICENSE_KEY=dnk_...`.

Use **`dn`** for every run, build and package command.

## Make it yours

- **Your UI**: edit `lib/main.dart`.
- **App icon and launch screen**: add `dartnative_splash: ^1.0.0` under
  `dependencies` in `pubspec.yaml`, and this section at the end of the file
  (the launch screen's colour and image; the plugin's page on dartpub.dev
  lists the other settings):
  ```yaml
  dartnative_splash:
    background_color: "#000000"
    image: assets/dn-logo.png
  ```
  Run `dn pub get`. Replace `assets/dn-logo.png` with your logo (at least
  1024×1024 pixels), then make the icon and the launch screen in one step:
  ```sh
  dn pub run tool/generate_app_assets.dart --source=assets/dn-logo.png --bg=#000000
  ```
  `--bg` is the icon's background colour. To remake only the launch screen:
  `dn run-tool dartnative_splash:setup`.
- **Packages and plugins**: browse [dartpub.dev](https://dartpub.dev). Add a
  package to `pubspec.yaml` in the form its page shows, run `dn pub get`, and
  import it. Pure-Dart packages from pub.dev work as they are.
- **Generated code** (json_serializable, freezed, Hive adapters): add
  `build_runner` and the generator under `dev_dependencies`, then run
  `dn pub run build_runner build`.

## The native app files

`ios/Runner/AppDelegate.swift`, `ios/Runner/SceneDelegate.swift`, and
`Application.kt` and `MainActivity.kt` under `android/app/src/main/kotlin/`
are empty classes. Each one inherits from a DartNative class that starts the
app, so there is nothing in them to keep in step. Add native code there when
you need it, and call the parent class's version of any method you override.

Two settings the app relies on: the scene section in `ios/Runner/Info.plist`,
which tells iOS to use `SceneDelegate`, and `LaunchTheme` in
`android/app/src/main/res/values*/styles.xml`, which the Android manifest
gives the app's screen.
