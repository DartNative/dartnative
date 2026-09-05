import UIKit
import GoogleMaps
import dartnative_ios

/// AppDelegate for the dartnative_google_maps example app.
///
/// The base class owns the engine lifecycle; the window is built in
/// SceneDelegate. What remains here is the API-key handoff, which is
/// app-side by design.
@main
@objc class AppDelegate: DartNativeAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API key — read from the GMSApiKey Info.plist value, fed by
    // the gitignored Secrets.xcconfig (MAPS_API_KEY). A consumer hardcodes
    // their own key here instead. This is Google's documented app-side
    // pattern; the plugin deliberately does NOT auto-read keys (keys vary
    // per environment/flavor and are the developer's secret to manage).
    // See README → "API key setup".
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !key.isEmpty {
      GMSServices.provideAPIKey(key)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
