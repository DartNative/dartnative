/// Spotify demo: Spotify's now-playing screen, recreated.
///
/// A silent loop of the performance fills the screen behind the player.
/// Scrolling down brings the lyrics card, which follows the song and opens
/// the lyrics full screen, then About the artist, Explore, Credits, a live
/// event and Merch; once the controls scroll away, a mini player takes the
/// top.
///
/// On a wide window, an iPhone Duo opened flat, the player and the lyrics
/// become the two panes of an [ArrangementView]: the system places them on
/// either side of the fold, the player on the left and the lyrics full
/// height on the right, so they can be read without leaving the player.
/// Folding it back returns to one column.
///
/// On iPhone Duo the screen's commands (close, like, lyrics, queue, share,
/// devices, more) are the system bar's items instead of Spotify's own
/// header and buttons: folded, the system stacks them in the vertical bar
/// beside the video, giving way first to the low-priority ones; open, it
/// lays them across the top. Everywhere else the screen keeps Spotify's
/// own look.
library;

import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_share/dartnative_share.dart';

import '../home/demo_ui.dart' show playgroundOverlayStyle;
import 'spotify_cards.dart';
import 'spotify_data.dart';
import 'spotify_hero.dart';
import 'spotify_lyrics.dart';
import 'spotify_player.dart';
import 'spotify_widgets.dart';

class SpotifyDemo extends StatefulWidget {
  /// Runs one step of a scripted walk-through, in debug builds, as when
  /// recording a video of the demo. Steps: `scroll <offset|end> <ms>`,
  /// `lyrics`, `close`, `seek <seconds>`.
  static void Function(String step)? debugScriptStep;

  const SpotifyDemo({super.key});

  /// From this width the lyrics get a pane of their own.
  static const double wideWidth = 600;

  @override
  State<SpotifyDemo> createState() => _SpotifyDemoState();
}

