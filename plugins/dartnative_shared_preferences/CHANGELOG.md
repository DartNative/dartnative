## 1.1.1

- In an iOS app whose default file protection is Complete, the one-time copy of what earlier versions and Flutter's `shared_preferences` saved waits until the device is unlocked. While it is locked, `UserDefaults` cannot be read there, and the copy could find nothing and never run again. Until it has run, reads find nothing and writes return false, as before the first unlock after a restart. What the copy has done is recorded beside the store instead of in `UserDefaults`.
- A long burst of writes no longer piles up old versions of the store's file on disk: at most five exist at once. In a test that writes without pause, there were up to 29 of 8 MB before.
- The podspec says iOS 15.0, the version the iOS library is built for.

## 1.1.0

- An app that shipped on Flutter and updates to its DartNative version under the same app id keeps what Flutter's `shared_preferences` saved, with each value's type.
- `SharedPreferences.setPrefix` is available, for apps whose Flutter build saved under a prefix of its own.
- Values are kept in a store of the plugin's own instead of `NSUserDefaults` and Android's `SharedPreferences`: a write takes about a microsecond, hundreds of times faster than Flutter's on an iPhone and on a mid-range Android phone, and nothing written is lost if the app is killed right after. What earlier versions saved moves over at the first launch.
- Reads are as fast as Flutter's, and a value written by another isolate or a background task is still seen on the next read.
- `incrementInt` and `updateInt`, `updateDouble`, `updateBool`, `updateString` and `updateStringList` change a value safely when several isolates or background tasks write it at once.
- `setString` and the other setters, and `remove`, return false when the value could not be stored, for example on iOS before the device's first unlock after a restart.
- A `SharedPreferences` captured by a closure sent to another isolate, such as one passed to `Isolate.run`, works there.

## 1.0.1

- `getString` now returns a long value whole instead of cutting it off at 4095
  characters.

## 1.0.0

- First release: save simple values such as settings and flags on iOS and
  Android, with the familiar `shared_preferences` API.
