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
    UrlLauncherFFIBindings.loadSymbols();
  }
}
