/// Playground home — native bottom tab bar (UITabBar / BottomNavigationView)
/// over five tabs:
///
///   Showcase — curated best-of reel (tall visual cards)
///   Widgets  — text & input, components, layout, scrollables, state
///   Graphics — canvas (Skia + native) and motion
///   Media    — images, video, audio
///   System   — storage, notifications, accounts, device
///
/// Tab bodies live in an [IndexedStack]: all five stay mounted, so each tab
/// keeps its scroll position and state while switching.
///
/// The shell also hosts:
///   • the theme — [PlaygroundTheme] with a sun/moon AppBar action flipping
///     dark ↔ light (see demo_ui.dart for the pattern);
///   • a [Scaffold.drawer] (hamburger in the AppBar) whose items mirror the
///     tabs — tapping one switches the tab programmatically.
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

import 'demo_ui.dart';
import 'graphics_tab.dart';
import 'media_tab.dart';
import 'showcase_tab.dart';
import 'system_tab.dart';
import 'widgets_tab.dart';

/// SharedPreferences key persisting the theme across launches.
const _kThemePref = 'playground_dark_theme';

/// Restores the persisted theme into [playgroundPalette]. Call BEFORE
/// [runApp]: hot restart resets the global to dark, and a restart from a
/// pushed screen builds that screen's tree immediately — an async restore
/// inside the shell would repaint the home but never a pushed route.
Future<void> restorePlaygroundTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final dark = prefs.getBool(_kThemePref) ?? true;
  playgroundPalette = dark ? kDarkPalette : kLightPalette;
  // Tell the NATIVE side which brightness the app is in. The playground
  // drives its own palette instead of App.theme (which would call this for
  // us), so without it the native Material theme stays on follow-system:
  // every M3 control the framework builds with DEFAULT colours — the tab
  // bar's selected pill, checkboxes, sliders, menus — resolves against the
  // SYSTEM brightness and cannot follow this app's light/dark toggle.
  setAppBrightness(dark ? Brightness.dark : Brightness.light);
}

class PlaygroundHome extends StatefulWidget {
  const PlaygroundHome({super.key});

  @override
  State<PlaygroundHome> createState() => _PlaygroundHomeState();
}

class _PlaygroundHomeState extends State<PlaygroundHome> {
  int _tab = 0;

  /// The device's Material You dark scheme, read once — used for the tab
  /// bar's selected-tab tint in dark theme (see the BottomNavigationBar
  /// below). Null on iOS and pre-Android-12 devices, which fall back to the
  /// framework's own default.
  static final ColorScheme? _dynamicScheme =
      DynamicColor.colorScheme(brightness: Brightness.dark);

  // The global is already restored (main awaits restorePlaygroundTheme).
  bool _dark = playgroundPalette.brightness == Brightness.dark;

  PlaygroundPalette get _palette => _dark ? kDarkPalette : kLightPalette;

  @override
  void initState() {
    super.initState();
    _applySystemChrome();
  }

