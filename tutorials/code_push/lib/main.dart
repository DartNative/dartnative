// The app's entry point.
//
// Only main() lives here. A fix sends every function of a file it changes,
// and main() is the one function that should never travel in a fix, so
// nothing else shares this file with it. The screen is in
// checkout_screen.dart and the four mistakes are in fix_me.dart.

import 'package:dartnative/dartnative.dart';

import 'checkout_screen.dart';
import 'dartnative_plugin_registrant.dart';

void main() {
  // Platform bindings + (once you add plugins) their FFI symbols. Keep this
  // as the FIRST line of main() — see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  // Dark status-bar icons over the white screen.
  SystemChrome.defaultStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  // Code push needs nothing here. runApp applies a fix that an earlier run
  // downloaded, before the first screen is drawn (on an iPhone it attaches
  // the fix's functions over the shipped ones; on Android the engine already
  // swapped the fix in as the app started), and asks for a newer one once
  // the screen is up. The release version it checks a fix against is the
  // one `dn release` wrote into dn_code_push.yaml. With no fix, or a fix
  // that does not fit this release, the app runs exactly as shipped.
  runApp(const CheckoutScreen());
}
