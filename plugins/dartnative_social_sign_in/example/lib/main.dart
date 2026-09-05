import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'social_sign_in_demo.dart';

void main() {
  // Platform bindings + the plugin's FFI symbols. Keep this as the FIRST line
  // of main() — see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  runApp(const SocialSignInDemoApp());
}
