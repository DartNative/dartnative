/// DartNative tutorial — Sign in with Apple & Google.
///
/// The screen at lib/screens/social_sign_in_demo.dart is a BYTE-IDENTICAL
/// copy of the DartNative playground's social sign-in demo
/// (lib/screens/home/demo_ui.dart is the playground's shared UI kit, also
/// verbatim). When the playground demo improves, this tutorial updates by
/// copying the files again:
///   • social_sign_in_demo.dart — Apple (ASAuthorizationController) and
///     Google (GIDSignIn / Credential Manager) over FFI, each with a native
///     Button variant, a GestureDetector variant, and a result card
///
/// Configuration (see README): Apple needs the "Sign in with Apple"
/// capability; Google needs GoogleService-Info.plist (iOS) or the web
/// OAuth client ID via --dart-define=GOOGLE_SERVER_CLIENT_ID (Android).
/// Missing configuration is handled gracefully — the buttons still show,
/// and auth errors are displayed inline.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/social_sign_in_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const SocialSignInDemo());
}
