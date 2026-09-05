# dartnative_keys_example

A **dartnative** app, scaffolded by `dn create`. It ships with correct iOS +
Android runner glue (so it renders instead of white-screening) and is ready for a
branded splash + app icon.

## Run it

```sh
dn pub get
dn run -d <device-id>
```

The example is an official demo — free to run, no license setup.

Always use **`dn`** for run/build/pub commands — not the underlying SDK CLI.

## Make it yours

- **Your UI** — edit `lib/main.dart`.
- **App icon + launch logo** — replace `assets/dn-logo.png` with your logo, then
  regenerate icon **and** splash in one step:
  ```sh
  dart run tool/generate_app_assets.dart --source=assets/dn-logo.png --bg=#000000
  ```
  (Splash only: `dart run dartnative_splash:setup`.)
- **Plugins** — browse **[dartpub.dev](https://dartpub.dev)**. Add a package to
  `pubspec.yaml`, run `dn pub get`, and import it — pure-Dart packages and
  dartnative plugins both work as-is.

## Don't touch (unless you know the runtime)

These files are the dartnative runner glue — they're why the app renders:
`ios/Runner/{AppDelegate,SceneDelegate}.swift` + the scene block in `Info.plist`,
and `android/.../{Application,MainActivity}.kt` + the Material3 themes in
`android/app/src/main/res/values*/styles.xml`.

