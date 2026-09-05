// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Regenerated automatically on `dn pub get` / `dn create` whenever the set of
// DartNative plugins changes. `registerAll()` selects the platform bindings
// AND loads every plugin's FFI symbols, so `main()` needs only:
//
//   void main() {
//     DartNativePluginRegistrant.registerAll();
//     runApp(const MyApp());
//   }
//
// To hand-own this file, delete the header line above; the CLI then stops
// overwriting it.
//
// Plugins loaded:
//   • dartnative_google_maps

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_google_maps/dartnative_google_maps.dart';

abstract final class DartNativePluginRegistrant {
  /// Registers the platform bindings and loads every DartNative plugin's
  /// FFI symbols. Call once as the first line of `main()`, before `runApp`.
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    initializeGoogleMapsPlugin();
  }
}
