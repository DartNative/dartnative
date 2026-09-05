/// DartNative tutorial — Liquid Glass, the real one.
///
/// Two screens live under lib/screens/liquid_glass/ (demo_ui.dart is the
/// small shared UI kit they build on):
///   • glass_merge_demo.dart — the material itself: interactive
///     GlassEffectContainer capsules with Dart children, the fluid merge
///     (GlassEffectGroup), and regular vs clear styles, under a frosted bar
///   • large_title_demo.dart — the fully clear iOS 26 bar with the native
///     large-title collapse over an ordinary Dart ListView
///
/// Everywhere else (Android, older iOS) the same code renders a graceful
/// translucent fallback — `isIOS26` lets you annotate when you care.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/liquid_glass/glass_merge_demo.dart';
import 'screens/liquid_glass/large_title_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const LiquidGlassHome());
}

/// Two-row launcher built from the shared UI kit.
class LiquidGlassHome extends StatelessWidget {
  const LiquidGlassHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Liquid Glass',
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
            icon: CupertinoIcons.circle_grid_hex_fill,
            tint: kAccentTeal,
            title: 'Glass & fluid merge',
            tagline: 'Capsules that melt together — real UIGlassEffect',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const GlassMergeDemo()),
            ),
          ),
          const SizedBox(height: 12),
          DemoRow(
            icon: CupertinoIcons.textformat_size,
            tint: kAccentPurple,
            title: 'Clear large title',
            tagline: 'Native scroll-driven collapse + edge blur ramp',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const LargeTitleDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
