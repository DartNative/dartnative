import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/hive_demo.dart';

void main() {
  // dartnative_hive is pure Dart — the documents path comes from
  // dartnative_path_provider (a self-contained facade over the OS dirs).
  DartNativePluginRegistrant.registerAll();
  runApp(const HiveDemo());
}
