// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_intl/dartnative_intl.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Localization`
  String get app_title {
    return Intl.message('Localization', name: 'app_title', desc: '', args: []);
  }

  /// `Hello, {name}!`
  String greeting(Object name) {
    return Intl.message(
      'Hello, $name!',
      name: 'greeting',
      desc: '',
      args: [name],
    );
  }

  /// `Language`
  String get language_section {
    return Intl.message(
      'Language',
      name: 'language_section',
      desc: '',
      args: [],
    );
  }

  /// `The app is in {language}.`
  String language_current(Object language) {
    return Intl.message(
      'The app is in $language.',
      name: 'language_current',
      desc: '',
      args: [language],
    );
  }

  /// `Plurals and numbers`
  String get counter_section {
    return Intl.message(
      'Plurals and numbers',
      name: 'counter_section',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No messages} =1{One message} other{{count} messages}}`
  String messages_count(num count) {
    return Intl.plural(
      count,
      zero: 'No messages',
      one: 'One message',
      other: '$count messages',
      name: 'messages_count',
      desc: '',
      args: [count],
    );
  }

  /// `Add one`
  String get add_message {
    return Intl.message('Add one', name: 'add_message', desc: '', args: []);
  }

  /// `Clear`
  String get clear_messages {
    return Intl.message('Clear', name: 'clear_messages', desc: '', args: []);
  }

  /// `Dates`
  String get dates_section {
    return Intl.message('Dates', name: 'dates_section', desc: '', args: []);
  }

  /// `Today is {date}.`
  String today_is(DateTime date) {
    final DateFormat dateDateFormat = DateFormat.yMMMMd(
      Intl.getCurrentLocale(),
    );
    final String dateString = dateDateFormat.format(date);

    return Intl.message(
      'Today is $dateString.',
      name: 'today_is',
      desc: '',
      args: [dateString],
    );
  }

  /// `That costs {amount}.`
  String price_is(double amount) {
    final NumberFormat amountNumberFormat = NumberFormat.currency(
      locale: Intl.getCurrentLocale(),
    );
    final String amountString = amountNumberFormat.format(amount);

    return Intl.message(
      'That costs $amountString.',
      name: 'price_is',
      desc: '',
      args: [amountString],
    );
  }

  /// `Your choice is saved. Close and reopen the app: it comes back in the same language.`
  String get restart_note {
    return Intl.message(
      'Your choice is saved. Close and reopen the app: it comes back in the same language.',
      name: 'restart_note',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'it'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
