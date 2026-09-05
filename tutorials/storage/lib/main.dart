/// DartNative tutorial — on-device storage, all four kinds.
///
/// lib/screens/storage_demo.dart is a BYTE-IDENTICAL copy of the DartNative
/// playground's Storage demo (lib/screens/home/demo_ui.dart is the
/// playground's shared UI kit, also verbatim). When the playground demo
/// improves, this tutorial updates by copying the files again:
///   • storage_demo.dart — one tabbed screen, four panels:
///     SharedPreferences, SecureStorage, Hive, and SQLite,
///     all over direct FFI — no MethodChannel, callable from any isolate
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/storage_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const StorageDemo(initialTab: StorageTab.preferences));
}
