# dartnative_secure_storage

Encrypted key–value storage for DartNative — the iOS Keychain and Android
EncryptedSharedPreferences behind the familiar `flutter_secure_storage` API. iOS and Android.

## Why you'll like it

- **Encrypted at rest** — Keychain on iOS, EncryptedSharedPreferences on Android.
- **Familiar API** — `read` / `write` / `delete` / `readAll` / `deleteAll` / `containsKey`, like `flutter_secure_storage`.
- **Zero setup** — self-contained native bridge over FFI; no MethodChannel, no extra wiring.

## Highlights

- **`read({key})` / `write({key, value})` / `delete({key})`**
- **`readAll()` / `deleteAll()` / `containsKey({key})`** — enumerate, clear, or test for a key.

> Most `IOSOptions` / `AndroidOptions` parameters are accepted for source compatibility but
> ignored — the plugin uses sensible defaults (Keychain `AfterFirstUnlockThisDeviceOnly` on iOS,
> EncryptedSharedPreferences AES-256 on Android). The exception is `AndroidOptions.resetOnError`
> (default `true`, Android-only, matching upstream): if the encrypted keyset can't be decrypted
> (e.g. after a backup-restore), the store is wiped and recreated instead of failing.

## Install

```yaml
dependencies:
  dartnative_secure_storage: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_secure_storage/dartnative_secure_storage.dart';

final storage = SecureStorage();

await storage.write(key: 'token', value: 'abc123');
final token = await storage.read(key: 'token');   // 'abc123' or null
await storage.delete(key: 'token');
```

Read everything, or clear it:

```dart
final all = await storage.readAll();   // Map<String, String>
await storage.deleteAll();
```

## Platform setup

### iOS

No native setup required.

### Android

No native setup required.

## Example

The [`example/`](./example) app writes, reads, and clears a secret — borrow from it freely.

## Credits & license

API mirrors
[`flutter_secure_storage`](https://github.com/juliansteenbakker/flutter_secure_storage)
(BSD-3-Clause); the plugin ships its own native bridge — Keychain on iOS,
EncryptedSharedPreferences on Android — over FFI, built on the DartNative framework's
runtime (FFI loader, and the Android application context).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
