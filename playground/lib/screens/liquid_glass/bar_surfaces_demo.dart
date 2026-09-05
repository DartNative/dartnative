/// Liquid Glass — the BAR SURFACES: the one look decision every iOS 26 app
/// makes. Three surfaces, one knob:
///   • OPAQUE   — a solid `backgroundColor`; content disappears beneath.
///   • FROST    — a translucent color (alpha < 1) routes to the NATIVE
///                frosted treatment (system chrome blur + tint); content
///                stays faintly visible through real glass. The frost
///                blurs what's beneath and transmits ~(1 − bar alpha) of
///                it: the BAR color's alpha is the frost level, and the
///                content must carry full-strength contrast to read
///                through — alpha on content washes it toward the
///                background and starves the glass.
///   • CLEAR    — NO `backgroundColor`: the bar surface is fully
///                see-through, glass lives on the controls, and the system
///                scroll-edge ramp keeps the region legible.
/// The bar surface is a creation-time appearance, so each surface is a
/// pushed variant of the same screen (also a bonus beat: the glass rides
/// every push/pop transition).
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class BarSurfacesDemo extends StatelessWidget {
  const BarSurfacesDemo({super.key});

  Widget _pushRow(BuildContext context, String title, String tagline,
          _Surface surface) =>
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRoute(
              builder: (_) => _SurfaceScreen(surface: surface),
              settings: '/liquid-glass-surface-${surface.name}',
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kRowBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        style: TextStyle(color: kTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: kChevron,
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Bar Surfaces',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? kBarBgGlass : kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        child: ListView(
          children: [
            SizedBox(
                height: isIOS26
                    ? 8
                    : 12), // bar clearance is AUTOMATIC now (null-padding scrollable + extendBodyBehindAppBar); keep only the breathing gap
            Padding(
              padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
              child: Text(
                'One AppBar, three surfaces — the look decision every '
                'iOS 26 app makes. Push each variant and scroll the same '
                'list to compare how content reads through the bar.',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ),
            _pushRow(context, 'Opaque',
                'Solid color — content disappears beneath', _Surface.opaque),
            _pushRow(context, 'Frosted glass',
                'Translucent color → native blur + tint', _Surface.frost),
            _pushRow(context, 'Fully clear',
                'No color — see-through + scroll-edge ramp', _Surface.clear),
            Padding(
              padding: EdgeInsets.only(left: 28, right: 28, top: 16),
              child: Text(
                'WHY NATIVE MATTERS — frost and the scroll-edge ramp are '
                'system materials reacting to YOUR content scrolling '
                'beneath the bar. The surface is the screen\'s real bar, '
                'so it stays live through transitions and modals — '
                'including the push you just performed.',
                style: TextStyle(color: kTextTertiary, fontSize: 12),
              ),
            ),
            SizedBox(height: tabListBottomGap(context)),
          ],
        ),
      ),
    );
  }
}

enum _Surface { opaque, frost, clear }

/// One screen, parameterized by surface. The colorful list runs UNDER the
/// bar (extendBodyBehindAppBar) so each surface has content to act on.
class _SurfaceScreen extends StatelessWidget {
  const _SurfaceScreen({required this.surface});

  final _Surface surface;

  static const _rows = [
    (Color(0xFF0A84FF), 'Ocean'),
    (Color(0xFF30D158), 'Meadow'),
    (Color(0xFFFF9F0A), 'Amber'),
    (Color(0xFFFF453A), 'Coral'),
    (Color(0xFFBF5AF2), 'Violet'),
    (Color(0xFF64D2FF), 'Sky'),
    (Color(0xFFFFD60A), 'Sun'),
    (Color(0xFFFF375F), 'Rose'),
  ];

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.paddingOf(context).top;
    final (title, blurb, barColor) = switch (surface) {
      _Surface.opaque => (
          'Opaque',
          'Solid bar: scroll — rows vanish beneath the surface. The '
              'classic pre-glass look, still first-class.',
          kRowBg as Color?,
        ),
      _Surface.frost => (
          'Frosted',
          'This bar passes the glass color at 60% alpha. The alpha of '
              'your backgroundColor IS the frost knob: lower shows more '
              'of the rows scrolling beneath, higher hides them behind '
              'heavier glass.',
          // The knob, visibly turned: the palette glass tone re-issued
          // at 60% alpha (the palette default is a heavier 85%).
          kBarBgGlass.withValues(alpha: 0.6) as Color?,
        ),
      _Surface.clear => (
          'Clear',
          'No backgroundColor: a fully see-through bar. Glass lives on '
              'the controls; the system scroll-edge ramp keeps the title '
              'legible as rows pass beneath.',
          null,
        ),
    };
    return Scaffold(
      // Content must run under the bar for the surface to act on it.
      extendBodyBehindAppBar: true,
      // Theme trait — else status chrome follows the DEVICE trait.
      brightness: playgroundPalette.brightness,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: barColor,
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        padding: EdgeInsets.only(top: padTop + 66, bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Text(
              blurb,
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          for (var i = 0; i < 5; i++)
            for (final (color, name) in _rows)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    // Full strength — the frost needs contrast to
                    // transmit (see the FROST note in the header).
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
