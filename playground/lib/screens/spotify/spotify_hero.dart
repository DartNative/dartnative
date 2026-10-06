/// The top of the player: the controls over the looping video. The video
/// and its shades are [SpBackdrop], a layer behind the scrolling page that
/// stays still while the page scrolls or bounces over it.
///
/// The controls keep their measured distance from the video's bottom, the
/// top bar from the top.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

import 'spotify_data.dart';
import 'spotify_lyrics.dart';
import 'spotify_player.dart';
import 'spotify_widgets.dart';

// The rows on the measured screen.
const _currentLineCenter = 480.0;
const _trackRowTop = 568.0;
const _titleSize = 24.0;
const _progressBarY = 642.7;
const _transportCenter = 712.0;
const _transportHeight = 66.0;
const _bottomRowCenter = 781.7;
const _bottomRowHeight = 36.0;

/// With the bottom row in the system bar (the iPhone Duo version) the
/// controls and the shade under them move down into its place, so the
/// transport ends where the bottom row ended and the video shows that much
/// more.
double _controlsDrop(bool commandsInBars) => commandsInBars
    ? (_bottomRowCenter + _bottomRowHeight / 2) -
        (_transportCenter + _transportHeight / 2)
    : 0;

/// The centre of the last row of controls, from the video's bottom edge.
double spLastRowFromBottom(bool commandsInBars) =>
    spFromScreenBottom(commandsInBars ? _transportCenter : _bottomRowCenter) -
    _controlsDrop(commandsInBars);

/// The bottom of the song's title in the track row, from the video's bottom
/// edge.
double spTitleBottomFromBottom(bool commandsInBars) =>
    spFromScreenBottom(_trackRowTop + _titleSize * 1.2) -
    _controlsDrop(commandsInBars);

class SpHero extends StatelessWidget {
  const SpHero({
    super.key,
    required this.videoHeight,
    required this.showLyricsCard,
    required this.onClose,
    required this.onOpenLyrics,
    this.commandsInBars = false,
    this.showCurrentLine = true,
  });

  /// The video's height: the screen's, or the pane's.
  final double videoHeight;

  /// The lyrics card peeks over the video's bottom edge; on a wide screen
  /// the lyrics have their own pane and the card is left out.
  final bool showLyricsCard;

  final VoidCallback onClose;
  final VoidCallback onOpenLyrics;

  /// The iPhone Duo version: close, like, share, the queue, the devices and
  /// more are the system bar's items, so the header, the bottom row and the
  /// tick are left out of the page.
  final bool commandsInBars;

  /// The line being sung, over the video. Left out while the lyrics have
  /// their own pane beside the player.
  final bool showCurrentLine;

  /// How far the lyrics card rises over the video's bottom edge. Under the
  /// lower controls of the iPhone Duo version it rises 10 pt less, still
  /// showing its header.
  double get _peek => commandsInBars ? kSpLyricsPeek - 10 : kSpLyricsPeek;

