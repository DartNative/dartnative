import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/shared_preferences_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const SharedPreferencesDemo());
}
