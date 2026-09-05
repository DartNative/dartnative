/// Shared UI for the playground home tabs.
///
/// Three building blocks:
///   • [SectionHeader] — small uppercase label between row groups.
///   • [DemoRow] — compact list row: icon tile + title + one-line tagline +
///     chevron. Settings-style, scannable. `comingSoon: true` renders the row
///     dimmed with a SOON chip instead of a chevron.
///   • [ShowcaseCard] — tall visual card for the Showcase tab: gradient
///     preview band + title + one-line pitch + tag chips.
import 'package:dartnative/dartnative.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────
//
// Playground theming in the smallest idiomatic shape:
//   • [PlaygroundPalette] — a plain immutable color set (dark + light consts).
//   • [PlaygroundTheme] — an InheritedWidget carrying the active palette. The
//     home shell hosts it; widgets read `PlaygroundTheme.of(context)` and
//     rebuild automatically when the palette flips (updateShouldNotify).
//   • [playgroundPalette] — module-global mirror of the active palette. The
//     k* getters below read it, so screens OUTSIDE the shell's tree (pushed
//     routes run their own element tree) pick up the current palette when
//     they build. Flip it via the home shell's sun/moon action.

class PlaygroundPalette {
  const PlaygroundPalette({
    required this.brightness,
    required this.homeBg,
    required this.barBg,
    required this.barBgGlass,
    required this.rowBg,
    required this.tileBg,
    required this.chipBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.chevron,
    required this.codeGreen,
    required this.segBg,
    required this.segTint,
  });

  final Brightness brightness;
  final Color homeBg;
  final Color barBg;

  /// iOS 26 glass variant of [barBg]: alpha < 1 opts the AppBar into the real
  /// Liquid Glass material — the bar keeps its tint while content scrolling
  /// behind it stays faintly visible through the frost. Raise the alpha for a
  /// more opaque bar.
  final Color barBgGlass;
  final Color rowBg;
  final Color tileBg;
  final Color chipBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color chevron;

  /// Code-snippet / terminal green — bright on dark, deepened on light so it
  /// stays readable on the pale code boxes.
  final Color codeGreen;

  /// Segmented-control container / selected-segment colors — explicit so the
  /// control never depends on the platform's appearance resolution.
  final Color segBg;
  final Color segTint;
}

/// Dark palette — the playground's original look. Values are borrowed from
/// Apple's dark system palette but apply to BOTH platforms identically.
const kDarkPalette = PlaygroundPalette(
  brightness: Brightness.dark,
  homeBg: Color(0xFF000000),
  barBg: Color(0xFF1C1C1E),
  barBgGlass: Color(0xD91C1C1E),
  rowBg: Color(0xFF1C1C1E),
  tileBg: Color(0xFF2C2C2E),
  chipBg: Color(0xFF3A3A3C),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFF8E8E93),
  textTertiary: Color(0xFF636366),
  chevron: Color(0xFF48484A),
  codeGreen: Color(0xFF30D158),
  segBg: Color(0xFF2C2C2E),
  segTint: Color(0xFF636366),
);

/// Light palette — iOS light system surfaces. Like [kDarkPalette], shared by
/// both platforms.
const kLightPalette = PlaygroundPalette(
  brightness: Brightness.light,
  homeBg: Color(0xFFFFFFFF),
  barBg: Color(0xFFFFFFFF),
  barBgGlass: Color(0xD9FFFFFF),
  rowBg: Color(0xFFF2F2F7),
  tileBg: Color(0xFFE5E5EA),
  chipBg: Color(0xFFE5E5EA),
  textPrimary: Color(0xFF111111),
  textSecondary: Color(0xFF6B6B70),
  textTertiary: Color(0xFF8E8E93),
  chevron: Color(0xFFC7C7CC),
  codeGreen: Color(0xFF1E8E3E),
  segBg: Color(0xFFEEEEEF),
  segTint: Color(0xFFFFFFFF),
);

PlaygroundPalette _playgroundPalette = kDarkPalette;
bool _paletteAppearanceApplied = false;

/// The active palette. First read pins the app-wide native appearance to its
/// brightness so native controls match the palette on every route.
PlaygroundPalette get playgroundPalette {
  if (!_paletteAppearanceApplied) {
    _paletteAppearanceApplied = true;
    setAppBrightness(_playgroundPalette.brightness);
  }
  return _playgroundPalette;
}

/// Switch the active palette and re-pin the native appearance.
set playgroundPalette(PlaygroundPalette p) {
  _playgroundPalette = p;
  _paletteAppearanceApplied = true;
  setAppBrightness(p.brightness);
}

class PlaygroundTheme extends InheritedWidget {
  const PlaygroundTheme(
      {super.key, required this.palette, required super.child});

  final PlaygroundPalette palette;

  /// The active palette; registers [context] for rebuild on theme flips.
  /// Falls back to [playgroundPalette] outside the shell's tree.
  static PlaygroundPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlaygroundTheme>()?.palette ??
      playgroundPalette;

  @override
  bool updateShouldNotify(covariant PlaygroundTheme oldWidget) =>
      palette != oldWidget.palette;
}

