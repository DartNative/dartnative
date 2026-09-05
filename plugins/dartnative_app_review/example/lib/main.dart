import 'package:dartnative/dartnative.dart';

import 'app_review_demo.dart';
import 'dartnative_plugin_registrant.dart';

void main() {
  // Platform bindings + plugin FFI symbols (AppReviewFFIBindings.loadSymbols).
  // Keep as the FIRST line of main() — see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  runApp(const AppReviewDemo());
}
