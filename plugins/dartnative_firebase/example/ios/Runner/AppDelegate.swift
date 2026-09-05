import UIKit
import dartnative_ios
import dartnative_firebase

/// AppDelegate for the dartnative_firebase example app.
///
/// The base class owns the engine lifecycle; the window is built in
/// SceneDelegate. What remains here is the one piece of glue iOS requires
/// any app using dartnative_firebase to supply:
///
///   `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
///   forwards silent / data-only pushes to the plugin so onMessage fires
///   while the app is suspended in background. Apple delivers these ONLY to
///   the UIApplicationDelegate — no SDK can intercept them elsewhere.
///
/// Notification taps and APNs token registration are handled internally by
/// DNMessagingDelegate (set as UNUserNotificationCenter delegate by
/// `FirebaseMessaging.setup()` from Dart).
@main
@objc class AppDelegate: DartNativeAppDelegate {

  /// Background / silent push entry point.
  ///
  /// Serialises userInfo to JSON and forwards to the plugin via
  /// `DNFCMHandleRemoteNotification`. The plugin then dispatches to the
  /// registered foreground-message Dart listener.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    let isBackground: Int32 =
      (application.applicationState == .background) ? 1 : 0
    if let data = try? JSONSerialization.data(
        withJSONObject: sanitizeForJson(userInfo),
        options: []),
      let json = String(data: data, encoding: .utf8) {
      json.withCString {
        DNFCMHandleRemoteNotification($0, isBackground, 0)
      }
    }
    completionHandler(.newData)
  }

  /// JSON-safe filter — replace non-stringifiable values (e.g. NSDate) with
  /// their description so JSONSerialization succeeds.
  private func sanitizeForJson(_ dict: [AnyHashable: Any]) -> [String: Any] {
    var out: [String: Any] = [:]
    for (k, v) in dict {
      let key = "\(k)"
      if JSONSerialization.isValidJSONObject([key: v]) {
        out[key] = v
      } else {
        out[key] = "\(v)"
      }
    }
    return out
  }
}
