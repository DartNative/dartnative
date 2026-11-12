# dartnative_supabase

[Supabase](https://supabase.com) for DartNative — auth, Postgres, storage, and realtime through
the pure-Dart `supabase` client, with the same `Supabase.initialize(...)` /
`Supabase.instance.client` API as `supabase_flutter`. No platform channels. iOS and Android.

## Why you'll like it

- **The real Supabase client** — auth, database, storage, and realtime, all from Dart.
- **Familiar API** — `Supabase.initialize(...)` then `Supabase.instance.client`, like `supabase_flutter`.
- **Pure Dart** — no platform channels, no native code.

## Highlights

- **`Supabase.initialize({url, anonKey})`** — boot the client once at startup.
- **`Supabase.instance.client`** — the `SupabaseClient`: `.from(...)`, `.auth`, `.storage`, `.realtime`.

## Install

```yaml
dependencies:
  dartnative_supabase: ^1.0.1   # from dartpub.dev
```

```bash
dn pub get
```

## Quick look

```dart
import 'package:dartnative_supabase/dartnative_supabase.dart';

await Supabase.initialize(
  url: 'https://YOUR-PROJECT.supabase.co',
  anonKey: 'YOUR-ANON-KEY',
);

final supabase = Supabase.instance.client;

final todos = await supabase.from('todos').select();
await supabase.auth.signInWithPassword(email: email, password: password);
```

## Platform setup

**None** — just add the dependency to your `pubspec.yaml` (above) and `dn pub get`. No iOS or
Android configuration is required.

## Passkeys and zero-tap sign-in

`supabase.auth.passkey` is Supabase's WebAuthn API: `startRegistration` and
`verifyRegistration` to add a passkey, `startAuthentication` and
`verifyAuthentication` to sign in with one. It arrives with `gotrue` 2.27.2 and
is marked experimental upstream.

It is **off until you enable it per project**, under Authentication →
Configuration → Passkeys in the Supabase dashboard, where you also set the
relying-party ID and origins. Until then every call returns HTTP 404 with
`code: passkey_disabled`.

The same API backs Android's restore credentials, which sign a user back in
silently on their next phone, which Google Play requires from April 2027 for
apps with user sign-in. Supabase stores and verifies restore keys as ordinary
passkeys, so no extra server work is needed; pair this plugin with
[`dartnative_passkeys`](https://dartpub.dev/packages/dartnative_passkeys) for
the device half.

**[Keep users signed in on their next phone](https://dartnative.com/tutorials/zero-tap-sign-in)**
covers the dashboard settings, the Digital Asset Links file your domain has to
serve, and the signing fingerprints that go in the origins field.

## Credits & license

A DartNative port of
[`supabase_flutter`](https://github.com/supabase/supabase-flutter), built on the pure-Dart
[`supabase`](https://pub.dev/packages/supabase) package (MIT).

First-party DartNative plugin, free to use in any DartNative app. Distributed
through [dartpub.dev](https://dartpub.dev); report issues on the plugin's page.
