# dartnative_firebase

**The notifications + monitoring slice of Firebase for DartNative** — Firebase Core,
Crashlytics, and Cloud Messaging, on top of the native Firebase SDKs. iOS and Android.

> **This is a focused subset, not the full Firebase suite.** It focuses on the Firebase services
> that *must* run through the native SDKs — crash **monitoring** and push **notifications** —
> rather than the backend/data services (Firestore, Auth, Storage, …), which Dart can already
> reach directly over their REST/gRPC APIs. See [Scope](#scope) for details.

## Why this plugin exists

Push **notifications** (Cloud Messaging) and crash/error **monitoring** (Crashlytics) are two
Firebase services almost every production app reaches for — and they're valuable no matter how
the rest of the app is built. Whether your backend is Firebase, Supabase, your own API, or you
have no backend at all, you'll still want FCM to reach your users and Crashlytics to tell you
when something breaks. That's why these two are bundled together here:

- **Useful on their own.** Notifications and monitoring are cross-cutting concerns that sit apart
  from your data layer, so they make sense as a standalone plugin you can drop into any app.
- **They need native code.** FCM relies on APNs / the native FCM service to receive a push, and
  Crashlytics relies on native signal handlers and the NDK to capture a crash — neither can be
  implemented in pure Dart, which is exactly what a native DartNative plugin is for.
- **Firebase's other services are already reachable from Dart.** Firestore, Auth, Storage and
  friends expose REST/gRPC APIs you can call directly from Dart, so they work without a native
  wrapper (see [Scope](#scope)).

**Using Firebase as your backend? Great — this plugin slots right in alongside it**, adding the
push and crash-reporting pieces that benefit from native support. It simply doesn't *require* the
rest of Firebase, so it's equally at home in an app built on anything else.

## Scope

`dartnative_firebase` covers the device-side Firebase services that genuinely require the
native SDKs:

| Included | What you get |
|---|---|
| **Firebase Core** | `Firebase.initializeApp()` from your GoogleService config |
| **Crashlytics** | crash & error monitoring — `recordError`, `log`, custom keys, user id |
| **Cloud Messaging (FCM)** | push — foreground, tap, background & killed-app delivery, topics |

**On the name.** `dartnative_firebase` stays scoped to the notifications + monitoring bundle — it
doesn't claim the rest of the Firebase namespace, and it doesn't lock anyone out. Any Firebase
service can be packaged independently of this plugin, by anyone, with no dependency on (or change
to) it — a data service like Firestore, Auth, or Storage, or even Messaging and Crashlytics
themselves — each free to live in its own package (e.g. `dartnative_firebase_firestore`) while this
one stays focused on push + crash.

## Why you'll like it

- **The native Firebase SDKs** — your app talks to the same Firebase Core, Crashlytics, and
  Messaging SDKs the rest of the ecosystem uses, straight from Dart.
- **Crash reporting that just works** — record errors, logs, and custom keys; reports land in
  your Firebase console.
- **Push out of the box** — receive FCM messages, handle taps that open your app, and manage
  topic subscriptions.

## Highlights

- **`Firebase.initializeApp()`** — boot the default app from your GoogleService config.
- **`FirebaseCrashlytics.instance`** — `recordError`, `recordFatalError`, `log`,
  `setUserIdentifier`, `setCustomKey`, `setCrashlyticsCollectionEnabled`.
- **`FirebaseMessaging`** — `onMessage` / `onMessageOpenedApp` streams, `getInitialMessage`,
  `subscribeToTopic` / `unsubscribeFromTopic`.

## Install

```yaml
dependencies:
  dartnative_firebase: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

Register the plugin once, in `main()`, and initialize Firebase before using any service:

```dart
void main() async {
  DartNativePluginRegistrant.registerAll();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

## Quick look

**Crash reporting**

```dart
import 'package:dartnative_firebase/dartnative_firebase.dart';

try {
  riskyWork();
} catch (e, stack) {
  await FirebaseCrashlytics.instance.recordError(e, stack);
}

await FirebaseCrashlytics.instance.setUserIdentifier('user-123');
await FirebaseCrashlytics.instance.log('checkout started');
```

**Cloud Messaging**

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // a message arrived while the app was in the foreground
});

// the message that launched the app from a notification tap, if any
final initial = await FirebaseMessaging.getInitialMessage();

await FirebaseMessaging.subscribeToTopic('news');
```

## Platform setup

Firebase needs the config file Google generates for your app, on each platform.

### iOS

Requires **iOS 15.0+** — the Firebase SDKs' minimum deployment target. Set
`platform :ios, '15.0'` in your Podfile (and the Xcode project's deployment
target) if your app targets lower.

1. Push needs an explicit App ID, so set a bundle identifier unique to your team —
   generic `com.example.*` IDs are already claimed and fail team registration.
2. Register an iOS app with that bundle ID in your Firebase project and add its
   `GoogleService-Info.plist` to the app target — `Firebase.initializeApp()` reads it.
3. Add the **Push Notifications** capability (Xcode: Signing & Capabilities → + Capability →
   Push Notifications). By hand that's a `Runner.entitlements` file containing
   `aps-environment` = `development`, referenced from the target's `CODE_SIGN_ENTITLEMENTS`
   build setting. Without it APNs registration silently never completes and the FCM token
   request **times out**.
4. For background message delivery, also enable **Background Modes → Remote notifications**.
5. Upload an APNs auth key in the Firebase console (Project settings → Cloud Messaging), and
   test on a physical device — APNs doesn't reach simulators.

### Android

1. Register an Android app (your `applicationId`) in your Firebase project and put its
   `google-services.json` in `android/app/`. The file is read at **build** time, not
   runtime — on its own it does nothing.
2. Apply the **Google Services** Gradle plugin, which turns that file into the resources
   Firebase reads at startup. Two files:

   `android/settings.gradle.kts` — declare the versions:

   ```kotlin
   plugins {
       // …existing entries…
       id("com.google.gms.google-services") version "4.4.2" apply false
       id("com.google.firebase.crashlytics") version "3.0.2" apply false
   }
   ```

   `android/app/build.gradle.kts` — apply them:

   ```kotlin
   plugins {
       // …existing entries…
       id("com.google.gms.google-services")
       id("com.google.firebase.crashlytics")
   }
   ```

   The Crashlytics plugin injects the build-id resource its startup code needs — without
   it `firebase-crashlytics` can crash the app on launch.

Missing step 2 shows up at launch as
`FirebaseApp could not initialize: no default options` (and FCM setup failing with
"Default FirebaseApp is not initialized") — the log names both requirements.

## Example

The [`example/`](./example) app initializes Firebase, reports a test error, and receives an FCM
message — borrow from it freely.

## Migrating from FlutterFire

The public API deliberately mirrors the FlutterFire packages this plugin replaces
(`firebase_core` / `firebase_crashlytics` / `firebase_messaging`), so imports and most call
sites port unchanged: swap the dependencies in `pubspec.yaml`, follow
[Platform setup](#platform-setup) above, and keep your existing Firebase project and config
files — they work as they are.

## Credits & license

Ports of [`firebase_core`](https://pub.dev/packages/firebase_core),
[`firebase_crashlytics`](https://pub.dev/packages/firebase_crashlytics), and
[`firebase_messaging`](https://pub.dev/packages/firebase_messaging) (FlutterFire, BSD-3-Clause),
running on top of the native Firebase SDKs.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
