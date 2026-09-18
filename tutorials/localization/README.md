# Localization, the way a shipping app does it

The finished code for the [localization tutorial](https://dartnative.com/tutorials/localization):
one screen in four languages, a picker that switches the app live, and a
choice that survives a restart. This is the pattern Gee uses in production.

```sh
dn pub get
dn run
```

## How it fits together

- [`l10n/`](l10n/) — one ARB file per language. `intl_en.arb` is the source
  of truth: every key you add there gets a method on `S`.
- [`lib/generated/`](lib/generated/) — written by
  `dart run dartnative_intl:generate` from the ARB files. Never edit by
  hand; regenerate after every change to a `.arb`.
- [`lib/state/language_provider.dart`](lib/state/language_provider.dart) —
  the current language, saved in SharedPreferences and restored on the next
  launch. Falls back to the device's language on first run.
- [`lib/main.dart`](lib/main.dart) — the startup order that matters: open
  preferences, restore the language, then `runApp`.
- [`lib/screens/localization_demo.dart`](lib/screens/localization_demo.dart)
  — the screen: placeholders, plurals, and dates and money formatted the
  way each language writes them.

## Adding a language

1. Copy `l10n/intl_en.arb` to `l10n/intl_<code>.arb` and translate the
   values.
2. Add an `AppLanguage` entry in `lib/state/language_provider.dart`.
3. Run `dart run dartnative_intl:generate`.

Verified against dartnative `^1.0.0`.
