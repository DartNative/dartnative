import 'package:dartnative/dartnative.dart';

/// The app's two looks. Every themed screen reads its colors from the
/// active palette through ThemeState (see state/theme_state.dart), so a
/// theme flip is one notify away from repainting the whole app.
///
/// The onboarding and create profile screens deliberately do NOT theme:
/// they are dark by design, which is also a useful pattern to copy for
/// fixed look screens (a camera, a media viewer).
class Palette {
  final Brightness brightness;

  /// Screen background.
  final Color bg;

  /// Cards, drawer rows, input fields.
  final Color surface;

  /// The drawer panel.
  final Color drawerBg;

  /// The selected drawer item's pill. Clearly brighter than [drawerBg] so
  /// the current section reads at a glance.
  final Color drawerSelection;

  /// Primary text and icons.
  final Color text;

  /// Secondary text.
  final Color textSoft;

  /// Faint text (empty states, captions).
  final Color textFaint;

  /// State that has to stand out from the theme, like a saved note's heart.
  final Color accent;

  /// The avatar circle in the drawer header.
  final Color avatarBg;

  /// Hairline separators.
  final Color divider;

  /// The drawer's right edge, which is the only thing dividing it from the
  /// page when the two share a background. Stronger than [divider] for
  /// that reason.
  final Color drawerEdge;

  /// Note card surfaces, one per card, picked by the note's id so a note
  /// keeps its colour for life. Cool tones, muted enough that the text on
  /// top stays the primary thing on the card.
  final List<Color> cardColors;

  const Palette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.drawerBg,
    required this.drawerSelection,
    required this.text,
    required this.textSoft,
    required this.textFaint,
    required this.accent,
    required this.avatarBg,
    required this.divider,
    required this.drawerEdge,
    required this.cardColors,
  });
}

const kDarkPalette = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF101014),
  surface: Color(0xFF1C1C22),
  drawerBg: Color(0xFF101014),
  drawerSelection: Color(0xFF272730),
  text: Color(0xFFFFFFFF),
  textSoft: Color(0x99FFFFFF),
  textFaint: Color(0x66FFFFFF),
  accent: Color(0xFFFF453A),
  avatarBg: Color(0xFF3A3A44),
  divider: Color(0x14FFFFFF),
  drawerEdge: Color(0x33FFFFFF),
  // Lifted and saturated on purpose. Tinting near black (the first pass
  // sat around 15 percent lightness) reads as a hole in the page rather
  // than coloured paper, and low saturation down there just looks muddy.
  // These sit near 26 percent lightness with the hue pushed up, which is
  // where dark theme note apps keep their surfaces: clearly above the
  // background, clearly coloured, still quiet under white text.
  cardColors: [
    Color(0xFF4F6389), // slate
    Color(0xFF4B876F), // pine
    Color(0xFF635490), // indigo
    Color(0xFF43878C), // teal
    Color(0xFF80558D), // plum
    Color(0xFF487291), // steel
  ],
);

const kLightPalette = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFF4F4F6),
  surface: Color(0xFFFFFFFF),
  drawerBg: Color(0xFFF4F4F6),
  drawerSelection: Color(0xFFEDEDF0),
  text: Color(0xFF17171C),
  textSoft: Color(0x9917171C),
  textFaint: Color(0x6617171C),
  accent: Color(0xFFFF3B30),
  avatarBg: Color(0xFFD4D4DC),
  divider: Color(0x1417171C),
  drawerEdge: Color(0x2617171C),
  // A shade under the first pass, with the hue raised as they darken.
  // Pastels that light read as if they are shading when a large area of
  // one sits against the page, which is the eye and not a gradient.
  cardColors: [
    Color(0xFFC9D7F3), // slate
    Color(0xFFCAE4D8), // pine
    Color(0xFFD4CDF0), // indigo
    Color(0xFFC4E4EA), // teal
    Color(0xFFE4D0E8), // plum
    Color(0xFFC9DDEC), // steel
  ],
);
