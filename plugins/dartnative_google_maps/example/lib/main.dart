import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/google_maps_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const GoogleMapsDemo());
}