class _SpotifyDemoState extends State<SpotifyDemo> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier(0);

  /// The full-screen lyrics: 0 closed, 1 open; a drag on the page's header
  /// moves it between the two.
  final AnimationController _lyrics =
      AnimationController(duration: const Duration(milliseconds: 380));

  bool _mini = false;
  bool? _wide;
  double _miniThreshold = double.infinity;

  /// The iPhone Duo version: the device reports a hinge. The hardware does
  /// not change, but the first report can come after the first frame.
  bool _duo = DeviceHinge.current.value != null;

  /// iPhone Duo, open: whether the lyrics have their pane beside the player.
  bool _lyricsPane = true;

  /// Folded, or on a phone: whether the lyrics are open full screen over
  /// the player.
  bool _lyricsOpen = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    SpotifyPlayer.instance.start();
    _scroll.addListener(_onScroll);
    assert(() {
      SpotifyDemo.debugScriptStep = _scriptStep;
      return true;
    }());
    if (_duo) {
      _becameDuo();
    } else {
      DeviceHinge.current.addListener(_onHinge);
    }
  }

  void _onHinge() {
    if (DeviceHinge.current.value == null) return;
    DeviceHinge.current.removeListener(_onHinge);
    setState(() => _duo = true);
    _becameDuo();
  }

  /// The like command's icon follows the song's state.
  void _becameDuo() => SpotifyPlayer.instance.liked.addListener(_onLiked);

  void _onLiked() => setState(() {});

  @override
  void dispose() {
    DeviceHinge.current.removeListener(_onHinge);
    SpotifyPlayer.instance.liked.removeListener(_onLiked);
    _scroll.removeListener(_onScroll);
    _scriptScroll?.dispose();
    if (SpotifyDemo.debugScriptStep == _scriptStep) {
      SpotifyDemo.debugScriptStep = null;
    }
    _lyrics.dispose();
    SpotifyPlayer.instance.release();
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
    super.dispose();
  }

  void _onScroll() {
    final o = _scroll.offset;
    _offset.value = o;
    final mini = o > _miniThreshold;
    if (mini != _mini) setState(() => _mini = mini);
  }

  /// A script's scroll: the column moves frame by frame, as a finger would
  /// move it, over the time the step gives.
  Ticker? _scriptScroll;

  void _scriptStep(String step) {
    final words = step.trim().split(RegExp(r'\s+'));
    switch (words.first) {
      case 'scroll':
        if (!_scroll.hasClients || words.length < 2) return;
        // The extent is known once the scroll view has reported; before
        // that the offset is taken as given.
        final max = _scroll.position.maxScrollExtent;
        final asked = words[1] == 'end' ? max : double.tryParse(words[1]) ?? 0;
        final to = max > 0 ? asked.clamp(0.0, max) : asked;
        final ms = words.length > 2 ? int.tryParse(words[2]) ?? 1500 : 1500;
        final from = _scroll.offset;
        _scriptScroll?.dispose();
        _scriptScroll = Ticker((elapsed) {
          final t = (elapsed.inMilliseconds / ms).clamp(0.0, 1.0);
          _scroll
              .jumpTo(from + (to - from) * Curves.easeInOutCubic.transform(t));
          if (t >= 1) _scriptScroll?.stop();
        })
          ..start();
      case 'lyrics':
        if (!_lyricsOpen) _openLyrics();
      case 'close':
        if (_lyricsOpen) _closeLyrics();
      case 'seek':
        final seconds = words.length > 1 ? double.tryParse(words[1]) ?? 0 : 0;
        SpotifyPlayer.instance
            .seek(Duration(milliseconds: (seconds * 1000).round()));
    }
  }

  void _close() => Navigator.pop(context);

  /// Folded, the lyrics over the player: the bar's close command closes
  /// them first, as their own close button does on a phone.
  void _closeFromBar() => _lyricsOpen ? _closeLyrics() : _close();

  void _openLyrics() {
    HapticFeedback.lightImpact();
    setState(() => _lyricsOpen = true);
    _lyrics.animateTo(1, curve: Curves.easeOutCubic);
  }

  void _closeLyrics() {
    setState(() => _lyricsOpen = false);
    // The bar's title comes back once they are gone.
    _lyrics.animateTo(0, curve: Curves.easeOutCubic).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _dragLyrics(double dy, double height) {
    _lyrics.value = (_lyrics.value - dy / height).clamp(0.0, 1.0);
  }

  void _releaseLyrics(double velocity) {
    if (velocity > 700 || _lyrics.value < 0.8) {
      _closeLyrics();
    } else {
      _lyrics.animateTo(1, curve: Curves.easeOutCubic);
    }
  }

  void _toTop() => _scroll.animateTo(0,
      duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);

  /// The window crossed [SpotifyDemo.wideWidth]: the backdrop and the mini
  /// player follow the column at its new size (it keeps its place where its
  /// tree stays, and starts again at the top where it is built again). The
  /// lyrics pane comes with the system's own transition, as in a UIKit app.
  void _layoutChanged(bool wide) {
    final first = _wide == null;
    _wide = wide;
    _mini = false;
    if (first) return;
    // Called from build: what notifies listeners waits for the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scroll.hasClients) {
        _onScroll();
      } else {
        _offset.value = 0;
      }
      if (wide) {
        setState(() => _lyricsOpen = false);
        _lyrics.value = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read here, before the bar is built: the bar's lyrics command follows
    // the same layout as the body in the same frame.
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= SpotifyDemo.wideWidth;
    if (wide != _wide) _layoutChanged(wide);
    if (!_duo) {
      return Scaffold(
        brightness: Brightness.dark,
        backgroundColor: kSpBg,
        body: _body(),
      );
    }
    return Scaffold(
      brightness: Brightness.dark,
      backgroundColor: kSpBg,
      // The video runs under the bar, as it runs under the status bar.
      extendBodyBehindAppBar: true,
      appBar: _commandBar(),
      body: _body(),
    );
  }

  /// The iPhone Duo version's commands, as system bar items. Close and like
  /// keep their place when the vertical bar runs short; share and the
  /// devices give way first.
  AppBar _commandBar() {
    const high = BarButtonItemIOSConfig(
        visibilityPriority: BarItemVisibilityPriority.high);
    const low = BarButtonItemIOSConfig(
        visibilityPriority: BarItemVisibilityPriority.low);
    final player = SpotifyPlayer.instance;
    final liked = player.liked.value;
    final wide = _wide ?? false;
    final lyricsShown = wide ? _lyricsPane : _lyricsOpen;
    return AppBar(
      leading: BarButtonItem(
          icon: 'chevron.down', onPressed: _closeFromBar, ios: high),
      // The song's title takes the playlist's place once the column's has
      // gone under the bar, as a large title gives way to the bar's own. The
      // lyrics' header takes it while they cover the player folded, until
      // they have slid away.
      title: !wide && (_lyricsOpen || _lyrics.value > 0)
          ? null
          : Text(_mini ? kSpTitle : 'Liked Songs'),
      actions: [
        BarButtonItem(
          icon: liked ? 'checkmark.circle.fill' : 'plus.circle',
          titleStyle: liked ? const TextStyle(color: kSpGreen) : null,
          onPressed: player.toggleLiked,
          ios: high,
        ),
        BarButtonItem(
          icon: lyricsShown ? 'quote.bubble.fill' : 'quote.bubble',
          onPressed: _toggleLyrics,
        ),
        BarButtonItem(icon: 'list.bullet', onPressed: _showQueue),
        BarButtonItem(icon: 'square.and.arrow.up', onPressed: _share, ios: low),
        BarButtonItem(
          icon: 'hifispeaker.2',
          onPressed: _showDevices,
          ios: low,
        ),
        BarButtonItem(icon: 'ellipsis', onPressed: _showMore),
      ],
    );
  }

  /// Open: the lyrics pane comes and goes, the system moving the player
  /// into the space. Folded: the lyrics open and close full screen.
  void _toggleLyrics() {
    if (_wide ?? false) {
      setState(() => _lyricsPane = !_lyricsPane);
    } else if (_lyricsOpen) {
      _closeLyrics();
    } else {
      _openLyrics();
    }
  }

  void _share() => Share.share('$kSpTitle, $kSpArtists');

  // The demo has no queue, device list or song menu of its own: the
  // commands open the system's action sheet with what Spotify offers there.
  void _showQueue() => showActionSheet(
      context: context,
      title: 'Queue',
      actions: const ['Go to queue', 'Clear queue']);

  void _showDevices() => showActionSheet(
      context: context,
      title: 'Connect to a device',
      actions: const ['This iPhone', 'AirPlay or Bluetooth']);

  void _showMore() =>
      showActionSheet(context: context, title: kSpTitle, actions: const [
        'Add to playlist',
        'Go to album',
        'Go to artist',
        'Sleep timer',
      ]);

  /// The window's size, live from the platform: opening a foldable flat or
  /// folding it changes it, and the layout follows.
  Widget _body() {
    return Builder(builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final wide = _wide!;
      if (!wide && !_duo) {
        return _playerWithLyrics(context, size.width, size.height,
            lyricsCard: true);
      }
      // Each pane reads its own size: the system decides it, around the
      // fold. The iPhone Duo version keeps this tree folded and open, so
      // folding resizes the player instead of building it again: folded, the
      // lyrics pane is put away and the lyrics open over the player.
      return ArrangementView(
        style: const ArrangementStyle.split(axes: {Axis.horizontal}),
        showsSecondary: wide && (!_duo || _lyricsPane),
        primary: Builder(builder: (context) {
          final pane = MediaQuery.sizeOf(context);
          return _playerWithLyrics(context, pane.width, pane.height,
              lyricsCard: !wide);
        }),
        secondary: Builder(builder: (context) {
          final pane = MediaQuery.sizeOf(context);
          // Under the system bar (the iPhone Duo version) the lyrics' header
          // sits in the bar's title row, beside the title: measured on the
          // iPhone Duo simulator, that row's centre is 33 pt above the top
          // of the safe area, which the bar ends.
          final safeTop = MediaQuery.paddingOf(context).top;
          return SpLyricsPage(
            width: pane.width,
            height: pane.height,
            headerCenter: _duo ? safeTop - 33 : null,
          );
        }),
      );
    });
  }

  /// The player with the full-screen lyrics over it.
  Widget _playerWithLyrics(BuildContext context, double width, double height,
      {required bool lyricsCard}) {
    return Stack(
      children: [
        Positioned.fill(
            child: _player(context, width, height, lyricsCard: lyricsCard)),
        Positioned.fill(child: _lyricsLayer(width, height)),
      ],
    );
  }

  /// The scrolling column with the status bar's tint and the mini player
  /// over it.
  Widget _player(BuildContext context, double width, double height,
      {required bool lyricsCard}) {
    final insets = MediaQuery.paddingOf(context);
    final top = insets.top;
    // The column needs room for the controls under the bar on a short pane.
    final videoHeight = math.max(height, 640.0);
    // The iPhone Duo version names the song in the bar once the column's
    // title has gone under it; the mini player arrives once the last row of
    // controls has gone under where it will sit.
    _miniThreshold = _duo
        ? (videoHeight - spTitleBottomFromBottom(_duo)) - top
        : (videoHeight - spLastRowFromBottom(_duo)) - (top + kSpMiniHeight);
    final hero = SpHero(
      videoHeight: videoHeight,
      showLyricsCard: lyricsCard,
      onClose: _close,
      onOpenLyrics: _openLyrics,
      commandsInBars: _duo,
      // On a wide screen the lyrics pane shows the line already, unless the
      // iPhone Duo version has put the pane away.
      showCurrentLine: lyricsCard || (_duo && !_lyricsPane),
    );
    return SpLayout(
      width: width,
      left: insets.left,
      right: insets.right,
      child: Stack(
        children: [
          // The video and its shades stay put behind the column, so a
          // bounce at the top moves only the controls; the offset is not
          // reported during a bounce, so the dimming holds still too. Once
          // the column has covered the video it is hidden, so the bounce at
          // the end of the column can't show it.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: videoHeight,
            child: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (_, o, __) => Opacity(
                opacity: o < videoHeight ? 1 : 0,
                child: SpBackdrop(
                  height: videoHeight,
                  dim: (o / (videoHeight * 0.3)).clamp(0.0, 1.0) * 0.75,
                  commandsInBars: _duo,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.zero,
              children: [
                hero,
                // The gaps take the page's colour too, over the video.
                Container(height: kSpGap, color: kSpBg),
                const SpAboutCard(),
                Container(height: kSpGap, color: kSpBg),
                const SpExploreCard(),
                Container(height: kSpGap, color: kSpBg),
                const SpCreditsCard(),
                Container(height: kSpGap, color: kSpBg),
                const SpEventCard(),
                Container(height: kSpGap, color: kSpBg),
                const SpMerchCard(),
                Container(height: 64, color: kSpBg),
              ],
            ),
          ),
          // The status bar takes the mini player's colour as the video
          // scrolls under it.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top,
            child: IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _offset,
                builder: (_, o, __) => Opacity(
                  opacity: ((o - videoHeight * 0.3) / (videoHeight * 0.3))
                      .clamp(0.0, 0.85),
                  child: Container(color: kSpHeader),
                ),
              ),
            ),
          ),
          if (!_duo)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: top + kSpMiniHeight + 0.5,
              child: IgnorePointer(
                ignoring: !_mini,
                child: AnimatedOpacity(
                  opacity: _mini ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: _MiniPlayer(onTap: _toTop),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The full-screen lyrics over a dimmed player.
  Widget _lyricsLayer(double width, double height) {
    return AnimatedBuilder(
      animation: _lyrics,
      builder: (context, _) {
        final t = _lyrics.value;
        if (t == 0) return const IgnorePointer(child: SizedBox());
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeLyrics,
                child: Opacity(
                  opacity: 0.6 * t,
                  child: Container(color: kSpBlack),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: (1 - t) * height,
              height: height,
              child: SpLyricsPage(
                width: width,
                height: height,
                onClose: _closeLyrics,
                // The iPhone Duo version closes them from the bar, which has
                // put its title away for them: the header goes under it.
                closeButton: !_duo,
                onDragDown: (dy) => _dragLyrics(dy, height),
                onDragEnd: _releaseLyrics,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The player squeezed under the status bar: the scrolling title, the
/// artists, the tick, pause and a line of progress along the bottom.
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final layout = SpLayout.of(context);
    final width = layout.contentWidth;
    final player = SpotifyPlayer.instance;
    // Measured under a 62 pt status bar: the title's centre 23 pt below it,
    // the artists' 48 pt, the buttons' 34 pt.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + kSpMiniHeight - 1.5,
            child: Container(color: kSpHeader),
          ),
          // The header's colour runs under a side bar; its content keeps
          // clear of it.
          Positioned(
            left: layout.left,
            right: layout.right,
            top: 0,
            bottom: 0,
            child: Stack(
              children: [
                Positioned(
                  left: 21,
                  right: 129,
                  top: top + 23 - 16.6 * 0.6,
                  child: SpMarquee(
                    text: kSpTitle,
                    size: 16.6,
                    width: width - 21 - 129,
                    fadeEnd: 20,
                  ),
                ),
                Positioned(
                  left: 21,
                  right: 129,
                  top: top + 48 - 13.8 * 0.6,
                  child: Text(
                    kSpArtists,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: spText(13.8, color: const Color(0xA6FFFFFF)),
                  ),
                ),
                Positioned(
                  right: spFromScreenRight(308) - 11.5,
                  top: top + 34 - 11.5,
                  child: const SpLikedButton(diameter: 23),
                ),
                Positioned(
                  right: spFromScreenRight(364.6) - 18,
                  top: top + 34 - 18,
                  width: 36,
                  height: 36,
                  child: ValueListenableBuilder<SpState>(
                    valueListenable: player.state,
                    builder: (_, s, __) => GestureDetector(
                      onTap: player.toggle,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Icon(
                          s.playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          size: 24,
                          color: kSpWhite,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 2,
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: player.position,
                    builder: (_, pos, __) {
                      final total = player.state.value.duration.inMilliseconds;
                      final f = total <= 0
                          ? 0.0
                          : (pos.inMilliseconds / total).clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          Positioned.fill(child: Container(color: kSpTrack)),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: width * f,
                            child: Container(color: kSpWhite),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
