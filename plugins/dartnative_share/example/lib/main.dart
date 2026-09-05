import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'share_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const ShareDemoApp());
}
