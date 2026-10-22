// The hot reload benchmark's medium app, DartNative: a contacts screen built
// from nine files, an app bar over a header and 40 rows, each row with an
// avatar, two texts and a trailing icon. ../../tool/measure.py changes
// rowColor in contact_row.dart, one file of the nine.
//
//   dn run -d <simulator id> -t lib/medium/main.dart
import 'package:dartnative/dartnative.dart';

import '../dartnative_plugin_registrant.dart';
import 'contacts_screen.dart';

void main() {
  // The platform bindings; the first line of main() in every DartNative app.
  DartNativePluginRegistrant.registerAll();
  runApp(const ContactsScreen());
}
