// GENERATED-STYLE registrant for this tutorial. In your own project,
// `dn create` generates and maintains this file from your pubspec.
//
// Plugins in this app:
//   • dartnative_ios / dartnative_android (platform bindings)
//   • dartnative_google_maps

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_google_maps/dartnative_google_maps.dart';

abstract final class DartNativePluginRegistrant {
  /// Call once at the top of `main()`, before `runApp`.
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
    initializeGoogleMapsPlugin();
  }
}
