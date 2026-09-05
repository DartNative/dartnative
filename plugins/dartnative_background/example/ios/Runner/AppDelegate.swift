import UIKit
import dartnative_ios
import dartnative_background

/// AppDelegate for the dartnative_background example app.
///
/// The base class owns the engine lifecycle; the window is built in
/// SceneDelegate. What remains here is the registration Apple requires the
/// app itself to perform.
@main
@objc class AppDelegate: DartNativeAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Register BGTaskScheduler identifiers BEFORE didFinishLaunching returns
    // (Apple requires it — super has run, but we are still inside the
    // launch call, so the timing contract holds). These must match the task
    // names in lib/main.dart and the BGTaskSchedulerPermittedIdentifiers in
    // Info.plist. The handlers boot a headless engine and run the Dart
    // `callbackDispatcher` over FFI — no plugin-registrant callback needed
    // (FFI symbols are process-global).
    //
    // `frequency` is the *requested* minimum interval. iOS enforces its own
    // ~15-minute floor regardless of the value — actual dispatch depends on
    // device usage patterns. Each invocation is capped to ~30 s of CPU time
    // by the OS.
    if #available(iOS 13.0, *) {
      DartNativeBackgroundPlugin.registerPeriodicTask(
        withIdentifier: "com.dartnative.background.periodicTask",
        frequency: NSNumber(value: 15 * 60))  // 15 min — the OS minimum
      DartNativeBackgroundPlugin.registerBGProcessingTask(
        withIdentifier: "com.dartnative.background.processingTask")
    }
    return result
  }
}
