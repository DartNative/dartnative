import UIKit

/// Legend List's "Cards" screen and its chat, written in Swift on UIKit
/// for the scrolling benchmark. The app opens straight on one screen,
/// chosen when it is built, as the DartNative app does; each screen is its
/// own app ("ChatList (Swift)"), so all of them can sit on one phone:
///
///   xcodebuild ... build                         # Cards
///   xcodebuild ... BENCH_SCREEN=chat build       # Chat
///   xcodebuild ... BENCH_SCREEN=empty build      # Empty
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    true
  }
}

/// The app's one window, in its scene, as Xcode's iOS app template sets an
/// app up.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    #if CHAT
    let screen = ChatViewController()
    #elseif EMPTY
    let screen = EmptyViewController()
    #else
    let screen = CardsViewController()
    #endif
    let nav = UINavigationController(rootViewController: screen)
    // The example's stack header (`headerTransparent: false`): an opaque
    // bar in the theme's colour, with the screen laid out below it rather
    // than scrolling under it.
    nav.navigationBar.isTranslucent = false
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = Palette.header
    appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    nav.navigationBar.standardAppearance = appearance
    nav.navigationBar.scrollEdgeAppearance = appearance
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = nav
    window.makeKeyAndVisible()
    self.window = window
  }
}
