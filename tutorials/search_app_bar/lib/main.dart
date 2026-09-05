/// DartNative tutorial — search in the app bar, both platforms.
///
/// The screen under lib/screens/material3/ is a BYTE-IDENTICAL copy of the
/// DartNative playground's search app bar demo (lib/screens/home/demo_ui.dart
/// is the playground's shared UI kit, also verbatim). When the playground demo
/// improves, this tutorial updates by copying the file again:
///   • m3_search_appbar_demo.dart — one `AppBar.searchBar` declaration:
///     Apple's in-place search on iOS 26 (real Liquid Glass), the genuine
///     Material 3 SearchBar + SearchView pair on Android, live Dart
///     suggestions inside both native surfaces
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/material3/m3_search_appbar_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const SearchHome());
}

/// One-row launcher built from the playground's own UI kit. Pushing the demo
/// (rather than running it as the root) matters: frame 1 keeps the auto back
/// button with the pill laying out after it, exactly as the screen runs in
/// the playground.
class SearchHome extends StatelessWidget {
  const SearchHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Search',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DemoRow(
            icon: CupertinoIcons.search,
            tint: kAccentBlue,
            title: 'Search app bar',
            tagline: 'One AppBar.searchBar — native on both platforms',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const M3SearchAppBarDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
