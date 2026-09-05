import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/supertonic_demo.dart';

void main() {
  // Platform bindings + FFI symbol loading for every dartnative_* plugin.
  DartNativePluginRegistrant.registerAll();
  runApp(const SuperTonicDemo());
}
