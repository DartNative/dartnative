# dartnative_keys

Load your app's client config and **publishable** API keys from one `.env`-style
file — at runtime, on iOS and Android. The `flutter_dotenv` you can actually use
in DartNative. iOS and Android.

## Why you'll like it

- **One place** — keep every client key in a single gitignored `.dnkeys` file (`.env` syntax), instead of scattering them across `Info.plist`, `xcconfig`, the manifest and `local.properties`.
- **Works in DartNative** — reads the bundled file **natively** on both platforms (iOS app bundle, Android `AssetManager`), where `flutter_dotenv` / `rootBundle` simply don't run.
- **No leaks** — gitignore `.dnkeys`, commit a `.dnkeys.example`; real keys never reach source control.
- **Tiny, familiar API** — `await DnKeys.load()`, then `DnKeys.get('KEY')`.

## Highlights

- **`DnKeys.load({String file = '.dnkeys'})`** — parse the bundled `.env`-style file once, at startup.
- **`DnKeys.get('KEY')`** → `String?` — nullable lookup, like `SharedPreferences.getString`.
- **`DnKeys.containsKey('KEY')`** → `bool` · **`DnKeys.all`** → `Map<String, String>`.

> ⚠️ **Not a secret store.** Anything shipped in an app is recoverable from it —
> a bundled `.dnkeys`, `--dart-define`, `Info.plist`, all of it. Use `dartnative_keys`
> **only for publishable / restricted keys** (RevenueCat *public* `appl_…`/`goog_…`,
> Google Maps, Supabase *anon*, Stripe *publishable*). **Secret / billing keys**
> (Stripe *secret*, LLM provider keys, DB credentials) must live **behind your
> backend** — no client-side mechanism makes them safe. This plugin's value is
> *one place + nothing leaks to GitHub*, not secrecy.

## Install

```yaml
dependencies:
  dartnative_keys: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  await DnKeys.load();               // before you read any key
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_keys/dartnative_keys.dart';

await DnKeys.load();                                   // reads `.dnkeys` from the app bundle

final rcKey = DnKeys.get('REVENUECAT_IOS_API_KEY')!;   // required → `!` throws if missing
final base  = DnKeys.get('API_BASE_URL') ?? 'https://api.example.com';

if (DnKeys.containsKey('FEATURE_X')) { /* … */ }
final everything = DnKeys.all;                         // Map<String, String>
```

## Setting up your keys

`dartnative_keys` reads a plain `.env`-style file that you **bundle as an asset**.

1. **Create `.dnkeys`** at your app's root (same folder as `pubspec.yaml`):

   ```env
   # .dnkeys  ← gitignored; never commit real keys
   REVENUECAT_IOS_API_KEY=appl_xxxxxxxxxxxxxxxx
   REVENUECAT_ANDROID_API_KEY=goog_xxxxxxxxxxxxxxxx
   API_BASE_URL=https://api.example.com
   ```

2. **Bundle it** — add it to your `pubspec.yaml` assets:

   ```yaml
   flutter:
     assets:
       - .dnkeys
   ```

3. **Keep it out of git** — add to `.gitignore` and commit a template instead:

   ```gitignore
   # .gitignore
   .dnkeys
   ```

   ```env
   # .dnkeys.example  ← committed; documents the required keys (no values)
   REVENUECAT_IOS_API_KEY=
   REVENUECAT_ANDROID_API_KEY=
   API_BASE_URL=
   ```

Syntax is the usual `.env`: `KEY=value` per line, `#` comments, blank lines ignored,
optional surrounding quotes are stripped.

## Platform setup

### iOS

No native setup required.

### Android

No native setup required — the plugin reads the bundled asset via the native
`AssetManager` for you.

## Example

The [`example/`](./example) app loads a `.dnkeys` and prints a couple of values —
copy its `.dnkeys.example` and pubspec wiring to get started.

## Credits & license

Inspired by the `.env` convention popularised by
[`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv), reimplemented so it
works in DartNative (no Flutter engine / `rootBundle`). Reading is backed by the
DartNative framework (iOS app bundle / Android `AssetManager`).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
