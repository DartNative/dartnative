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
  dartnative_supabase: ^1.0.0   # from dartpub.dev
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

## Credits & license

A DartNative port of
[`supabase_flutter`](https://github.com/supabase/supabase-flutter), built on the pure-Dart
[`supabase`](https://pub.dev/packages/supabase) package (MIT).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
