# Sign in with Apple & Google

The finished code for the [sign-in tutorial](https://dartnative.com/tutorials/social-sign-in):
a sign-in screen using `dartnative_social_sign_in` — the real
ASAuthorizationController sheet on iOS and GIDSignIn / Credential Manager
for Google — over FFI, with each provider's status, profile fields, and
ID token shown in a result card.

Configuration required before running:
- **Apple**: the "Sign in with Apple" capability — already wired in this
  tutorial's committed shell (`ios/Runner/Runner.entitlements`, referenced
  from the target's `CODE_SIGN_ENTITLEMENTS`). In your own app add it via
  Xcode: Runner target → Signing & Capabilities → **+ Capability → Sign in
  with Apple**. Without it the request fails with error 1000. The
  capability needs an explicit App ID, so the shell ships the unique
  bundle identifier `com.dartnative.tutorials.socialSignIn` — change it if
  registration reports it taken.
- **Google (iOS)**: `GoogleService-Info.plist` + the `REVERSED_CLIENT_ID`
  URL scheme.
- **Google (Android)**: the WEB OAuth 2.0 client ID —
  `dn run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`
  — plus an Android OAuth client registered with your package name and
  SHA-1 fingerprint (`./gradlew signingReport`; in Firebase: Project
  settings → *Add fingerprint*).

Missing configuration is handled gracefully — the buttons still show, and
auth errors are displayed inline.

```sh
dn pub get
dn run
```

The screen at [`lib/screens/social_sign_in_demo.dart`](lib/screens/social_sign_in_demo.dart)
is a byte-identical copy of the DartNative playground's social sign-in
demo ([`lib/screens/home/demo_ui.dart`](lib/screens/home/demo_ui.dart) is
the playground's shared UI kit, also verbatim; the Apple/Google logos
under `assets/` come from the playground too). When the playground demo
improves, this tutorial updates by copying the files again — only the
thin [`lib/main.dart`](lib/main.dart) launcher is tutorial-specific.
Verified against dartnative `^1.0.0`.
