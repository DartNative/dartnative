import UIKit
import dartnative_ios

@objc class SceneDelegate: DartNativeSceneDelegate {
  // The base class builds the window and starts the DartNative runtime.
  // Override scene(_:willConnectTo:options:) here to customize.

  private var background = UIBackgroundTaskIdentifier.invalid

  // iOS shows nothing of a live activity while its app is open, so a story
  // sends its alert step a moment after the app leaves the screen. The app
  // asks iOS for those seconds; without them iOS suspends it first.
  @objc func sceneDidEnterBackground(_ scene: UIScene) {
    guard background == .invalid else { return }
    background = UIApplication.shared.beginBackgroundTask(withName: "story alert") { [weak self] in
      self?.endBackground()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
      self?.endBackground()
    }
  }

  @objc func sceneWillEnterForeground(_ scene: UIScene) {
    endBackground()
  }

  private func endBackground() {
    guard background != .invalid else { return }
    UIApplication.shared.endBackgroundTask(background)
    background = .invalid
  }
}
