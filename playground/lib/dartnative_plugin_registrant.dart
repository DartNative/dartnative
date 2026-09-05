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
//   • dartnative_audio
//   • dartnative_camera
//   • dartnative_compressor
//   • dartnative_connectivity
//   • dartnative_image_crop
//   • dartnative_lottie
//   • dartnative_media_picker
//   • dartnative_notifications
//   • dartnative_onnxruntime
//   • dartnative_permissions
//   • dartnative_secure_storage
//   • dartnative_shared_preferences
//   • dartnative_social_sign_in
//   • dartnative_system
//   • dartnative_video_player

import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_ios/dartnative_ios.dart';
import 'package:dartnative_android/dartnative_android.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_camera/dartnative_camera.dart';
import 'package:dartnative_compressor/dartnative_compressor.dart';
import 'package:dartnative_connectivity/connectivity.dart';
import 'package:dartnative_image_crop/dartnative_image_crop.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';
import 'package:dartnative_media_picker/dartnative_media_picker.dart';
import 'package:dartnative_media_picker/gallery.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';
import 'package:dartnative_onnxruntime/dartnative_onnxruntime.dart';
import 'package:dartnative_permissions/dartnative_permissions.dart';
import 'package:dartnative_secure_storage/dartnative_secure_storage.dart';
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';
import 'package:dartnative_social_sign_in/social_sign_in.dart';
import 'package:dartnative_system/dartnative_system.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

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
      'dartnative_audio',
      'dartnative_camera',
      'dartnative_compressor',
      'dartnative_connectivity',
      'dartnative_firebase',
      'dartnative_hive',
      'dartnative_image_crop',
      'dartnative_lottie',
      'dartnative_media_picker',
      'dartnative_notifications',
      'dartnative_onnxruntime',
      'dartnative_path_provider',
      'dartnative_permissions',
      'dartnative_secure_storage',
      'dartnative_shared_preferences',
      'dartnative_skia',
      'dartnative_social_sign_in',
      'dartnative_splash',
      'dartnative_sqlite',
      'dartnative_supertonic_tts',
      'dartnative_system',
      'dartnative_video_player',
    ]);
    registerNativeBindings(
      Platform.isAndroid
          ? AndroidNativeBindings.instance
          : IOSNativeBindings.instance,
    );
    _load('dartnative_audio', () {
      AudioFFIBindings.loadSymbols();
    });
    _load('dartnative_camera', () {
      CameraFfiBindings.loadSymbols();
    });
    _load('dartnative_compressor', () {
      CompressorFFIBindings.loadSymbols();
    });
    _load('dartnative_connectivity', () {
      ConnectivityFFIBindings.loadSymbols();
    });
    _load('dartnative_image_crop', () {
      ImageCropFFIBindings.loadSymbols();
    });
    _load('dartnative_lottie', () {
      LottieFFIBindings.loadSymbols();
    });
    _load('dartnative_media_picker', () {
      MediaPickerFFIBindings.loadSymbols();
      MediaGalleryFFIBindings.loadSymbols();
    });
    _load('dartnative_notifications', () {
      NotificationsFFIBindings.loadSymbols();
    });
    _load('dartnative_onnxruntime', () {
      OrtFFIBindings.loadSymbols();
    });
    _load('dartnative_permissions', () {
      PermissionFFIBindings.loadSymbols();
    });
    _load('dartnative_secure_storage', () {
      SecureBindings.loadSymbols();
    });
    _load('dartnative_shared_preferences', () {
      PrefsBindings.loadSymbols();
    });
    _load('dartnative_social_sign_in', () {
      GoogleSignInFFIBindings.loadSymbols();
      SignInWithAppleFFIBindings.loadSymbols();
    });
    _load('dartnative_system', () {
      SystemFFIBindings.loadSymbols();
    });
    _load('dartnative_video_player', () {
      VideoFFIBindings.loadSymbols();
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
