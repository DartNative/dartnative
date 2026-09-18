// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
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
  String get localeName => 'es';

  static String m0(name) => "¡Hola, ${name}!";

  static String m1(language) => "La aplicación está en ${language}.";

  static String m2(count) =>
      "${Intl.plural(count, zero: 'Sin mensajes', one: 'Un mensaje', other: '${count} mensajes')}";

  static String m3(amount) => "Cuesta ${amount}.";

  static String m4(date) => "Hoy es ${date}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "add_message": MessageLookupByLibrary.simpleMessage("Añadir uno"),
    "app_title": MessageLookupByLibrary.simpleMessage("Localización"),
    "clear_messages": MessageLookupByLibrary.simpleMessage("Borrar"),
    "counter_section": MessageLookupByLibrary.simpleMessage(
      "Plurales y números",
    ),
    "dates_section": MessageLookupByLibrary.simpleMessage("Fechas"),
    "greeting": m0,
    "language_current": m1,
    "language_section": MessageLookupByLibrary.simpleMessage("Idioma"),
    "messages_count": m2,
    "price_is": m3,
    "restart_note": MessageLookupByLibrary.simpleMessage(
      "Tu elección está guardada. Cierra y vuelve a abrir la app: vuelve en el mismo idioma.",
    ),
    "today_is": m4,
  };
}
