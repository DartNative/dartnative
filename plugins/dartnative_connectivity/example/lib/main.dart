import 'package:dartnative/dartnative.dart';

import 'connectivity_demo.dart';
import 'dartnative_plugin_registrant.dart';

void main() {
  // Platform bindings + plugin FFI symbols. Keep this as the FIRST line of
  // main() — see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  // App-wide system chrome default for the white template: dark status-bar
  // icons over the light background, transparent strips.
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  runApp(const ConnectivityDemo());
}
