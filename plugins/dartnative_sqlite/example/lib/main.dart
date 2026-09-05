import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';

import 'screens/sqlite_demo.dart';

void main() {
  // Register the platform bindings (iOS or Android). dartnative_sqlite itself is
  // pure Dart — it talks to libsqlite3 over FFI, so no plugin registrant is
  // needed beyond these bindings. The database lives at the documents path from
  // dartnative_path_provider.
  registerNativeBindings(
    Platform.isAndroid
        ? AndroidNativeBindings.instance
        : IOSNativeBindings.instance,
  );
  runApp(const SqliteDemo());
}