  /// The section's height in the scrolling column.
  double get height => showLyricsCard
      ? videoHeight - _peek + kSpLyricsCardHeight
      : videoHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final layout = SpLayout.of(context);
    final w = layout.contentWidth;
    final h = videoHeight;
    final drop = _controlsDrop(commandsInBars);
    // A measured y, kept at its distance from the video's bottom edge.
    double fromBottom(double y) => h - spFromScreenBottom(y) + drop;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Under the video's bottom edge the page has its own colour, so
          // the video behind it shows only through the top of the column.
          // The keys here and in the controls keep each part's native views
          // when a part before it comes or goes (folding an iPhone Duo).
          if (height > h)
            Positioned(
              key: const ValueKey('page'),
              left: 0,
              right: 0,
              top: h,
              bottom: 0,
              child: Container(color: kSpBg),
            ),
          // The bottom of the backdrop's shade, carried with the controls so
          // the page under them stays dark as they scroll up. At rest it lies
          // where the backdrop is already near black.
          Positioned(
            key: const ValueKey('shade'),
            left: 0,
            right: 0,
            top: h * 0.74 + drop,
            height: h * 0.26 - drop,
            child: const _Shade(
              colors: [Color(0x000C0C0C), Color(0xFF0C0C0C), Color(0xFF0C0C0C)],
              stops: [0, 0.23, 1],
            ),
          ),
          // Text and controls keep clear of a side bar (iPhone Duo's
          // vertical bar); the video and the shades run under it.
          Positioned(
            key: const ValueKey('controls'),
            left: layout.left,
            right: layout.right,
            top: 0,
            bottom: 0,
            child: SpLayout(
              width: w,
              child: Stack(
                children: [
                  if (!commandsInBars)
                    Positioned(
                      key: const ValueKey('top'),
                      left: 0,
                      right: 0,
                      top: top + 31 - 22,
                      height: 44,
                      child: _TopBar(onClose: onClose),
                    ),
                  if (showCurrentLine)
                    Positioned(
                      key: const ValueKey('line'),
                      left: 71,
                      right: 71,
                      // The iPhone Duo version sets it 24 pt lower, nearer
                      // the controls.
                      top: fromBottom(_currentLineCenter) -
                          60 +
                          (commandsInBars ? 24 : 0),
                      height: 120,
                      child: const _CurrentLine(),
                    ),
                  Positioned(
                    key: const ValueKey('track'),
                    left: 0,
                    right: 0,
                    top: fromBottom(_trackRowTop),
                    height: 60,
                    child: _TrackRow(showLiked: !commandsInBars),
                  ),
                  Positioned(
                    key: const ValueKey('progress'),
                    left: 26,
                    right: 26,
                    top: fromBottom(_progressBarY) - SpProgress.barCenter,
                    child: SpProgress(width: w - 52),
                  ),
                  Positioned(
                    key: const ValueKey('transport'),
                    left: 0,
                    right: 0,
                    top: fromBottom(_transportCenter) - _transportHeight / 2,
                    height: _transportHeight,
                    child: const _Transport(),
                  ),
                  if (!commandsInBars)
                    Positioned(
                      key: const ValueKey('bottom'),
                      left: 0,
                      right: 0,
                      top: fromBottom(_bottomRowCenter) - _bottomRowHeight / 2,
                      height: _bottomRowHeight,
                      child: const _BottomRow(),
                    ),
                  if (showLyricsCard)
                    Positioned(
                      key: const ValueKey('card'),
                      left: kSpMargin,
                      right: kSpMargin,
                      top: h - _peek,
                      child: SpLyricsCard(
                        width: w - kSpMargin * 2,
                        onOpen: onOpenLyrics,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shade extends StatelessWidget {
  const _Shade({required this.colors, this.stops});

  final List<Color> colors;
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: stops,
          ),
        ),
      ),
    );
  }
}

/// The layer behind the scrolling page: the loop, darkened under the bar
/// and under the controls. It keeps still while the page scrolls or bounces
/// over it; [dim] darkens all of it as the page scrolls up.
class SpBackdrop extends StatelessWidget {
  const SpBackdrop({
    super.key,
    required this.height,
    this.dim = 0,
    this.commandsInBars = false,
  });

  final double height;
  final double dim;

  /// As [SpHero.commandsInBars]: the shade moves down with the controls.
  final bool commandsInBars;

  @override
  Widget build(BuildContext context) {
    final drop = _controlsDrop(commandsInBars);
    return Stack(
      children: [
        const Positioned.fill(child: _Canvas()),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 180,
          child: const _Shade(
            colors: [Color(0x66000000), Color(0x00000000)],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: height * 0.45 + drop,
          height: height * 0.55,
          // Near black from three quarters down, as measured: the
          // controls sit on the page's colour, not on the picture.
          child: const _Shade(
            colors: [
              Color(0x00000000),
              Color(0x8C000000),
              Color(0xEB0C0C0C),
              Color(0xFF0C0C0C),
              Color(0xFF0C0C0C),
            ],
            stops: [0, 0.31, 0.53, 0.64, 1],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: dim,
              child: Container(color: const Color(0xFF000000)),
            ),
          ),
        ),
      ],
    );
  }
}

/// The loop, over its first frame until the player shows one.
class _Canvas extends StatelessWidget {
  const _Canvas();