// ── Palette shorthands ────────────────────────────────────────────────────────
//
// Getter aliases over the ACTIVE palette, so call sites read `kRowBg` instead
// of threading a palette everywhere. Read at build time — a screen picks up
// the current theme whenever it (re)builds.

Color get kHomeBg => playgroundPalette.homeBg;
Color get kSegBg => playgroundPalette.segBg;
Color get kSegTint => playgroundPalette.segTint;
Color get kBarBg => playgroundPalette.barBg;
Color get kBarBgGlass => playgroundPalette.barBgGlass;
Color get kRowBg => playgroundPalette.rowBg;
Color get kTileBg => playgroundPalette.tileBg;
Color get kChipBg => playgroundPalette.chipBg;
Color get kTextPrimary => playgroundPalette.textPrimary;
Color get kTextSecondary => playgroundPalette.textSecondary;
Color get kTextTertiary => playgroundPalette.textTertiary;
Color get kChevron => playgroundPalette.chevron;
Color get kCodeGreen => playgroundPalette.codeGreen;

// ── System chrome ─────────────────────────────────────────────────────────────

/// Theme-following system chrome for demo screens: transparent bars, status/
/// nav icon brightness matching the active palette. Use from `initState`:
///
/// ```dart
/// SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
/// ```
SystemUiOverlayStyle playgroundOverlayStyle({Color? navBarColor}) {
  final dark = playgroundPalette.brightness == Brightness.dark;
  final iconBrightness = dark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarBrightness: playgroundPalette.brightness,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    systemNavigationBarIconBrightness: iconBrightness,
    systemNavigationBarColor: navBarColor ?? Colors.transparent,
    systemNavigationBarDividerColor: navBarColor ?? Colors.transparent,
  );
}

// ── Tab list clearances ───────────────────────────────────────────────────────
//
// On iOS 26 the home Scaffold uses extendBody: the tab lists run edge-to-edge
// behind the AppBar and the floating glass tab-bar pill, so the first/last
// rows need explicit clearance. Elsewhere the bars are solid and outside the
// body — plain gaps suffice.

double tabListTopGap(BuildContext context, {double fallback = 0}) =>
    isIOS26 ? MediaQuery.paddingOf(context).top + kToolbarHeight + 8 : fallback;

double tabListBottomGap(BuildContext context) =>
    isIOS26 ? 66 + MediaQuery.paddingOf(context).bottom : 20;

const kAccentBlue = Color(0xFF0A84FF);
const kAccentGreen = Color(0xFF30D158);
const kAccentOrange = Color(0xFFFF9F0A);
const kAccentRed = Color(0xFFFF453A);
const kAccentPurple = Color(0xFFBF5AF2);
const kAccentTeal = Color(0xFF64D2FF);
const kAccentYellow = Color(0xFFFFD60A);
const kAccentPink = Color(0xFFFF375F);
const kAccentIndigo = Color(0xFF5E5CE6);

// ── Section header ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = PlaygroundTheme.of(context); // rebuilds this row on theme flips
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 28, top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: t.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Demo row ──────────────────────────────────────────────────────────────────

class DemoRow extends StatelessWidget {
  const DemoRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.tagline,
    this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String tagline;
  final void Function(BuildContext ctx)? onTap;

  /// Renders the row dimmed (grey icon/text) with a SOON chip instead of the
  /// chevron, and disables the tap — the placeholder style for demos whose
  /// plugin examples aren't ported yet. Keep this around even when unused:
  ///
  /// ```dart
  /// const DemoRow(
  ///   icon: CupertinoIcons.film_fill,
  ///   tint: kAccentRed,
  ///   title: 'Lottie Player',
  ///   tagline: 'dartnative_lottie (Skottie) examples',
  ///   comingSoon: true,
  /// ),
  /// ```
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final t = PlaygroundTheme.of(context); // rebuilds this row on theme flips
    final active = !comingSoon && onTap != null;
    return GestureDetector(
      onTap: active ? () => onTap!(context) : null,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.rowBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.tileBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon,
                    size: 18, color: comingSoon ? t.textTertiary : tint),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: comingSoon ? t.textSecondary : t.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tagline,
                    style: TextStyle(
                      color: comingSoon ? t.textTertiary : t.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (comingSoon)
              const TagChip('SOON')
            else
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: t.chevron,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = PlaygroundTheme.of(context); // rebuilds this chip on theme flips
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: t.chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: t.textSecondary, fontSize: 11),
      ),
    );
  }
}

// ── Showcase card ─────────────────────────────────────────────────────────────

class ShowcaseCard extends StatelessWidget {
  const ShowcaseCard({
    super.key,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.pitch,
    required this.tags,
    required this.onTap,
  });

  /// Two colors for the preview band, top-left → bottom-right.
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String pitch;
  final List<String> tags;
  final void Function(BuildContext ctx) onTap;

  @override
  Widget build(BuildContext context) {
    final t = PlaygroundTheme.of(context); // rebuilds this card on theme flips
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        decoration: BoxDecoration(
          color: t.rowBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Center(
                // Gradient band keeps white glyphs in both themes.
                child: Icon(icon, size: 44, color: const Color(0xFFFFFFFF)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pitch,
                    style: TextStyle(color: t.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < tags.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        TagChip(tags[i]),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
