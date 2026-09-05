// GENERATED-STYLE registrant for this tutorial. In your own project,
// `dn create` generates and maintains this file from your pubspec.
//
// Plugins in this app:
//   • dartnative_ios / dartnative_android (platform bindings)
//   • dartnative_audio (PCM playback) + dartnative_onnxruntime (inference)
//   • dartnative_supertonic_tts is pure Dart — nothing to load

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_onnxruntime/dartnative_onnxruntime.dart';

abstract final class DartNativePluginRegistrant {
  /// Call once at the top of `main()`, before `runApp`.
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    AudioFFIBindings.loadSymbols();
    OrtFFIBindings.loadSymbols();
  }
}
