## 2.0.0

- Hive now ships inside this package, and existing boxes open as they are.
- Writes are much faster, and nothing is lost if the app crashes or is
  killed.
- `Hive.initDartNative(path, mmap: false)` keeps the previous file storage.
- Generated adapters now come from `dartnative_hive_generator` 2.0.0.
- After upgrading, run `dn pub run build_runner build` once.

## 1.0.0

- First release: Hive for DartNative apps, started with
  `Hive.initDartNative(path)`.
