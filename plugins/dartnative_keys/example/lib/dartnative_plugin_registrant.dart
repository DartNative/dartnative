// GENERATED FILE — DO NOT EDIT BY HAND.
// Regenerate with:
//   dn pub get
//
// This file is re-generated whenever the set of DartNative plugin dependencies
// in pubspec.yaml changes. It is the single entry point an app needs:
//
//   void main() {
//     DartNativePluginRegistrant.registerAll();  // platform bindings + plugins
//     runApp(const MyApp());
//   }
//
// Plugins found in dartnative_keys_example:
//   • dartnative_ios (platform bindings)
//   • dartnative_android (platform bindings)
//   • dartnative_keys

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_keys/dartnative_keys.dart';

abstract final class DartNativePluginRegistrant {
  /// Register the platform bindings (iOS or Android) AND load FFI symbols for
  /// every DartNative plugin linked into this app.
  ///
  /// Call once at the top of `main()`, before [runApp]. Each plugin guards on
  /// its supported platform(s), so it's safe to call on any platform.
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    KeysBindings.loadSymbols();
  }
}
