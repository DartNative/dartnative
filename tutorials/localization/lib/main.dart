/// DartNative tutorial — app localization.
///
/// Four languages from ARB files, a picker that switches the app live, and
/// a choice that survives a restart. The pattern is the one Gee uses in
/// production: `dartnative_intl` generates the message class from the ARB
/// files, a provider owns the current language, and every screen reads its
/// text through `S()`.
///
/// The one rule that matters at startup: load the language BEFORE `runApp`,
/// and never load a second one after it. An unconditional `S.load(...)` here
/// would override the language the provider just restored, and the app would
/// open in the wrong language on every launch.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_intl/dartnative_intl.dart' show Localizations;
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

import 'dartnative_plugin_registrant.dart';
import 'generated/l10n.dart';
import 'screens/localization_demo.dart';
import 'state/language_provider.dart';

/// The app's single language provider.
final languageProvider = LanguageProvider();

/// SharedPreferences, opened once at startup.
late final SharedPreferences prefs;

Future<void> main() async {
  DartNativePluginRegistrant.registerAll();

  // 1. Preferences first: the saved language lives here.
  prefs = await SharedPreferences.getInstance();

  // 2. Restore the language and load its messages. After this, S() answers
  //    in the right language.
  await languageProvider.initialize(prefs);

  // 3. Tell the generated code where to find the loaded messages. S() calls
  //    this resolver, so it must be set before the first screen builds.
  Localizations.setResolver((_, __) => S.current);

  runApp(const LocalizationDemo());
}
