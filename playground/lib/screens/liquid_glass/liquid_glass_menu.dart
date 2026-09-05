/// Liquid Glass — sub-menu screen (iOS 26 material showcase).
///
/// Curates what the platform-view sandwich walls off from Flutter plugins
/// (verified against their source): plugins host native glass/bars only as
/// islands between Flutter layers — island content must itself be native,
/// controller-gated bar behaviors have no screens to attach to, and the
/// seams leak. DartNative has no island: one native hierarchy, so Dart
/// widgets live INSIDE the glass and the real bar machinery hosts them.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';
import 'bar_actions_demo.dart';
import 'bar_surfaces_demo.dart';
import 'floating_tab_bar_demo.dart';
import 'glass_merge_demo.dart';
import 'large_title_demo.dart';
import 'morphing_buttons_demo.dart';
import 'zoom_morph_demo.dart';
import '../material3/m3_search_appbar_demo.dart';

class LiquidGlassMenuScreen extends StatelessWidget {
  const LiquidGlassMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Liquid Glass',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? kBarBgGlass : kBarBg,
      ),
      body: ListView(
        children: [
          SizedBox(
              height: isIOS26
                  ? 8
                  : 12), // bar clearance is AUTOMATIC now (null-padding scrollable + extendBodyBehindAppBar); keep only the breathing gap
          if (!isIOS26)
            Padding(
              padding: EdgeInsets.only(left: 28, right: 28, bottom: 4),
              child: Text(
                'These demos showcase the iOS 26 Liquid Glass material — '
                'on this device they render with graceful fallbacks.',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ),
          const SectionHeader('THE MATERIAL'),
          DemoRow(
            icon: CupertinoIcons.circle_grid_hex_fill,
            tint: kAccentTeal,
            title: 'Glass & Fluid Merge',
            tagline: 'Capsules that melt together — real UIGlassEffect',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const GlassMergeDemo(),
                settings: '/liquid-glass-merge',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.arrow_up_left_arrow_down_right,
            tint: kAccentPurple,
            title: 'Zoom Morph',
            tagline: 'Tap a tile — it becomes the screen (system zoom)',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const ZoomMorphDemo(),
                settings: '/liquid-glass-zoom',
              ),
            ),
          ),
          const SectionHeader('THE BARS'),
          DemoRow(
            icon: CupertinoIcons.ellipsis_circle_fill,
            tint: kAccentBlue,
            title: 'Bar Actions & Menu Morph',
            tagline: 'Widgets inside glass pills; capsule→menu morph',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const BarActionsDemo(),
                settings: '/liquid-glass-bar-actions',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.arrow_merge,
            tint: kAccentGreen,
            title: 'Morphing Buttons',
            tagline: 'Bar buttons move & merge between screens',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const MorphingButtonsDemo(),
                settings: '/liquid-glass-morphing-buttons',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.square_stack_3d_up,
            tint: kAccentOrange,
            title: 'Bar Surfaces',
            tagline: 'Opaque · frosted glass · fully clear',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const BarSurfacesDemo(),
                settings: '/liquid-glass-surfaces',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.textformat_size,
            tint: kAccentPurple,
            title: 'Large Title & See-Through Bar',
            tagline: 'Native scroll-driven collapse + edge blur ramp',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const LargeTitleDemo(),
                settings: '/liquid-glass-large-title',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.rectangle_dock,
            tint: kAccentPink,
            title: 'Floating Tab Bar',
            tagline: 'Minimize on scroll · accessory · search pill',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const FloatingTabBarDemo(),
                settings: '/liquid-glass-tab-bar',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.search,
            tint: kAccentOrange,
            title: 'Search in the Bar',
            tagline: 'AppBar.searchBar — UISearchController from the bar',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3SearchAppBarDemo(),
                settings: '/material3-search-appbar',
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
