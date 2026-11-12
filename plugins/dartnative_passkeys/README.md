# dartnative_passkeys

Sign users back in **silently on their next phone**. Android's Restore
Credentials API creates a *restore key* after sign-in and carries it to the
user's new device through cloud backup or a device-to-device transfer; on first
launch there your app retrieves it and signs the user in without a single tap.
This plugin exposes that API to DartNative apps, as a port of Corbado's
`passkeys_android`, implementing its `RestoreCredentialInterface`. It covers
the restore-key calls only; the standard passkey register and authenticate
flows are not included.

Users who switch phones stay signed in instead of starting over at a login
screen. The same mechanism satisfies Google Play's **Zero-Tap Sign-In**
requirement: from **April 2027**, any Play app with user sign-in (optional or
mandatory; games are currently exempt) must restore the signed-in state when a
user migrates to a new Android device, and Google measures it by whether apps
successfully retrieve the restore key.

## Why you'll like it

- **Users stay signed in across phones.** Someone who upgrades their device
  opens your app already signed in, instead of hitting a login wall on day one:
  fewer abandoned accounts and fewer password resets.
- **No user prompts.** Creation and retrieval are silent; cloud backup falls
  back to a local key automatically when the device can't encrypt it end to end.
- **One less screen to phish.** The silent restore takes the sign-in and
  account-recovery screens out of the device switch: nothing for the user to
  re-enter, and no sign-in form for a phishing site to imitate.
- **Your passkey server already works.** Requests and responses are standard
  WebAuthn JSON (`RegisterRequestType` / `AuthenticateRequestType` in,
  `RegisterResponseType` / `AuthenticateResponseType` out), verified by the same
  relying-party endpoints as passkeys.
- **Zero-Tap Sign-In compliance.** The three calls Google Play's requirement is
  built on: create the restore key, retrieve it on the new device, delete it on
  sign-out.
- **Familiar API.** It implements the same `RestoreCredentialInterface` as the
  `passkeys` plugin, so code written against it ports unchanged.

## Highlights

- **`PasskeyAuthenticator.createRestoreCredential(request, {isCloudBackupEnabled})`**
  → a `RegisterResponseType` to register with your server.
- **`PasskeyAuthenticator.getRestoreCredential(request)`** → an
  `AuthenticateResponseType` to sign in with; `android-no-credential` means
  there is nothing to restore.
- **`PasskeyAuthenticator.clearRestoreCredential()`** deletes the key on
  sign-out.
- **`PasskeyAuthenticator.isSupported`** is `true` on Android 9 (API 28) or
  later.

Android only, and it needs Android 9+ with Google Play services 24.22+. Off
Android, `isSupported` is `false`, create/get throw `PasskeyException`
(`restore-credential-unsupported`) and clear is a no-op.

## Install

```yaml
dependencies:
  dartnative_passkeys: ^0.1.0   # from dartpub.dev
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
import 'package:dartnative_passkeys/dartnative_passkeys.dart';

const auth = PasskeyAuthenticator();
```

**After sign-in** (and on launch when the user is signed in but no restore key
has been recorded yet), create the key and register it with your server:

```dart
final options = RegisterRequestType.fromJsonString(
  await server.restoreKeyCreationOptions(),   // PublicKeyCredentialCreationOptions
);
final registration = await auth.createRestoreCredential(options);
await server.registerRestoreKey(registration.toJsonString());
```

**On first launch on a new device**, before showing the login screen, retrieve
the key and sign in:

```dart
try {
  final options = AuthenticateRequestType.fromJsonString(
    await server.restoreKeyRequestOptions(),  // PublicKeyCredentialRequestOptions, allowCredentials empty
  );
  final assertion = await auth.getRestoreCredential(options);
  await server.signInWithRestoreKey(assertion.toJsonString());
} on PasskeyException catch (e) {
  switch (e.code) {
    case 'android-no-credential':             // nothing to restore
    case 'restore-credential-unsupported':    // old Android / Play services
      showLoginScreen();
    default:
      rethrow;
  }
}
```

**On sign-out**, delete the key so the next launch doesn't sign the user back
in:

```dart
await auth.clearRestoreCredential();
```

Keep a local "restore key created" flag so you don't call
`createRestoreCredential` on every launch, but keep that flag out of backed-up
storage, or the new device will believe it already has a key.

## Setup

Adding the dependency isn't enough. You also need to register your app's
signing fingerprints as allowed origins, serve a Digital Asset Links file
from your domain, and have your relying party accept an assertion whose
*user verified* flag is `false`.

That's also why there's no example app. A restore key needs a real relying
party, a domain whose asset-links file names your package, and a build signed
by a key you registered. None of that fits in a sample project: an example
would fail on first run or prove nothing.

So we wrote a tutorial that walks you through it:
**[Keep users signed in on their next phone](https://dartnative.com/tutorials/zero-tap-sign-in)**.
It has screenshots of the console pages and covers both signing fingerprints,
`apk-key-hash` origins, `assetlinks.json`, relying-party setup (Supabase is
the worked example) and device testing. Its first stage runs with no server,
so you can try the plugin on your hardware before configuring anything.

## Server notes

- Reuse your passkey registration and assertion endpoints; the cryptographic
  verification is identical. Tag restore keys in your database so they stay out
  of user-facing passkey lists, and allow several per user (one per device).
- Creation options: `challenge` and `user.id` as unpadded Base64URL,
  `rp.id` = your relying-party domain, `pubKeyCredParams` with `-7` (ES256) and
  `-257` (RS256).
- Request options: the user isn't known yet, so leave `allowCredentials` empty
  and identify the user from the assertion's `userHandle`. Retrieval shows no
  biometric or lock-screen prompt, so the assertion's *user verified* flag is
  `false`; accept that for restore keys.

## Android setup

Nothing to declare: the plugin bundles `androidx.credentials` 1.6.0 and its
Play services provider, and the restore flows need no permissions. Keep in
mind:

- **Android 9 (API 28)+ and Google Play services 24.22+.** Older devices fail
  with `restore-credential-unsupported` at call time.
- **One account per app.** The restore key is tied to your package name; apps
  that let users switch accounts should create it for the primary one.
- **Cloud backup needs** a signed-in Google Account, Android backup enabled and
  a screen lock. Without them the key is created locally and still transfers
  device to device (handled automatically).
- Phones, foldables and tablets only; no cross-category restore (Wear OS, TV,
  Auto).
- **Google Play's deadline.** Zero-Tap Sign-In is required from April 2027 for
  apps with user sign-in; apps that don't meet it risk losing full publishing
  capabilities and Play Store visibility.

> Android-only plugin. `isSupported` is `false` on every other platform, so you
> can call these methods unconditionally behind a single code path.

## Credits & license

Ported from
[`passkeys_android`](https://pub.dev/packages/passkeys_android) (BSD-3-Clause,
© 2023 Corbado GmbH). The Android Credential Manager calls and error mapping
are kept intact; the Flutter pigeon transport was reworked to FFI. Uses
[`passkeys_platform_interface`](https://pub.dev/packages/passkeys_platform_interface)
for its interface and request/response types. Google Play's requirement:
[Android Developers Blog, August 2026](https://android-developers.googleblog.com/2026/08/app-quality-memory-optimization-secure-onboarding.html);
the API:
[Restore Credentials](https://developer.android.com/identity/sign-in/restore-credentials).

First-party DartNative plugin, free to use in any DartNative app. Distributed
through [dartpub.dev](https://dartpub.dev); report issues on the plugin's page.
