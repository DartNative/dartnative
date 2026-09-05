// GENERATED FILE — DO NOT EDIT BY HAND.
// Regenerate with:
//   dn pub get
//
// Plugins found in url_launcher_example:
//   • dartnative_ios (platform bindings)
//   • dartnative_android (platform bindings)
//   • dartnative_url_launcher

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_url_launcher/dartnative_url_launcher.dart';

abstract final class DartNativePluginRegistrant {
  static void registerAll() {
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    UrlLauncherFFIBindings.loadSymbols();
  }
}
