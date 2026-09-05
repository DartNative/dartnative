/// DartNative tutorial — notifications, local & push.
///
/// lib/screens/notifications_demo.dart is a BYTE-IDENTICAL copy of the
/// DartNative playground's notifications demo (lib/screens/home/demo_ui.dart
/// is the playground's shared UI kit, also verbatim). When the playground
/// demo improves, this tutorial updates by copying the files again:
///   • DartNativeNotifications — permission (UNUserNotificationCenter /
///     POST_NOTIFICATIONS), a default local alert, and the iOS 15+
///     Communication notification (the chat-style banner with an avatar)
///   • dartnative_firebase — FCM over FFI: token fetch + a foreground
///     message log (replaces firebase_messaging, no MethodChannel)
///
/// This file adds only the entry wiring: plugin registration plus the
/// Firebase / notifications startup below. Permission + local notifications
/// run with zero configuration; the FCM part needs your own Firebase project
/// (GoogleService-Info.plist), the Push Notifications + Background Modes
/// (Remote notifications) capabilities, and a physical device — see
/// README.md.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_firebase/dartnative_firebase.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/notifications_demo.dart';

Future<void> main() async {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  // Firebase loads its symbols + inits the default app from the platform
  // config (GoogleService-Info.plist / google-services.json), then
  // installs the FCM delegate — done in main() so the token is ready
  // before any screen asks for it.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.setup();
  } catch (e) {
    print('Firebase init failed — continuing without push: $e');
  }
  try {
    DartNativeNotifications.setup(onTap: (payload) {
      // A tapped notification lands here — route on the payload.
      print('notification tapped: $payload');
    });
  } catch (e) {
    print('Notifications init failed: $e');
  }
  runApp(const NotificationsDemo());
}
