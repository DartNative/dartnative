# Storage, all four kinds

The finished code for the [storage tutorial](https://dartnative.com/tutorials/storage):
one tabbed screen exercising each on-device store — SharedPreferences for
settings (drop-in `shared_preferences` API), the Keychain /
EncryptedSharedPreferences for secrets (drop-in `flutter_secure_storage`
API), Hive for objects, and SQLite for relational rows. All over direct
FFI — no MethodChannel, callable from any isolate.

Requires **Android minSdk 26** — `dartnative_path_provider`'s minimum (the
committed `android/app/build.gradle.kts` already sets it).

```sh
dn pub get
dn run
```

The screen under [`lib/screens/`](lib/screens/) is a byte-identical copy of
the playground's Storage demo (`storage_demo.dart`; `home/demo_ui.dart` is
the playground's shared UI kit, also verbatim), so improvements to the
playground screen flow into this tutorial by re-copying the files.
[`lib/main.dart`](lib/main.dart) is a thin entry that registers the plugins
and launches the screen. Verified against dartnative `^1.0.0`.
