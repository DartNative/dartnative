import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'permissions_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const PermissionsDemoApp());
}
