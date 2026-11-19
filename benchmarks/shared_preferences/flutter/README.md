# Flutter side

A `flutter create` app with `shared_preferences` 2.5.6, the legacy
`SharedPreferences` API that `dartnative_shared_preferences` mirrors. Its
`lib/benchmark/` is the DartNative example's with two lines changed;
`../tool/sync_flutter.sh` copies it again. `lib/main.dart` runs every case
on launch, prints the table to the console, and writes it to
`prefs_bench.txt` in the app's temporary folder. The screen and both system
bars are black, as on the DartNative side.

```
flutter build ios --profile        # or: flutter build apk --profile
```
