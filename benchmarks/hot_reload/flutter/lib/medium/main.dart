// The hot reload benchmark's medium app, Flutter: a contacts screen built
// from nine files, an app bar over a header and 40 rows, each row with an
// avatar, two texts and a trailing icon. ../../tool/measure.py changes
// rowColor in contact_row.dart, one file of the nine.
//
//   flutter run -d <simulator id> -t lib/medium/main.dart
import 'package:flutter/material.dart';

import 'contacts_screen.dart';

void main() => runApp(const MaterialApp(home: ContactsScreen()));
