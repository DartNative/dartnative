// GENERATED FILE — DO NOT EDIT BY HAND.
// Regenerate with:
//
// This file is re-generated whenever the set of DartNative plugin dependencies
// in pubspec.yaml changes. It is the single entry point an app needs:
//
//   void main() {
//     DartNativePluginRegistrant.registerAll();  // platform bindings + plugins
//     runApp(const MyApp());
//   }
//
// Plugins found in dartnative_firebase_example:
//   • dartnative_ios (platform bindings)
//   • dartnative_android (platform bindings)

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';

abstract final class DartNativePluginRegistrant {
  /// Register the platform bindings (iOS or Android) AND load FFI symbols for
  /// every DartNative plugin linked into this app.
  ///
  /// Call once at the top of `main()`, before [runApp]. Each plugin guards on
  /// its supported platform(s), so it's safe to call on any platform.
  static void registerAll() {
    // The licence the build injected: the compiled demo/trial token, or the
    // subscriber key from `dn config --license-key`. `dn` puts one of them in
    // the build's defines, and this file is the only place that can read them
    // — the framework's own `fromEnvironment` was frozen when the SDK was
    // compiled. Without this an app with a perfectly valid licence shows the
    // licence screen. `dn create` generates these lines for your own projects.
    const dnLicenseToken = String.fromEnvironment('DART_NATIVE_LICENSE_TOKEN');
    if (dnLicenseToken.isNotEmpty) {
      DartNativeLicense.instance.provideToken(dnLicenseToken);
    }
    const dnLicenseKey = String.fromEnvironment('DN_LICENSE_KEY');
    if (dnLicenseKey.isNotEmpty) {
      DartNativeLicense.instance.provideLicenseKey(dnLicenseKey);
    }
    const dnTrialEnded = bool.fromEnvironment('DN_TRIAL_ENDED');
    if (dnTrialEnded) {
      DartNativeLicense.instance.noteTrialEnded();
    }

    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
  }
}
