/// Material 3 — sub-menu screen (the Android twin of the Liquid Glass
/// section). The headline is the framework's adaptive-first thesis: the
/// SAME generic Dart API lowers to each platform's native design language —
/// `scrollBehavior` gives the Liquid Glass pill-minimize on iOS 26 and the
/// M3 hide-on-scroll slide here, from one Scaffold. Every component on
/// these screens is the real com.google.android.material widget
/// (BottomNavigationView, BadgeDrawable, PopupMenu) — not a re-drawing.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';
import 'm3_badges_demo.dart';
import 'm3_menus_demo.dart';
import 'm3_hide_on_scroll_demo.dart';
import 'm3_large_top_bar_demo.dart';
import 'm3_dynamic_color_demo.dart';
import 'm3_progress_demo.dart';
import 'm3_switches_demo.dart';
import 'm3_sliders_demo.dart';
import 'm3_search_demo.dart';
import 'm3_search_appbar_demo.dart';

class Material3MenuScreen extends StatelessWidget {
  const Material3MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Material 3',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: ListView(
        children: [
          SizedBox(height: tabListTopGap(context)),
          const SectionHeader('THE COMPONENTS'),
          DemoRow(
            icon: MaterialSymbolsRounded.swipe,
            tint: kAccentGreen,
            title: 'Hide-on-Scroll Bar',
            tagline: 'M3 motion, edge-to-edge — one field, two platforms',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3HideOnScrollDemo(),
                settings: '/material3-hide-on-scroll',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.badge,
            tint: kAccentRed,
            title: 'Live Badges',
            tagline: 'Real BadgeDrawable on tabs and actions',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3BadgesDemo(),
                settings: '/material3-badges',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.menu,
            tint: kAccentBlue,
            title: 'Anchored Menu',
            tagline: 'Material popup from a toolbar action',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3MenusDemo(),
                settings: '/material3-menus',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.title,
            tint: kAccentPurple,
            title: 'Large Top App Bar',
            tagline: 'M3 collapsing top bar — the largeTitle twin',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3LargeTopBarDemo(),
                settings: '/material3-large-top-bar',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.palette,
            tint: kAccentTeal,
            title: 'Dynamic Color',
            tagline: 'Material You device palette, into Dart',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3DynamicColorDemo(),
                settings: '/material3-dynamic-color',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.percent,
            tint: kAccentBlue,
            title: 'Progress Indicators',
            tagline: 'The wavy M3 style — one android: field',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3ProgressDemo(),
                settings: '/material3-progress',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.tune,
            tint: kAccentOrange,
            title: 'Sliders',
            tagline: 'The M3 handle-and-gap anatomy — one android: field',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3SlidersDemo(),
                settings: '/material3-sliders',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.toggle_on,
            tint: kAccentGreen,
            title: 'Switches',
            tagline: 'The real MaterialSwitch — thumb grows, check mark',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3SwitchesDemo(),
                settings: '/material3-switches',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.search,
            tint: kAccentPurple,
            title: 'Search App Bar',
            tagline: 'AppBar.searchBar — the bar region IS the pill',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3SearchAppBarDemo(),
                settings: '/material3-search-appbar',
              ),
            ),
          ),
          DemoRow(
            icon: MaterialSymbolsRounded.search,
            tint: kAccentOrange,
            title: 'Expanding Search Pill',
            tagline: 'A body-placed SearchBar + the SearchView morph',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const M3SearchDemo(),
                settings: '/material3-search',
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
