import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'http_demo.dart';

void main() {
  // Registers the platform bindings and the plugins' FFI symbols. Keep this
  // as the first line of main(); see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  // The app-wide style of the system bars, for this white app: dark status
  // bar icons over the light background, and transparent bars. A screen can
  // override it in initState; the navigator restores it when a screen pops.
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  runApp(const PackageSearchApp());
}
