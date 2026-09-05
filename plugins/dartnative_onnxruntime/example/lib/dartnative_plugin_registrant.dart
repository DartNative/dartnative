// GENERATED-STYLE FILE — kept in sync with pubspec.yaml DartNative plugin deps.
// Regenerate with:
//   dn pub get
//
// Plugins linked into dartnative_onnxruntime_example:
//   • dartnative_ios / dartnative_android (platform bindings)
//   • dartnative_onnxruntime  → OrtFFIBindings.loadSymbols()

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_onnxruntime/dartnative_onnxruntime.dart';

abstract final class DartNativePluginRegistrant {
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    OrtFFIBindings.loadSymbols();
  }
}
