## 0.1.0

* Initial release: iOS Live Activities and Android Live Updates for DartNative
  apps, from one Dart API (`LiveActivities.start`, `LiveActivity.update`,
  `end`). The design is written in Dart and drawn natively: SwiftUI in a
  widget extension on iOS, a promoted notification on Android 16 and later.
  Ported from `live_island_kit` 0.4.0; the Flutter method channel is replaced
  by FFI.
