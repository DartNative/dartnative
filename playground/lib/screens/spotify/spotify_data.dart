/// Content, palette, type and measurements of the Spotify demo.
///
/// The screen recreates Spotify's now-playing screen. Every distance below
/// was measured on a recording of the real app on a 402 x 874 pt iPhone, so
/// the numbers are points on that screen; the layout keeps them on other
/// sizes and anchors the player's controls to the bottom of the video.
library;

import 'package:dartnative/dartnative.dart';

// ── The measured screen ─────────────────────────────────────────────────────

/// The real app's screen, in points: every measured position is on it.
const kSpScreenWidth = 402.0;
const kSpScreenHeight = 874.0;

/// A measured y as a distance from the bottom of the measured screen.
double spFromScreenBottom(double y) => kSpScreenHeight - y;

/// A measured x as a distance from the right of the measured screen.
double spFromScreenRight(double x) => kSpScreenWidth - x;

// ── Assets ──────────────────────────────────────────────────────────────────

/// Only a short sample of the original track, for the demo.
const kSpSong = 'assets/spotify/spotify_demo_track.mp3';

/// A few seconds of the performance, cropped to portrait, looping silently
/// behind the player the way a Spotify Canvas does.
const kSpCanvas = 'assets/spotify/canvas_loop.mp4';
const kSpCanvasPoster = 'assets/spotify/images/canvas_poster.jpg';

/// Timed lyrics, LRC format: one `[mm:ss.xx] line` per sung line.
const kSpLyrics = 'assets/spotify/lyrics.lrc';

/// Added to every lyrics timestamp: a file timed against another recording
/// of the song lines up with this one by changing this value alone.
const kSpLyricsOffset = Duration.zero;

const kSpCover = 'assets/spotify/images/cover.jpg';
const kSpArtistPhoto = 'assets/spotify/images/artist.jpg';
const kSpEventImage = 'assets/spotify/images/live_event.jpg';

// ── Content ─────────────────────────────────────────────────────────────────

const kSpContext = 'Liked Songs';
const kSpTitle = 'Valerie (feat. Amy Winehouse) - Version Revisited';
const kSpArtists = 'Mark Ronson, Amy Winehouse';
const kSpArtist = 'Amy Winehouse';
const kSpListeners = '25M monthly listeners';
const kSpBio =
    'Amy Winehouse brought classic soul, jazz and girl-group pop back to the '
    'charts with a voice that sounded like no one else. Back to Black made '
    'her one of the defining artists of her generation, and her songs '
    'still find new listeners every day.';

class SpExploreTile {
  const SpExploreTile(this.label, this.image);
  final String label;
  final String image;
}

const kSpExplore = [
  SpExploreTile('Songs by $kSpArtist', 'assets/spotify/images/explore_1.jpg'),
  SpExploreTile('Similar to $kSpArtist', 'assets/spotify/images/explore_2.jpg'),
  SpExploreTile('Similar to Valerie (feat. Amy Winehouse)',
      'assets/spotify/images/explore_3.jpg'),
];

class SpCredit {
  const SpCredit(this.name, this.roles, {this.followable = true});
  final String name;
  final String roles;
  final bool followable;
}

const kSpCredits = [
  SpCredit('Mark Ronson', 'Main Artist, Producer'),
  SpCredit('Amy Winehouse', 'Featured Artist'),
  SpCredit('Sean Payne', 'Composer, Lyricist', followable: false),
];

const kSpEventArtist = 'Mark Ronson';
const kSpEventDate = 'Wed, Oct 21, 19:00';
const kSpEventVenue = 'Roundhouse, London';

class SpMerch {
  const SpMerch(this.title, this.image);
  final String title;
  final String image;
}

const kSpMerch = [
  SpMerch('Version | Vinyl 2LP', 'assets/spotify/images/merch_vinyl.jpg'),
  SpMerch('Version | CD', 'assets/spotify/images/merch_cd.jpg'),
];

// ── Palette ─────────────────────────────────────────────────────────────────

const kSpBg = Color(0xFF121212);
const kSpCard = Color(0xFF242424);
const kSpEventBody = Color(0xFF1D1D1D);

/// The lyrics colour, taken from the artwork in the real app.
const kSpLyricsRed = Color(0xFFDE2719);
const kSpLyricsButton = Color(0xFF951B14);

/// The mini player that takes the top once the controls scroll away.
const kSpHeader = Color(0xFF49100C);

const kSpGreen = Color(0xFF1ED760);
const kSpWhite = Color(0xFFFFFFFF);
const kSpBlack = Color(0xFF000000);
const kSpGrey = Color(0xFFB3B3B3);
const kSpOutline = Color(0xFF727272);

/// Secondary text over the video and the lyrics.
const kSpMuted = Color(0xB3FFFFFF);

/// The unplayed part of a progress bar.
const kSpTrack = Color(0x29FFFFFF);

// ── Type ────────────────────────────────────────────────────────────────────

/// Figtree, a close free match for Spotify's typeface. The family is named
/// per weight (`Figtree-Bold`), the font's own name on both platforms.
/// Figtree runs a little wider than Spotify's face, so every style carries
/// a slight negative tracking that keeps lines breaking where the app's do.
TextStyle spText(
  double size, {
  String weight = 'Regular',
  Color color = kSpWhite,
  double? height,
}) =>
    TextStyle(
      fontFamily: 'Figtree-$weight',
      fontSize: size,
      letterSpacing: -0.016 * size,
      color: color,
      height: height,
    );

/// The lyrics, on the card and full screen: 24 pt on a 36.7 pt line.
const double kSpLyricSize = 24;
const double kSpLyricPitch = 36.7;

// ── Measurements (pt) ───────────────────────────────────────────────────────

/// Side margin of the cards.
const double kSpMargin = 16.67;

/// Space between two cards.
const double kSpGap = 24;

/// Inner padding of a card.
const double kSpPad = 16.67;

const double kSpCardRadius = 12;

/// The lyrics card peeks this far over the bottom of the video.
const double kSpLyricsPeek = 50.7;
const double kSpLyricsCardHeight = 325.4;

/// Height of the mini player under the status bar.
const double kSpMiniHeight = 68;

/// The player column's width, given by the screen: the whole screen, or
/// the left pane on a wide one. Every width inside is worked out from it.
class SpLayout extends InheritedWidget {
  const SpLayout({
    super.key,
    required this.width,
    this.left = 0,
    this.right = 0,
    required super.child,
  });

  /// The column edge to edge: the video and the page's colour span it.
  final double width;

  /// The safe area at the column's sides, such as iPhone Duo's vertical bar:
  /// text and controls stay between them.
  final double left;
  final double right;

  /// The width text and controls are laid out in.
  double get contentWidth => width - left - right;

  /// The cards' width, inside their margins.
  double get cardWidth => contentWidth - kSpMargin * 2;

  static SpLayout of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SpLayout>()!;

  @override
  bool updateShouldNotify(SpLayout old) =>
      old.width != width || old.left != left || old.right != right;
}
