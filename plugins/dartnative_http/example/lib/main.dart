import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'http_demo.dart';

void main() {
  // Registers the platform bindings and the plugins' FFI symbols. Keep this
  // as the first line of main(); see lib/dartnative_plugin_registrant.dart.
  DartNativePluginRegistrant.registerAll();
  runApp(const PackageSearchApp());
}
