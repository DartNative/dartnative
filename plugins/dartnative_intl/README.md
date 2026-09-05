# dartnative_intl

ARB-to-Dart localisation code generator for DartNative apps — a drop-in replacement for
`intl_utils`. One command, same config, generated code that's pure DartNative.

## Why you'll like it

- **Pure DartNative output** — generated files import `dartnative`; your l10n layer has
  no external SDK dependency.
- **Same config** — the `flutter_intl:` block in `pubspec.yaml` works exactly as with
  `intl_utils`; nothing to learn.
- **Same generated API** — `S.of(context)` and `S.delegate` are identical
  (`supportedLocales` lives on the delegate: `S.delegate.supportedLocales`);
  existing app code needs no changes beyond swapping the dependency.
- **Familiar** — `dart run dartnative_intl:generate`, like `intl_utils`.

## Highlights

- **`dart run dartnative_intl:generate`** — reads your ARB files and generates the full
  l10n class tree.
- **`Locale`, `LocalizationsDelegate`, `Localizations`** — pure-Dart runtime shims
  included so generated code compiles with no extra dependencies.
- **Localizely support** — optional download step pulls ARBs from Localizely before
  generating (same as upstream).

## Install

```yaml
dependencies:
  dartnative_intl: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

Configure in `pubspec.yaml` (same keys as `intl_utils`):

```yaml
flutter_intl:
  enabled: true
  arb_dir: lib/l10n
  output_dir: lib/generated
  main_locale: en
```

## Quick look

Add your ARB files:

```
lib/l10n/intl_en.arb
lib/l10n/intl_pt.arb
```

Run the generator:

```bash
dart run dartnative_intl:generate
```

Use the generated class in your app:

```dart
import 'package:dartnative_intl/dartnative_intl.dart';

// Register the resolver once at startup, before runApp()
Localizations.setResolver((context, type) => myLocalizationLookup(context, type));

// Then anywhere in your widget tree
final label = S.of(context).welcomeMessage;
```

Load a locale (there is no `localizationsDelegates` list to wire up — the
resolver above is the whole hookup):

```dart
await S.delegate.load(const Locale('fr'));

// The locales the generated delegate knows about:
final locales = S.delegate.supportedLocales;
```

## Credits & license

Adapted from
[`intl_utils`](https://pub.dev/packages/intl_utils)
(MIT), reworked to use DartNative imports.

Distributed via [dartpub.dev](https://dartpub.dev) — file issues on the plugin's page.
