import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/crypto_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const CryptoDemo());
}
