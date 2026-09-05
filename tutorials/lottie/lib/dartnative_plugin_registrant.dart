// GENERATED-STYLE registrant for this tutorial. In your own project,
// `dn create` generates and maintains this file from your pubspec.
//
// Plugins in this app:
//   • dartnative_ios / dartnative_android (platform bindings)
//   • dartnative_lottie

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';

abstract final class DartNativePluginRegistrant {
  /// Call once at the top of `main()`, before `runApp`.
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    LottieFFIBindings.loadSymbols();
  }
}
