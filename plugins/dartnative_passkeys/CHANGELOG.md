## 0.1.0

* Initial release: Android Restore Credentials (restore keys) for DartNative
  apps — `PasskeyAuthenticator.createRestoreCredential`,
  `getRestoreCredential`, `clearRestoreCredential` and the
  `PasskeyAuthenticator.isSupported` probe. Ported from Corbado's
  `passkeys_android` 2.15.0; the Flutter pigeon transport is replaced by FFI.
  Android only.
