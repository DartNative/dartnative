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
//   • dartnative_keys
//   • dartnative_shared_preferences
//   • dartnative_social_sign_in
//   • dartnative_url_launcher

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_keys/dartnative_keys.dart';
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';
import 'package:dartnative_social_sign_in/social_sign_in.dart';
import 'package:dartnative_url_launcher/dartnative_url_launcher.dart';

abstract final class DartNativePluginRegistrant {
  /// Registers the platform bindings and loads every DartNative plugin's
  /// FFI symbols. Call once as the first line of `main()`, before `runApp`.
  static void registerAll() {
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
    DartNativeLicense.instance.reportPluginUsage(const <String>[
      'dartnative_keys',
      'dartnative_path_provider',
      'dartnative_shared_preferences',
      'dartnative_skia',
      'dartnative_social_sign_in',
      'dartnative_splash',
      'dartnative_sqlite',
      'dartnative_supabase',
      'dartnative_url_launcher',
    ]);
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    _load('dartnative_keys', () {
      KeysBindings.loadSymbols();
    });
    _load('dartnative_shared_preferences', () {
      PrefsBindings.loadSymbols();
    });
    _load('dartnative_social_sign_in', () {
      GoogleSignInFFIBindings.loadSymbols();
      SignInWithAppleFFIBindings.loadSymbols();
    });
    _load('dartnative_url_launcher', () {
      UrlLauncherFFIBindings.loadSymbols();
    });
  }

  /// Loads one plugin's FFI symbols, turning a missing native side into a
  /// message that names the fix.
  static void _load(String plugin, void Function() load) {
    try {
      load();
    } catch (e) {
      dnLog(
        '[dartnative] $plugin: its native symbols are not in this build.\n'
        '  iOS:     run `pod install` in ios/, then rebuild.\n'
        '  Android: rebuild so the plugin library is packaged.\n'
        '  The app keeps going; this plugin will not work until then.\n'
        '  $e',
      );
    }
  }
}
