/// The lyrics: the card under the player and the full-screen page.
///
/// Both show the same view. Lines already sung are white, the rest black,
/// and the list glides up so the line being sung stays at the same height.
library;

import 'package:dartnative/dartnative.dart';

import 'spotify_data.dart';
import 'spotify_player.dart';
import 'spotify_widgets.dart';

/// The lines, kept in place against the song.
class SpLyricsView extends StatefulWidget {
  const SpLyricsView({
    super.key,
    required this.width,
    required this.height,
    required this.anchor,
    this.fadeTop = 0,
    this.fadeTopOpacity = 1,
    this.fadeBottom = 0,
    this.horizontalPadding = 0,
    this.seekOnTap = false,
  });

  /// Width of the view; the lines wrap inside its horizontal padding.
  final double width;

  /// Height of the visible window.
  final double height;

  /// Where the current line's top sits, from the window's top. Before the
  /// list has scrolled that far, it starts at the top.
  final double anchor;

  /// The window's edges fade into [kSpLyricsRed] over these heights.
  final double fadeTop;
  final double fadeBottom;

  /// How much the top fade covers at the window's edge: 1 hides a line
  /// there, less leaves it showing through.
  final double fadeTopOpacity;

  final double horizontalPadding;

  /// A tap on a line plays the song from it.
  final bool seekOnTap;

  @override
  State<SpLyricsView> createState() => _SpLyricsViewState();
}

class _SpLyricsViewState extends State<SpLyricsView> {
  final _player = SpotifyPlayer.instance;

  /// Moves the list to the line being sung. UIKit animates the move, so
  /// nothing is rebuilt frame by frame while the page around it scrolls.
  final ScrollController _scroll = ScrollController();

  /// Top of every line within the list, for the width they were measured at.
  List<double> _tops = const [];
  double _measuredWidth = -1;

  @override
  void initState() {
    super.initState();
    _player.line.addListener(_follow);
  }

  @override
  void dispose() {
    _player.line.removeListener(_follow);
    _scroll.dispose();
    super.dispose();
  }

  /// Where the list rests with [current] at the anchor row.
  double _target(int current) => current < 0 || _tops.isEmpty
      ? 0.0
      : (_tops[current] - widget.anchor).clamp(0.0, double.infinity);

  void _follow() => _scroll.animateTo(
        _target(_player.line.value),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );

  /// Measures the lines for [width]; true when they were measured again, and
  /// the list has to be put back on the current line.
  bool _measure(double width) {
    if (width == _measuredWidth) return false;
    _measuredWidth = width;
    final lines = _player.lyrics.lines;
    final tops = <double>[];
    var y = 0.0;
    for (final l in lines) {
      tops.add(y);
      final tp = TextPainter(
        text: TextSpan(text: l.text, style: _style(kSpWhite)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width);
      // Whole rows: a wrapped line takes two rows of the same pitch.
      final rows = (tp.height / kSpLyricPitch).round().clamp(1, 20);
      y += rows * kSpLyricPitch;
    }
    _tops = tops;
    return true;
  }

  TextStyle _style(Color color) => spText(
        kSpLyricSize,
        weight: 'Bold',
        color: color,
        height: kSpLyricPitch / kSpLyricSize,
      );

  @override
  Widget build(BuildContext context) {
    final lines = _player.lyrics.lines;
    if (_measure(widget.width - widget.horizontalPadding * 2)) {
      // Opens on the line being sung, without animating.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scroll.jumpTo(_target(_player.line.value));
      });
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scroll,
              // The song moves the lines, not the finger.
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
                child: ValueListenableBuilder<int>(
                  valueListenable: _player.line,
                  builder: (_, current, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < lines.length; i++)
                        _line(i, lines[i], i <= current),
                      // Room under the last line, so it too can reach the
                      // anchor row.
                      SizedBox(height: widget.height),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.fadeTop > 0)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: widget.fadeTop,
              child: IgnorePointer(
                child: _Fade(down: true, opacity: widget.fadeTopOpacity),
              ),
            ),
          if (widget.fadeBottom > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.fadeBottom,
              child: const IgnorePointer(child: _Fade(down: false)),
            ),
        ],
      ),
    );
  }

  Widget _line(int i, SpLyricLine line, bool sung) {
    final text = SizedBox(
      width: double.infinity,
      child: Text(line.text, style: _style(sung ? kSpWhite : kSpBlack)),
    );
    if (!widget.seekOnTap) return text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SpotifyPlayer.instance.seek(line.time),
      child: text,
    );
  }
}