  /// System strip (status + nav bar) follows the theme. The nav strip is a
  /// WINDOW property painted over everything — while the slideOver drawer
  /// is open the bar-colored strip would cover the sliding card's shadow
  /// (and the drawer) in the bottom band, so it goes transparent for the
  /// open state and restores on close.
  void _applySystemChrome({bool drawerOpen = false}) {
    // Keep the Navigator's push-default in sync with the theme.
    SystemChrome.defaultStyle = playgroundOverlayStyle();
    final barColor = drawerOpen ? Colors.transparent : _palette.barBg;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: _dark ? Brightness.dark : Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _dark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          _dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isIOS26 ? Colors.transparent : barColor,
      systemNavigationBarDividerColor: isIOS26 ? Colors.transparent : barColor,
    ));
  }

  void _toggleTheme() {
    setState(() {
      _dark = !_dark;
      // Mirror into the module global so pushed routes (their own element
      // trees, outside this PlaygroundTheme) build with the same palette.
      playgroundPalette = _palette;
    });
    // Native Material controls resolve their default colours from the
    // native theme — keep it in step with the palette (see
    // restorePlaygroundTheme).
    setAppBrightness(_dark ? Brightness.dark : Brightness.light);
    _applySystemChrome();
    // Persist for the next launch (fire-and-forget).
    SharedPreferences.getInstance().then((p) => p.setBool(_kThemePref, _dark));
  }

  void _selectTab(int i, BuildContext drawerCtx) {
    setState(() => _tab = i);
    Scaffold.of(drawerCtx).closeDrawer();
  }

  static const _titles = ['Showcase', 'Widgets', 'Graphics', 'Media', 'System'];

  static const _icons = <IconData>[
    CupertinoIcons.star_fill,
    CupertinoIcons.square_grid_2x2,
    CupertinoIcons.paintbrush,
    CupertinoIcons.play_rectangle,
    CupertinoIcons.cube_box,
  ];

  Widget _drawerItem(int i, BuildContext ctx) {
    final t = _palette;
    final selected = _tab == i;
    return GestureDetector(
      onTap: () => _selectTab(i, ctx),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        // Squircle (continuous corner) — CALayer.cornerCurve on iOS, the
        // DNSquircle superellipse path on Android.
        decoration: ShapeDecoration(
          color: selected ? t.tileBg : Colors.transparent,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        child: Row(
          children: [
            Icon(_icons[i],
                size: 20, color: selected ? kAccentBlue : t.textSecondary),
            const SizedBox(width: 12),
            Text(
              _titles[i],
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawer() {
    final t = _palette;
    return Drawer(
      backgroundColor: t.barBg,
      child: Builder(
        builder: (ctx) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar header (same asset as the Hero demo) ────────────────
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 20, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kAccentBlue, width: 2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/avatar.jpg',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lisa Taylor',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@lisataylor',
                          style:
                              TextStyle(color: t.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Tabs — switching from here showcases programmatic
              //    tab selection (setState on the shell's _tab). ─────────────
              for (var i = 0; i < _titles.length; i++) _drawerItem(i, ctx),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _palette;
    // Tabs are created per build (NOT const) so a theme flip re-runs their
    // build — const instances would be identical() across rebuilds and the
    // reconciler would skip them, leaving stale colors.
    final tabs = <Widget>[
      ShowcaseTab(),
      WidgetsTab(),
      GraphicsTab(),
      MediaTab(),
      SystemTab(),
    ];
    return PlaygroundTheme(
      palette: t,
      child: Scaffold(
        backgroundColor: t.homeBg,
        // Declare the theme's trait so system bar chrome matches it during
        // transient states (avoids a wrong-color bar flash on tab switch).
        brightness: t.brightness,
        // iOS 26: run the tab lists edge-to-edge behind the floating glass
        // tab-bar pill (the bar area is transparent there). Tab lists reserve
        // their own top/bottom clearance via tabListTopGap/tabListBottomGap.
        // Pre-26 iOS and Android keep the solid bar above the body.
        extendBody: isIOS26,
        drawer: _drawer(),
        drawerStyle: DrawerStyle.slideOver,
        // Open fires as the slide STARTS (shadow visible from frame one);
        // close fires when the card lands — the strip restores after.
        onDrawerChanged: (open) => _applySystemChrome(drawerOpen: open),
        // Dark mode: the default soft-black edge shadow is invisible on the
        // dark drawer surface — use a faint light glow so the card edge reads.
        slideOverStyle: _dark
            ? const SlideOverStyle(
                shadow: BoxShadow(
                  color: Color(0x38FFFFFF),
                  blurRadius: 64,
                  offset: Offset(-2, 0),
                ),
              )
            : const SlideOverStyle(
                // Wider and darker than the framework default — a full-height
                // card needs more than the default's gentle edge. 22% is also
                // the most an Android elevation shadow can actually render
                // (the platform multiplies shadow alpha by the theme's
                // ambient/spot values); asking for more silently flattens.
                shadow: BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 64,
                  offset: Offset(-2, 0),
                ),
              ),
        appBar: AppBar(
          leading: Builder(
            builder: (ctx) => IconButton(
              icon:
                  Icon(CupertinoIcons.line_horizontal_3, color: t.textPrimary),
              onPressed: () => Scaffold.of(ctx).toggleDrawer(),
            ),
          ),
          title: Text(
            _titles[_tab],
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _dark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
                color: t.textPrimary,
              ),
              onPressed: _toggleTheme,
            ),
          ],
          // iOS 26: glass bar — tab lists scroll behind it, faintly visible
          // through the frost.
          backgroundColor: isIOS26 ? t.barBgGlass : t.barBg,
        ),
        body: IndexedStack(index: _tab, children: tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          backgroundColor: t.barBg,
          // LIGHT: no override — the framework's M3 default
          // (`secondaryContainer`, a pale wallpaper tint) reads beautifully
          // on a white bar.
          // DARK: `secondaryContainer` is a DARK brown by M3 design, which
          // disappears into this palette's pure-black bar. Take the light
          // end of the SAME wallpaper palette instead (`primary` is a light
          // tone in dark schemes) so the tab still says "Material You" but
          // actually reads. Null on devices without a dynamic palette →
          // framework default.
          indicatorColor: _dark ? _dynamicScheme?.primary : null,
          selectedIconColor: _dark ? _dynamicScheme?.onPrimary : null,
          iconColor: t.textSecondary,
          labelFontStyle: TextStyle(fontSize: 11, color: t.textSecondary),
          selectedLabelFontStyle: TextStyle(fontSize: 11, color: t.textPrimary),
          items: [
            BottomNavigationBarItem(
              label: 'Showcase',
              icon: const Icon(CupertinoIcons.star_fill),
            ),
            BottomNavigationBarItem(
              label: 'Widgets',
              icon: const Icon(CupertinoIcons.square_grid_2x2),
            ),
            BottomNavigationBarItem(
              label: 'Graphics',
              icon: const Icon(CupertinoIcons.paintbrush),
            ),
            BottomNavigationBarItem(
              label: 'Media',
              icon: const Icon(CupertinoIcons.play_rectangle),
            ),
            BottomNavigationBarItem(
              label: 'System',
              icon: const Icon(CupertinoIcons.cube_box),
            ),
          ],
        ),
      ),
    );
  }
}
