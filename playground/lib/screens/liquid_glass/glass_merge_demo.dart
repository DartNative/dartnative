/// Liquid Glass — the material itself: interactive glass capsules and the
/// FLUID MERGE (`GlassEffectGroup` / `GlassEffectContainer`, real
/// `UIGlassEffect` + `UIGlassContainerEffect` views).
///
/// There is no platform-view island here: the capsules are ordinary
/// parents in ONE native hierarchy, their children are Dart widgets, and
/// the group merge spans your own Dart layout.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class GlassMergeDemo extends StatefulWidget {
  const GlassMergeDemo({super.key});

  @override
  State<GlassMergeDemo> createState() => _GlassMergeDemoState();
}

class _GlassMergeDemoState extends State<GlassMergeDemo> {
  bool _together = false;

  Widget _glassCircle(IconData icon) => GlassEffectContainer(
        borderRadius: BorderRadius.circular(32),
        interactive: true,
        tint: const Color(0x22FFFFFF),
        brightness: playgroundPalette.brightness,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Icon(icon, size: 26, color: kTextPrimary),
          ),
        ),
      );

  /// A/B pill for the interactive section: same glass, same content — only
  /// [interactive] differs, so the press response is the ONLY difference.
  Widget _glassPill(String label, {required bool interactive}) =>
      GlassEffectContainer(
        borderRadius: BorderRadius.circular(32),
        interactive: interactive,
        // Gold-tinted GLASS marks the pill that answers — the
        // warm tint brightens visibly under the press response.
        tint: interactive ? const Color(0x44FFD60A) : const Color(0x1AFFFFFF),
        brightness: playgroundPalette.brightness,
        child: SizedBox(
          width: 128,
          height: 64,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

  /// Style A/B for the material section: same glass, same content — only
  /// [GlassStyle] differs (regular = the standard frosted material; clear =
  /// the more transparent variant behind UIButton clearGlass()).
  Widget _stylePill(String label, GlassStyle style) => GlassEffectContainer(
        borderRadius: BorderRadius.circular(32),
        interactive: true,
        style: style,
        tint: const Color(0x1AFFFFFF),
        brightness: playgroundPalette.brightness,
        child: SizedBox(
          width: 128,
          height: 64,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

  /// A vivid gradient "stage" — glass is invisible over flat black; it needs
  /// colorful content behind it to refract (the lensing IS the demo).
  Widget _stage({required Widget child, required double height}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Deep tones under the dark theme; airier tints on light so the
            // wells don't sit as heavy navy slabs on a white page.
            colors: playgroundPalette.brightness == Brightness.dark
                ? const [
                    Color(0xFF1B2A6B),
                    Color(0xFF7A2E8D),
                    Color(0xFFE0562F),
                  ]
                : const [
                    Color(0xFF6FA5FF),
                    Color(0xFFC08CF2),
                    Color(0xFFFF9E6B),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Off-center highlights give the glass something to bend.
            Positioned(
              left: 24,
              top: 18,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(45),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: 14,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0x2264D2FF),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Center(child: child),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Glass & Fluid Merge',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? kBarBgGlass : kBarBg,
      ),
      backgroundColor: kHomeBg,
      body: ListView(
        children: [
          SizedBox(
              height: isIOS26
                  ? 8
                  : 12), // bar clearance is AUTOMATIC now (null-padding scrollable + extendBodyBehindAppBar); keep only the breathing gap
          const SectionHeader('FLUID MERGE'),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'Two interactive glass capsules in a GlassEffectGroup. Bring '
              'them together and the system fuses them into one blob — the '
              'compositor computes the merge from the real views.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          _stage(
            height: 170,
            child: GlassEffectGroup(
              spacing: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _glassCircle(CupertinoIcons.camera_fill),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeInOut,
                    width: _together ? 10 : 72,
                  ),
                  _glassCircle(CupertinoIcons.plus),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => setState(() => _together = !_together),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: kRowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _together ? 'Move apart' : 'Bring together',
                    style: const TextStyle(
                      color: kAccentBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SectionHeader('INTERACTIVE GLASS'),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'Press and HOLD each capsule: the gold-tinted one is '
              'interactive — it brightens and flexes under your finger '
              'with the system\'s gel response; the clear one stays inert. '
              'The labels inside are Dart Text widgets.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          _stage(
            height: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _glassPill('Interactive', interactive: true),
                const SizedBox(width: 20),
                _glassPill('Static', interactive: false),
              ],
            ),
          ),
          const SectionHeader('REGULAR VS CLEAR'),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, bottom: 10),
            child: Text(
              'The material comes in two styles: REGULAR (the standard '
              'frosted glass) and CLEAR — the more transparent variant '
              'Apple uses for clear-glass buttons. Same widget, one '
              'parameter.',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          _stage(
            height: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stylePill('Regular', GlassStyle.regular),
                const SizedBox(width: 20),
                _stylePill('Clear', GlassStyle.clear),
              ],
            ),
          ),
          if (!isIOS26)
            Padding(
              padding: EdgeInsets.only(left: 28, right: 28, top: 16),
              child: Text(
                'This device renders the graceful fallback — run on an '
                'iOS 26 device to see the live material.',
                style: TextStyle(color: kTextTertiary, fontSize: 12),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: 28, right: 28, top: 16),
            child: Text(
              'WHY NATIVE MATTERS — the glass here is a real view in your '
              'own hierarchy. (1) Your widgets render INSIDE the glass '
              'itself, as its children. (2) One tap drives the glass '
              'response and your Dart handler together — there is no '
              'boundary for the touch to cross. (3) Capsules merge across '
              'your own layout, around your own widgets. And because there '
              'is no separate layer to keep in sync, the material behaves '
              'under modals and during transitions the way the system '
              'intends.',
              style: TextStyle(color: kTextTertiary, fontSize: 12),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
