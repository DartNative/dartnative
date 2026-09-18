// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar locale. All the
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
  String get localeName => 'ar';

  static String m0(name) => "مرحبا، ${name}!";

  static String m1(language) => "التطبيق باللغة ${language}.";

  static String m2(count) =>
      "${Intl.plural(count, zero: 'لا رسائل', one: 'رسالة واحدة', other: '${count} رسائل')}";

  static String m3(amount) => "سعرها ${amount}.";

  static String m4(date) => "اليوم هو ${date}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "add_message": MessageLookupByLibrary.simpleMessage("أضف واحدة"),
    "app_title": MessageLookupByLibrary.simpleMessage("الترجمة"),
    "clear_messages": MessageLookupByLibrary.simpleMessage("مسح"),
    "counter_section": MessageLookupByLibrary.simpleMessage("الجمع والأرقام"),
    "dates_section": MessageLookupByLibrary.simpleMessage("التواريخ"),
    "greeting": m0,
    "language_current": m1,
    "language_section": MessageLookupByLibrary.simpleMessage("اللغة"),
    "messages_count": m2,
    "price_is": m3,
    "restart_note": MessageLookupByLibrary.simpleMessage(
      "تم حفظ اختيارك. أغلق التطبيق وافتحه مرة أخرى: سيعود بنفس اللغة.",
    ),
    "today_is": m4,
  };
}
