import 'package:dartnative/dartnative.dart';
import 'package:dartnative_keys/dartnative_keys.dart';

import 'dartnative_plugin_registrant.dart';
import 'revenuecat_demo.dart';

void main() async {
  DartNativePluginRegistrant.registerAll();
  // Load the bundled RevenueCat public SDK key (.dnkeys) before the demo
  // configures Purchases. The DartNative license token is passed separately via
  // --dart-define=DART_NATIVE_LICENSE_TOKEN at `dn run` (see ../../README.md).
  await DnKeys.load();
  runApp(const RevenueCatDemoApp());
}
