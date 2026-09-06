import 'package:dartnative/dartnative.dart';
import 'package:dartnative_notifications/dartnative_notifications.dart';
import 'dartnative_plugin_registrant.dart';
import 'screens/notifications_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Register the tap callback before the first frame so a notification
  // tapped from a cold start still reaches it (iOS delegate / Android
  // activity-event hub deliver it automatically — no app glue needed).
  DartNativeNotifications.setup(onTap: (payload) {
    // A tapped notification lands here — route on the payload.
    print('notification tapped: $payload');
  });
  runApp(const NotificationsDemo());
}
