/// DartNative tutorial — Material 3 & dynamic color.
///
/// The three screens under lib/screens/material3/ are BYTE-IDENTICAL copies
/// of the DartNative playground's Material 3 demos (lib/screens/home/
/// demo_ui.dart is the playground's shared UI kit, also verbatim). When the
/// playground demos improve, this tutorial updates by copying the files
/// again:
///   • m3_dynamic_color_demo.dart — the device's wallpaper-derived Material
///     You palette, read from the system (android.R.color.system_accent1_*…)
///     and rebuilt into the M3 color roles in Dart; `null` off-Android-12+
///   • m3_badges_demo.dart — the real BadgeDrawable on a tab and a bar
///     action (the same Dart lowers to UITabBarItem badges on iOS)
///   • m3_hide_on_scroll_demo.dart — TabBarScrollBehavior.minimizeOnScrollDown,
///     ONE generic field: the M3 hide-on-scroll bar on Android, the Liquid
///     Glass pill-minimize on iOS 26
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/material3/m3_badges_demo.dart';
import 'screens/material3/m3_dynamic_color_demo.dart';
import 'screens/material3/m3_hide_on_scroll_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MaterialYouHome());
}

/// Three-row launcher built from the playground's own UI kit.
class MaterialYouHome extends StatelessWidget {
  const MaterialYouHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Material You',
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
            icon: MaterialSymbolsRounded.palette,
            tint: kAccentTeal,
            title: 'Dynamic Color',
            tagline: 'Material You device palette, into Dart',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const M3DynamicColorDemo()),
            ),
          ),
          const SizedBox(height: 12),
          DemoRow(
            icon: MaterialSymbolsRounded.badge,
            tint: kAccentRed,
            title: 'Live Badges',
            tagline: 'Real BadgeDrawable on tabs and actions',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const M3BadgesDemo()),
            ),
          ),
          const SizedBox(height: 12),
          DemoRow(
            icon: MaterialSymbolsRounded.swipe,
            tint: kAccentGreen,
            title: 'Hide-on-Scroll Bar',
            tagline: 'M3 motion, edge-to-edge — one field, two platforms',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const M3HideOnScrollDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
