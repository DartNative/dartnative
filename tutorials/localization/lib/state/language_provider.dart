/// Which language the app is in, and how that choice survives a restart.
///
/// The pattern is the one a shipping DartNative app uses: a list of the
/// languages you translated, a saved choice in SharedPreferences, and a
/// fallback to the device's own language on first launch.
library;

import 'dart:convert';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_intl/dartnative_intl.dart' show Locale;
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';
import 'package:intl/intl.dart' show Intl;

import '../generated/l10n.dart';

/// Key under which the chosen language is stored.
const String kPrefKeyLanguage = 'app_language';

/// One language the app is translated into: what to show in the picker, and
/// the codes that identify it to `intl`.
class AppLanguage {
  const AppLanguage({
    required this.name,
    required this.languageCode,
    this.countryCode,
  });

  /// Written in the language itself, so a reader who does not know the
  /// current language can still find their own.
  final String name;
  final String languageCode;
  final String? countryCode;

  factory AppLanguage.fromJson(Map<String, dynamic> json) => AppLanguage(
        name: json['name'] as String,
        languageCode: json['language_code'] as String,
        countryCode: json['country_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'language_code': languageCode,
        'country_code': countryCode,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguage &&
          languageCode == other.languageCode &&
          countryCode == other.countryCode;

  @override
  int get hashCode => Object.hash(languageCode, countryCode);
}

/// The languages this app ships. To add one: add the entry here and an
/// `intl_<code>.arb` beside the others in `l10n/`, then regenerate.
const supportedAppLanguages = <AppLanguage>[
  AppLanguage(name: 'English', languageCode: 'en'),
  AppLanguage(name: 'Italiano', languageCode: 'it'),
  AppLanguage(name: 'Español', languageCode: 'es'),
  AppLanguage(name: 'العربية', languageCode: 'ar'),
];

const _fallback = AppLanguage(name: 'English', languageCode: 'en');

/// Holds the current language and loads its messages.
///
/// The signal is what screens watch: changing it rebuilds them, and by then
/// the new messages are already loaded.
class LanguageProvider {
  final Signal<AppLanguage> _language = signal(_fallback);

  Signal<AppLanguage> get languageSignal => _language;
  AppLanguage get language => _language.value;

  Locale get locale =>
      Locale(_language.value.languageCode, _language.value.countryCode);

  /// Call once at startup, after SharedPreferences is ready and before
  /// `runApp`. Restores the saved language, or picks the device's own the
  /// first time the app runs.
  Future<void> initialize(SharedPreferences prefs) async {
    final saved = prefs.getString(kPrefKeyLanguage);
    _language.value = _resolve(saved);
    if (saved == null || saved.isEmpty) {
      await _persist(prefs, _language.value);
    }
    await S.load(locale);
  }

  /// Switches language: loads the messages first, then tells the screens.
  ///
  /// The order matters. Setting the signal first rebuilds every watching
  /// screen while the old messages are still current, so that rebuild
  /// renders the previous language and only a later, unrelated rebuild
  /// corrects it.
  Future<void> changeLanguage(
    SharedPreferences prefs,
    AppLanguage language,
  ) async {
    if (language == _language.value) return;
    await S.load(Locale(language.languageCode, language.countryCode));
    _language.value = language;
    await _persist(prefs, language);
  }

  Future<void> _persist(SharedPreferences prefs, AppLanguage language) =>
      prefs.setString(kPrefKeyLanguage, jsonEncode(language.toJson()));

  /// The saved language if it is still one we ship, else the device's
  /// language if we translated it, else English.
  AppLanguage _resolve(String? saved) {
    if (saved != null && saved.isNotEmpty) {
      final stored =
          AppLanguage.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      final match = supportedAppLanguages
          .where((l) => l.languageCode == stored.languageCode);
      if (match.isNotEmpty) return match.first;
    }
    // `Intl.systemLocale` is the device's own locale, as the platform
    // reports it: "en_US", "it_IT", "ar". Only the language part decides
    // which of our translations to use.
    final deviceCode = Intl.systemLocale.split(RegExp('[_-]')).first;
    final device =
        supportedAppLanguages.where((l) => l.languageCode == deviceCode);
    return device.isNotEmpty ? device.first : _fallback;
  }
}