  @override
  Widget build(BuildContext context) {
    final player = SpotifyPlayer.instance;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(kSpCanvasPoster, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: player.canvasReady,
            builder: (_, ready, __) {
              final c = player.canvas;
              if (!ready || c == null) return const SizedBox();
              return VideoPlayer(controller: c, fit: BoxFit.cover);
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 33 - 22,
          top: 0,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            // The glyphs sit 2 pt under the bar's centre line in the app.
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Center(
                child: Icon(CupertinoIcons.chevron_down,
                    size: 22, color: kSpWhite),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(kSpContext, style: spText(13.85, weight: 'Bold')),
          ),
        ),
        Positioned(
          right: spFromScreenRight(369) - 22,
          top: 0,
          width: 44,
          height: 44,
          child: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Center(
              child: Icon(CupertinoIcons.ellipsis, size: 22, color: kSpWhite),
            ),
          ),
        ),
      ],
    );
  }
}

/// The line being sung, over the video.
class _CurrentLine extends StatelessWidget {
  const _CurrentLine();

  @override
  Widget build(BuildContext context) {
    final player = SpotifyPlayer.instance;
    return IgnorePointer(
      child: ValueListenableBuilder<int>(
        valueListenable: player.line,
        builder: (_, i, __) {
          final lines = player.lyrics.lines;
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedOpacity(
              opacity: i < 0 ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              // The line wraps at 250 pt, as in the app, on any width.
              child: SizedBox(
                width: 250,
                child: Text(
                  i < 0 ? '' : lines[i].text,
                  maxLines: 3,
                  style: spText(19.7, weight: 'Bold', height: 1.22),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.showLiked});

  final bool showLiked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 25,
          top: 0,
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.asset(kSpCover, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          left: 86,
          top: 0,
          child: SpMarquee(
            text: kSpTitle,
            size: _titleSize,
            weight: 'Bold',
            width: SpLayout.of(context).width - 86 - 80,
          ),
        ),
        Positioned(
          left: 86,
          right: spFromScreenRight(340),
          top: 31.4,
          child: Text(
            kSpArtists,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: spText(17.1, color: kSpMuted),
          ),
        ),
        if (showLiked)
          Positioned(
            right: spFromScreenRight(363) - 15,
            top: 27 - 15,
            child: SpLikedButton(diameter: 30),
          ),
      ],
    );
  }
}

class _Transport extends StatelessWidget {
  const _Transport();

  @override
  Widget build(BuildContext context) {
    final player = SpotifyPlayer.instance;
    // Measured on the screen's width: the outer buttons keep their distance to
    // the edges, previous and next their distance to the centre.
    final width = SpLayout.of(context).width;
    final mid = width / 2;
    Widget at(double cx, Widget child, {VoidCallback? onTap, double w = 48}) =>
        Positioned(
          left: cx - w / 2,
          top: 0,
          width: w,
          height: 66,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Center(child: child),
          ),
        );
    return Stack(
      children: [
        at(37.6, const SpGlyph(SpGlyphKind.shuffle)),
        at(
            mid - 92,
            const Icon(CupertinoIcons.backward_end_fill,
                size: 28, color: kSpWhite),
            onTap: player.restart),
        Positioned(
          left: mid - 33,
          top: 0,
          child: ValueListenableBuilder<SpState>(
            valueListenable: player.state,
            builder: (_, s, __) => SpCircleButton(
              diameter: 66,
              color: kSpWhite,
              onTap: player.toggle,
              child: Icon(
                s.playing
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                size: 30,
                color: kSpBlack,
              ),
            ),
          ),
        ),
        at(
            mid + 92,
            const Icon(CupertinoIcons.forward_end_fill,
                size: 28, color: kSpWhite),
            onTap: player.restart),
        at(width - 37, const SpGlyph(SpGlyphKind.repeat)),
      ],
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow();

  @override
  Widget build(BuildContext context) {
    final width = SpLayout.of(context).width;
    Widget at(double cx, Widget child) => Positioned(
          left: cx - 18,
          top: 0,
          width: 36,
          height: 36,
          child: Center(child: child),
        );
    return Stack(
      children: [
        at(38, const SpGlyph(SpGlyphKind.devices)),
        at(
            width - 79,
            const Icon(CupertinoIcons.square_arrow_up,
                size: 23, color: kSpWhite)),
        at(width - 31, const SpGlyph(SpGlyphKind.queue)),
      ],
    );
  }
}
