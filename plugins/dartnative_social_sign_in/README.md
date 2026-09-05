# dartnative_social_sign_in

Social sign-in for DartNative — Google Sign-In on both platforms, plus native Sign in with Apple
on iOS. Backed by the platform's own auth flows (GoogleSignIn / Android Credential Manager and
`ASAuthorizationController`).

## Why you'll like it

- **The native sign-in sheets** — the real Google account picker and the system Sign in with
  Apple sheet, not a web view you have to babysit.
- **Familiar API** — `GoogleSignIn().signIn()` and `SignInWithApple.getAppleIDCredential(...)`,
  mirroring the packages you already know.
- **The tokens you need** — ID token and access token from Google, the authorization credential
  from Apple, ready to hand to your backend or Supabase.

## Highlights

- **`GoogleSignIn({serverClientId}).signIn()`** → a `GoogleSignInAccount` (email, displayName,
  `authentication.idToken` / `accessToken`), or `null` if canceled. **iOS and Android.**
- **`SignInWithApple.getAppleIDCredential({scopes, nonce})`** → an `AuthorizationCredentialAppleID`.
  **iOS only** — Apple provides no native Android SDK.

## Install

```yaml
dependencies:
  dartnative_social_sign_in: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

Register the plugin once, in `main()`:

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

**Google Sign-In** (iOS and Android)

```dart
import 'package:dartnative_social_sign_in/social_sign_in.dart';

final account = await GoogleSignIn(serverClientId: 'YOUR-WEB-CLIENT-ID').signIn();
if (account != null) {
  final idToken = account.authentication.idToken;   // send to your backend
  print('Signed in as ${account.email}');
}
```

**Sign in with Apple** (iOS only)

```dart
final credential = await SignInWithApple.getAppleIDCredential(
  scopes: [
    AppleIDAuthorizationScopes.email,
    AppleIDAuthorizationScopes.fullName,
  ],
);
// credential.identityToken / credential.authorizationCode → your backend
```

## Platform setup

### iOS

**Google Sign-In:**

1. Add `GoogleService-Info.plist` to your app target — the iOS client ID is read
   from its `CLIENT_ID` key. The plist only contains `CLIENT_ID` /
   `REVERSED_CLIENT_ID` after the iOS OAuth client exists — enable the Google
   provider in Firebase Authentication (or create the iOS OAuth client in the
   Cloud console) and re-download the plist. Alternatively set `GIDClientID`
   directly in `Info.plist` — it takes precedence over the plist.
2. Add your app's `REVERSED_CLIENT_ID` (from that plist) as a URL scheme in
   `Info.plist` — it's how the OAuth redirect returns to your app.

If no client ID can be resolved, `signIn()` completes with an error result
explaining the missing configuration (it never crashes).

**Sign in with Apple:** enable the **Sign in with Apple** capability for your app target (adds
the `com.apple.developer.applesignin` entitlement, referenced from the target's
`CODE_SIGN_ENTITLEMENTS` build setting). Without it authorization fails with **error 1000**.
The capability needs an explicit App ID, so use a bundle identifier unique to your team.

### Android

**Google Sign-In** uses the Android Credential Manager — no config file needed, but two
OAuth clients must exist in your Google Cloud project:

1. A **web** client — pass its ID as `serverClientId` in code (the ID token is addressed to
   your server, which is what verifies it).
2. An **Android** client matching your app's package name and **SHA-1 signing fingerprint**
   (`./gradlew signingReport` prints the debug SHA-1; in Firebase: Project settings → your
   Android app → *Add fingerprint*). Without it Google recognizes no app and issues no
   credentials.

**Sign in with Apple** is not available on Android (Apple ships no native Android SDK).

## Credits & license

Based on [`google_sign_in`](https://pub.dev/packages/google_sign_in) (Flutter Authors, BSD-3) and
[`sign_in_with_apple`](https://pub.dev/packages/sign_in_with_apple) (About You GmbH, MIT),
reworked to run natively on DartNative.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
