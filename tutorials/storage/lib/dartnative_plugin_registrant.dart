// GENERATED-STYLE registrant for this tutorial. In your own project,
// `dn create` generates and maintains this file from your pubspec.
//
// Plugins in this app:
//   • dartnative_ios / dartnative_android (platform bindings)
//   • dartnative_shared_preferences
//   • dartnative_secure_storage
//   (dartnative_hive, dartnative_sqlite and dartnative_path_provider are
//   pure Dart over the core symbols — nothing extra to load.)

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_secure_storage/dartnative_secure_storage.dart';
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

abstract final class DartNativePluginRegistrant {
  /// Call once at the top of `main()`, before `runApp`.
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    SecureBindings.loadSymbols();
    PrefsBindings.loadSymbols();
  }
}
