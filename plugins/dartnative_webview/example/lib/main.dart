import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'webview_demo.dart';

void main() {
  // Registers the platform bindings (iOS/Android) + WebViewFFIBindings.loadSymbols().
  DartNativePluginRegistrant.registerAll();
  runApp(const WebViewDemoScreen());
}
