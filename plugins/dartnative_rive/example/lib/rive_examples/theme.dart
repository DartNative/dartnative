// rive-flutter's example app palette, verbatim from their
// `example/lib/colors.dart`, so the two apps look the same side by side.

import 'package:dartnative/dartnative.dart';

const appBarColor = Color(0xFF323232);
const backgroundColor = Color(0xFF1D1D1D);
const primaryColor = Color(0xFF57A5E0);

/// Their nav buttons are grey pills on the dark background.
const buttonColor = Color(0xFF4A4A4A);

/// Their theme sets `fontFamily: 'JetBrainsMono'` app-wide, bundled as a
/// font asset. We cannot register that the same way: `dn` puts assets inside
/// `App.framework/flutter_assets`, and iOS's `UIAppFonts` only scans the main
/// bundle, so the family would have to be registered from native code at
/// startup. The system monospace face gives the same character — a fixed
/// pitch, the look their menu gets from JetBrains Mono — with no native
/// change. Their font is JetBrains Mono (SIL OFL 1.1, from
/// github.com/JetBrains/JetBrainsMono) — not shipped here, so nothing to
/// attribute; add it to THIRD_PARTY_NOTICES if it is ever bundled.
const monoFont = 'Menlo';

/// The status bar of the white demos ("Additional demos"): dark icons over
/// their white background, where the app's default (main.dart) has light
/// ones. Each sets it in initState; the Navigator restores the default when
/// the screen pops.
const whiteScreenStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.light,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
);
