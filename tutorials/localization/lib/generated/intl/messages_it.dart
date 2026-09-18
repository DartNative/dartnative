// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a it locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'it';

  static String m0(name) => "Ciao, ${name}!";

  static String m1(language) => "L\'app è in ${language}.";

  static String m2(count) =>
      "${Intl.plural(count, zero: 'Nessun messaggio', one: 'Un messaggio', other: '${count} messaggi')}";

  static String m3(amount) => "Costa ${amount}.";

  static String m4(date) => "Oggi è ${date}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "add_message": MessageLookupByLibrary.simpleMessage("Aggiungine uno"),
    "app_title": MessageLookupByLibrary.simpleMessage("Localizzazione"),
    "clear_messages": MessageLookupByLibrary.simpleMessage("Svuota"),
    "counter_section": MessageLookupByLibrary.simpleMessage("Plurali e numeri"),
    "dates_section": MessageLookupByLibrary.simpleMessage("Date"),
    "greeting": m0,
    "language_current": m1,
    "language_section": MessageLookupByLibrary.simpleMessage("Lingua"),
    "messages_count": m2,
    "price_is": m3,
    "restart_note": MessageLookupByLibrary.simpleMessage(
      "La tua scelta è salvata. Chiudi e riapri l\'app: torna nella stessa lingua.",
    ),
    "today_is": m4,
  };
}
