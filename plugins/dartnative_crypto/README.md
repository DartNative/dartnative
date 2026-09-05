# dartnative_crypto

RSA and AES cryptography for DartNative — generate keys, encrypt/decrypt, and sign/verify
against native crypto. iOS and Android, one API.

## Why you'll like it

- **RSA, done properly** — OAEP and PKCS#1 v1.5 encryption, PSS and PKCS#1 v1.5 signing.
- **AES-GCM** — authenticated symmetric encryption in two calls.
- **Strings or bytes** — every RSA op has a `…Bytes` variant for raw `Uint8List`, plus key
  tooling (generate, PKCS#1 ↔ PKCS#8, derive the public key, PEM-encrypt a private key).

## Highlights

- **`RSA.generate(bits)`** → an `RSAKeyPair` (PEM public + private keys).
- **`RSA.encryptOAEP` / `decryptOAEP`** — OAEP encryption (with `…Bytes` variants).
- **`RSA.signPSS` / `verifyPSS`** (and `signPKCS1v15` / `verifyPKCS1v15`) — signatures.
- **`AES.encrypt(data, key)` / `AES.decrypt(data, key)`** — AES-GCM.
- **`AES.pbkdf2(…)`** — PBKDF2 key derivation; **`AES.digest(data, algorithm)`** — SHA-256/384/512.
- **RSA key tooling** — convert between PKCS#1 / PKCS#8 / PKIX / JWK, derive the public key, PEM-encrypt.

## Install

```yaml
dependencies:
  dartnative_crypto: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_crypto/dartnative_crypto.dart';
```

Generate a key pair, then encrypt + decrypt (OAEP):

```dart
final pair = await RSA.generate(2048);

final cipher = await RSA.encryptOAEP('hello', '', RSAHash.SHA256, pair.publicKey);
final clear  = await RSA.decryptOAEP(cipher, '', RSAHash.SHA256, pair.privateKey);
```

Sign + verify (PSS):

```dart
final sig = await RSA.signPSS('message', RSAHash.SHA256, SaltLength.AUTO, pair.privateKey);
final ok  = await RSA.verifyPSS(sig, 'message', RSAHash.SHA256, SaltLength.AUTO, pair.publicKey);
```

AES-GCM:

```dart
final encrypted = await AES.encrypt(data, key); // Uint8List
final decrypted = await AES.decrypt(encrypted, key);
```

## Platform setup

### iOS

No native setup required (iOS 13+).

### Android

No native setup required (Android API 26+ / Android 8).

## Example

The [`example/`](./example) app generates keys and round-trips encrypt/decrypt and
sign/verify — borrow from it freely.

## Credits & license

Adapted from [`flutter-rsa`](https://github.com/jerson/flutter-rsa) (MIT) and
[`native-crypto-flutter`](https://github.com/hugo-pcl/native-crypto-flutter) (MIT),
reworked to FFI.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on
the plugin's page.
