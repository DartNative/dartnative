import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/secure_storage_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const SecureStorageDemo());
}
