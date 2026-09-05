// GENERATED-STYLE registrant for this tutorial. In your own project,
// `dn create` generates and maintains this file from your pubspec.
//
// Plugins in this app:
//   • dartnative_ios / dartnative_android (platform bindings)
//   • dartnative_camera
//   • dartnative_audio
//   • dartnative_compressor
//   • dartnative_image_crop

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_camera/dartnative_camera.dart';
import 'package:dartnative_compressor/dartnative_compressor.dart';
import 'package:dartnative_image_crop/dartnative_image_crop.dart';

abstract final class DartNativePluginRegistrant {
  /// Call once at the top of `main()`, before `runApp`.
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    AudioFFIBindings.loadSymbols();
    CameraFfiBindings.loadSymbols();
    CompressorFFIBindings.loadSymbols();
    ImageCropFFIBindings.loadSymbols();
  }
}
