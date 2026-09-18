# Localization

Localizing an app means showing its text in the user's own language. In DartNative you do it the same way as in Flutter. You keep your strings in one file per language, run a generator that turns those files into a Dart class, and call that class from your widgets instead of writing text directly.

The files are ARB files, which are JSON. The generator is the `dartnative_intl` plugin, a drop-in replacement for `intl_utils` whose output imports `dartnative` instead of Flutter. The class it writes is called `S` by default, so a heading becomes `S().app_title` and the right translation comes out.

```
l10n/intl_en.arb  ──► dn run-tool  ──► lib/generated/l10n.dart  ──► S().greeting('Ada')
```

Every snippet here comes from a working app, [`tutorials/localization`](../tutorials/localization), which runs with `dn pub get && dn run`. If anything on this page is unclear, read that app instead. Its `l10n/` folder has four translated ARB files, `lib/state/language_provider.dart` has the provider shown below, `lib/main.dart` has the startup order, and `lib/screens/localization_demo.dart` has a screen that reads strings, plurals and dates. The step-by-step version is at [dartnative.com/tutorials/localization](https://dartnative.com/tutorials/localization).

---

## Setup

```yaml
dependencies:
  dartnative_shared_preferences: ^1.0.0   # to remember the chosen language
  intl: ^0.20.2                           # formatting, and the message catalogue

dev_dependencies:
  dartnative_intl: ^1.0.1                 # the generator

flutter_intl:
  enabled: true
  arb_dir: l10n
  output_dir: lib/generated
  class_name: S
  main_locale: en
```

The `flutter_intl:` block takes the same keys as `intl_utils`, so a project moving from Flutter keeps its configuration. Put one ARB file per language in `l10n/`, named `intl_<code>.arb`.

---

## The ARB files

The file named by `main_locale` is the source of truth. Every key in it becomes a method on `S`, and a key prefixed with `@` describes the one above it.

```json
{
  "@@locale": "en",
  "app_title": "Localization",
  "greeting": "Hello, {name}!",
  "@greeting": {
    "placeholders": { "name": {} }
  },
  "messages_count": "{count, plural, =0{No messages} =1{One message} other{{count} messages}}",
  "@messages_count": {
    "placeholders": { "count": {} }
  },
  "today_is": "Today is {date}.",
  "@today_is": {
    "placeholders": {
      "date": { "type": "DateTime", "format": "yMMMMd" }
    }
  }
}
```

Translations are the same file with the values replaced. Only the main locale carries the `@` blocks; the other files inherit them.

| In the ARB | Generated | Called as |
|---|---|---|
| A plain string | `String get app_title` | `S().app_title` |
| A placeholder | `String greeting(Object name)` | `S().greeting('Ada')` |
| A plural | `String messages_count(num count)` | `S().messages_count(5)` |
| A typed placeholder | `String today_is(DateTime date)` | `S().today_is(DateTime.now())` |

Each language declares the plural cases it needs. English has two, Arabic has six, and the generator reads whatever each file provides.

Four complete ARB files, including a right-to-left one, are in [`tutorials/localization/l10n/`](../tutorials/localization/l10n).

---

## Generating

```sh
dn run-tool dartnative_intl:generate
```

This writes `lib/generated/l10n.dart` and one message file per locale. They are rewritten on every run, so never edit them by hand, and re-run after every change to an ARB file.

Use `dn run-tool`, not `dart run`. Plain pub looks for packages on pub.dev and the DartNative packages are not there, and the generator ships as a compiled tool inside the plugin rather than as source. You need `dartnative_intl` 1.0.1 or newer. An older version reports that the plugin provides no commands to run.

---

## Startup

The order in `main()` decides whether the app opens in the right language.

```dart
Future<void> main() async {
  DartNativePluginRegistrant.registerAll();

  // Whatever remembers the choice between launches.
  prefs = await SharedPreferences.getInstance();

  // Restore the language and load its messages.
  await languageProvider.initialize(prefs);

  // Point the generated code at the messages that were just loaded.
  Localizations.setResolver((_, __) => S.current);

  runApp(const MyApp());
}
```

`Localizations.setResolver` is what `S()` calls to find the loaded messages, so without it the first screen has nothing to read.

Do not call `S.load` again after this. A second call overrides the language you just restored, on every launch. The symptom is misleading: the app always opens in English, but switching languages inside the app works fine.

The working version is [`tutorials/localization/lib/main.dart`](../tutorials/localization/lib/main.dart).

---

## Holding the current language

A small provider holds the current language, saves it, and loads it. Three things in it need explaining, because each one fails in a way that is hard to trace back.

These are the imports it needs. `Locale` comes from the plugin rather than from Flutter, and the two `intl` imports are separate because one carries the formatting API and the other the symbol data:

```dart
import 'dart:convert';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_intl/dartnative_intl.dart' show Locale;
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:intl/date_symbol_data_local.dart';

import '../generated/l10n.dart';
```

One entry per language you translated. The name is written in the language itself, so a reader who does not understand the current one can still find their own:

```dart
class AppLanguage {
  const AppLanguage({
    required this.name,
    required this.languageCode,
    this.countryCode,
  });

  final String name;
  final String languageCode;
  final String? countryCode;
}

const supportedAppLanguages = <AppLanguage>[
  AppLanguage(name: 'English', languageCode: 'en'),
  AppLanguage(name: 'Italiano', languageCode: 'it'),
  AppLanguage(name: 'Español', languageCode: 'es'),
  AppLanguage(name: 'العربية', languageCode: 'ar'),
];

const _fallback = AppLanguage(name: 'English', languageCode: 'en');
```

```dart
class LanguageProvider {
  final Signal<AppLanguage> _language = signal(_fallback);
  Signal<AppLanguage> get languageSignal => _language;

  Future<void> initialize(SharedPreferences prefs) async {
    final saved = prefs.getString(kPrefKeyLanguage);
    _language.value = _resolve(saved);
    if (saved == null || saved.isEmpty) {
      await _persist(prefs, _language.value);
    }
    await _load(locale);
  }

  Future<void> changeLanguage(SharedPreferences prefs, AppLanguage lang) async {
    if (lang == _language.value) return;
    await _load(Locale(lang.languageCode, lang.countryCode));
    _language.value = lang;
    await _persist(prefs, lang);
  }

  Future<void> _load(Locale locale) async {
    await initializeDateFormatting(locale.languageCode);
    await S.load(locale);
  }
}
```

**Resolving the language on launch** takes three steps: use the saved language if you still ship it, otherwise the device's language if you translated it, otherwise your fallback. Check the saved value against the list you ship. If you drop a language later, anyone who had chosen it would otherwise be stuck on a code that no longer exists.

The device's own language comes from `Intl.systemLocale`, which reports it as the platform does (`en_US`, `ar`). Take the language part alone so a device set to Brazilian Portuguese still finds your `pt` file. `dart:ui` is not available in a DartNative app, so this is the portable read:

```dart
AppLanguage _resolve(String? saved) {
  if (saved != null && saved.isNotEmpty) {
    final stored = AppLanguage.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    final match = supportedAppLanguages
        .where((l) => l.languageCode == stored.languageCode);
    if (match.isNotEmpty) return match.first;
  }
  final deviceCode = Intl.systemLocale.split(RegExp('[_-]')).first;
  final device = supportedAppLanguages.where((l) => l.languageCode == deviceCode);
  return device.isNotEmpty ? device.first : _fallback;
}

Future<void> _persist(SharedPreferences prefs, AppLanguage language) =>
    prefs.setString(kPrefKeyLanguage, jsonEncode(language.toJson()));

Locale get locale =>
    Locale(_language.value.languageCode, _language.value.countryCode);
```

**Loading before notifying watchers** is why `changeLanguage` awaits `_load` before it sets the signal. If you set the signal first, every watching screen rebuilds while the old messages are still loaded, so they show the previous language until something else triggers another rebuild. It looks like a caching problem, but it is just the wrong order.

The whole provider, with the parts omitted here, is [`tutorials/localization/lib/state/language_provider.dart`](../tutorials/localization/lib/state/language_provider.dart).

**Loading the date symbols with the messages** is why `_load` does two things. `S().today_is(...)` builds a `DateFormat` underneath, and that throws unless the locale's symbol data is loaded first:

```
LocaleDataException: Locale data has not been initialized,
call initializeDateFormatting(<locale>).
```

`initializeDateFormatting` comes from `package:intl/date_symbol_data_local.dart` and is safe to call more than once. Keep it next to `S.load` so the messages and the formatting data always agree on the current language.

---

## Reading the strings

```dart
Widget build(BuildContext context) {
  final current = languageProvider.languageSignal.watch(context);

  return Scaffold(
    appBar: AppBar(title: Text(S().app_title)),
    body: Column(children: [
      Text(S().greeting('Ada')),
      Text(S().messages_count(_count)),
      Text(S().today_is(DateTime.now())),
    ]),
  );
}
```

Watching the signal is what makes the screen re-read every `S()` call when the language changes. Without it the text is fetched once and stays as it was.

A picker is an ordinary list; the only part that matters is calling `changeLanguage` and letting it await:

```dart
for (final language in supportedAppLanguages)
  GestureDetector(
    onTap: () => languageProvider.changeLanguage(prefs, language),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(language.name),
        if (language == current) const Icon(CupertinoIcons.checkmark, size: 18),
      ],
    ),
  ),
```

---

## Right-to-left layout

DartNative reads the layout direction from the platform once, at startup: the app's interface layout direction on iOS, the configuration's on Android. Both stay left-to-right unless the app itself declares a right-to-left language.

So picking a right-to-left language inside your app translates the text without mirroring the layout. For the layout to mirror, the operating system has to consider the app right-to-left: a per-app language change on Android, a device language change on iOS. Native apps work the same way. `Directionality.of(context)` reports the resolved direction, and wrapping a subtree in `Directionality` overrides it locally.

---

## Adding a language

Copy your main ARB file to `intl_<code>.arb` and translate the values, add the language to the list your picker shows, then run the generator again. It picks the new file up on its own, and the delegate's `supportedLocales` grows with it.

---

## When something looks wrong

| What you see | What it means |
|---|---|
| `dartnative_intl does not provide any commands to run` | The resolved version predates 1.0.1. Raise the constraint and run `dn pub get`. |
| `could not find package dartnative_intl at https://pub.dev` | The command was `dart run`. Use `dn run-tool`. |
| `LocaleDataException: Locale data has not been initialized` | `initializeDateFormatting` was never called for that locale. |
| The app always opens in English, but switching works | Something calls `S.load` after startup and overrides the restored language. |
| A rebuild briefly shows the previous language | The signal was set before the new messages finished loading. |
| Text is translated but the layout does not mirror | Expected: layout direction comes from the platform, not from a picker inside the app. |