/// Red into transparent: the lyrics' colour over the edge of the window.
class _Fade extends StatelessWidget {
  const _Fade({required this.down, this.opacity = 1});

  final bool down;

  /// The fade's opacity at the window's edge.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final solid = kSpLyricsRed.withOpacity(opacity);
    final clear = kSpLyricsRed.withOpacity(0);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: down ? [solid, clear] : [clear, solid],
        ),
      ),
    );
  }
}

// ── The card ────────────────────────────────────────────────────────────────

/// The red card under the player. Tapping it, or its expand button, opens
/// the lyrics full screen.
class SpLyricsCard extends StatelessWidget {
  const SpLyricsCard({super.key, required this.width, required this.onOpen});

  final double width;
  final VoidCallback onOpen;

  /// The window starts under the header; its first row is centred 72.5 pt
  /// below the card's top, and the line being sung sits on the fourth row.
  static const double _windowTop = 72.5 - kSpLyricPitch / 2;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: kSpLyricsCardHeight,
        decoration: BoxDecoration(
          color: kSpLyricsRed,
          borderRadius: BorderRadius.circular(kSpCardRadius),
        ),
        child: Stack(
          children: [
            Positioned(
              left: kSpPad,
              top: 27 - 15.8 * 0.6,
              child: Text('Lyrics', style: spText(15.8, weight: 'Bold')),
            ),
            Positioned(
              right: 22.3 + 32 + 13,
              top: 27.7 - 16,
              child: SpCircleButton(
                diameter: 32,
                color: kSpLyricsButton,
                onTap: () {},
                child: const Icon(CupertinoIcons.square_arrow_up,
                    size: 17, color: kSpWhite),
              ),
            ),
            Positioned(
              right: 22.3,
              top: 27.7 - 16,
              child: SpCircleButton(
                diameter: 32,
                color: kSpLyricsButton,
                onTap: onOpen,
                child: const Icon(MaterialSymbolsRounded.open_in_full,
                    size: 17, color: kSpWhite),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: _windowTop,
              bottom: 0,
              child: SpLyricsView(
                width: width,
                height: kSpLyricsCardHeight - _windowTop,
                anchor: 3 * kSpLyricPitch,
                // The first row shows through: about 40% at the top of its
                // letters, whole at their base.
                fadeTop: 27,
                fadeTopOpacity: 0.8,
                fadeBottom: 44,
                horizontalPadding: kSpPad,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The full-screen page ────────────────────────────────────────────────────

/// The lyrics full screen: the song at the top, the lines, and the scrub
/// bar with play and share under them. [onClose] null hides the close
/// button and the controls, for the lyrics pane beside the player on a
/// wide screen, which has its own controls; [closeButton] false hides the
/// button alone, where the screen's bar closes the lyrics.
class SpLyricsPage extends StatelessWidget {
  const SpLyricsPage({
    super.key,
    required this.width,
    required this.height,
    this.onClose,
    this.onDragDown,
    this.onDragEnd,
    this.headerCenter,
    this.closeButton = true,
  });

  final double width;
  final double height;
  final VoidCallback? onClose;
  final bool closeButton;

  /// Where the header's centre goes, the lines keeping their distance below
  /// it. Null puts it under the status bar, as on the phone; a pane under
  /// the system bar puts it in the bar's title row, where the bar has
  /// nothing over the pane.
  final double? headerCenter;

  /// A drag down the header moves the page with the finger; the screen
  /// decides on release whether it closes.
  final void Function(double dy)? onDragDown;
  final void Function(double velocity)? onDragEnd;

  /// Measured: the header's centre 34 pt below the
  /// status bar, the first line centred at 171.6 pt, the controls from the
  /// bottom edge.
  static const double _headerCenter = 34;
  static const double _firstRowCenter = 168.9;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final top =
        headerCenter == null ? insets.top : headerCenter! - _headerCenter;
    final controls = onClose != null;
    final h = height;
    final w = width;
    // The red runs edge to edge; the content keeps clear of a side bar or a
    // camera (iPhone Duo's vertical bar, a phone in landscape).
    final l = insets.left;
    final r = insets.right;
    final cw = w - l - r;
    final windowTop = top + _firstRowCenter - 62 - kSpLyricPitch / 2;
    final windowBottom = controls ? h - 174 : h - insets.bottom;
    return Container(
      width: w,
      height: h,
      color: kSpLyricsRed,
      child: Stack(
        children: [
          Positioned(
            left: l,
            right: r,
            top: windowTop,
            height: windowBottom - windowTop,
            child: SpLyricsView(
              width: cw,
              height: windowBottom - windowTop,
              anchor: 6 * kSpLyricPitch,
              fadeTop: 24,
              fadeBottom: 64,
              horizontalPadding: 36,
              seekOnTap: true,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + _headerCenter * 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate:
                  onDragDown == null ? null : (d) => onDragDown!(d.delta.dy),
              onVerticalDragEnd: onDragEnd == null
                  ? null
                  : (d) => onDragEnd!(d.primaryVelocity ?? 0),
              child: Container(color: kSpLyricsRed),
            ),
          ),
          if (controls && closeButton)
            Positioned(
              left: l + 50 - 16.5,
              top: top + _headerCenter - 16.5,
              child: SpCircleButton(
                diameter: 33,
                color: kSpLyricsButton,
                onTap: onClose,
                child: const Icon(CupertinoIcons.chevron_down,
                    size: 16, color: kSpWhite),
              ),
            ),
          Positioned(
            left: l + 72,
            right: r + 72,
            top: top + _headerCenter - 16.7,
            child: IgnorePointer(
              child: Column(
                children: [
                  Text(
                    _middleEllipsis(kSpTitle, 13.4, cw - 144),
                    maxLines: 1,
                    style: spText(13.4, weight: 'Bold'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kSpArtists,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: spText(13.85),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: r + spFromScreenRight(352) - 16,
            top: top + _headerCenter - 16,
            child: const SpGlyph(SpGlyphKind.flag),
          ),
          if (controls) ...[
            Positioned(
              left: l + 26,
              right: r + 26,
              bottom: spFromScreenBottom(736.7) -
                  (SpProgress.height - SpProgress.barCenter),
              child: SpProgress(
                width: cw - 52,
                timeColor: Color(0xABFFFFFF),
                trackColor: Color(0x29FFFFFF),
              ),
            ),
            Positioned(
              left: l + cw / 2 - 33,
              bottom: spFromScreenBottom(792.6) - 33,
              child: ValueListenableBuilder<SpState>(
                valueListenable: SpotifyPlayer.instance.state,
                builder: (_, s, __) => SpCircleButton(
                  diameter: 66,
                  color: kSpWhite,
                  onTap: SpotifyPlayer.instance.toggle,
                  child: Icon(
                    s.playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    size: 30,
                    color: kSpLyricsRed,
                  ),
                ),
              ),
            ),
            Positioned(
              right: r + spFromScreenRight(352) - 12,
              bottom: spFromScreenBottom(791) - 12,
              child: const Icon(CupertinoIcons.square_arrow_up,
                  size: 24, color: kSpWhite),
            ),
          ],
        ],
      ),
    );
  }
}

/// [text] with its middle replaced by an ellipsis so it fits [maxWidth], the
/// way the system shortens a title that keeps both its ends.
String _middleEllipsis(String text, double size, double maxWidth) {
  double widthOf(String s) => (TextPainter(
        text: TextSpan(text: s, style: spText(size, weight: 'Bold')),
        textDirection: TextDirection.ltr,
      )..layout())
          .width;
  if (widthOf(text) <= maxWidth) return text;
  // Keep more of the end than the start, as the system does for a title
  // whose end tells songs apart ("- Version Revisited").
  var keep = text.length - 1;
  while (keep > 2) {
    final head = (keep * 0.45).round();
    final tail = keep - head;
    final s =
        '${text.substring(0, head)}...${text.substring(text.length - tail)}';
    if (widthOf(s) <= maxWidth) return s;
    keep--;
  }
  return text;
}
