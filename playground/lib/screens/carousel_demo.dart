/// Carousel: an album player with covers you swipe through.
///
/// Dragging moves a decimal position (2.4 sits between the third and fourth
/// album) and letting go animates to the nearest one. Each frame sets every
/// cover's position, size and 3D angle from that number, and mixes the
/// background colour between the two albums the drag sits between.
///
/// Covers away from the middle are turned in 3D, so the side facing the
/// middle is drawn smaller than the side facing out.
///
/// Built by hand instead of with a scroll view: there is no paging API, and
/// horizontal scroll views do not report how far they have scrolled, which
/// is the number all of this needs.
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';

/// One record in the carousel. [tint] is sampled from the artwork's dominant
/// hue and stored here, since there is no colour-extraction helper to read it
/// at runtime.
class _Album {
  const _Album({
    required this.title,
    required this.artist,
    required this.cover,
    required this.tint,
    required this.length,
  });

  final String title;
  final String artist;
  final String cover;
  final Color tint;
  final Duration length;
}

const _albums = <_Album>[
  _Album(
    title: 'Midnight Static',
    artist: 'Neon Harbor',
    cover: 'assets/carousel/covers/cover_01.webp',
    tint: Color(0xFF491C1C),
    length: Duration(minutes: 3, seconds: 58),
  ),
  _Album(
    title: 'Crowd Theory',
    artist: 'The Velvet Antennas',
    cover: 'assets/carousel/covers/cover_02.webp',
    tint: Color(0xFF493730),
    length: Duration(minutes: 3, seconds: 7),
  ),
  _Album(
    title: 'Open Mic Elegy',
    artist: 'June Casette',
    cover: 'assets/carousel/covers/cover_03.webp',
    tint: Color(0xFF493030),
    length: Duration(minutes: 4, seconds: 51),
  ),
  _Album(
    title: 'Violet Hours',
    artist: 'Prism Motel',
    cover: 'assets/carousel/covers/cover_04.webp',
    tint: Color(0xFF493045),
    length: Duration(minutes: 3, seconds: 31),
  ),
  _Album(
    title: 'Encore Weather',
    artist: 'Fjord Radio',
    cover: 'assets/carousel/covers/cover_05.webp',
    tint: Color(0xFF1C4549),
    length: Duration(minutes: 4, seconds: 12),
  ),
];

const _kText = Color(0xFFFFFFFF);
const _kTextDim = Color(0x8CFFFFFF);

class CarouselDemo extends StatefulWidget {
  const CarouselDemo({super.key});

  @override
  State<CarouselDemo> createState() => _CarouselDemoState();
}

class _CarouselDemoState extends State<CarouselDemo>
    with SingleTickerProviderStateMixin {
  /// Which album is in the middle, as a decimal: 1.4 sits between the second
  /// and third. Everything on screen is built from this one number.
  double _page = 0;

  late final AnimationController _snap;
  Animation<double>? _snapRun;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    // Dark by design screen: pin dark chrome, or the status bar icons go
    // dark on this near black gradient in light theme. The nav strip stays
    // transparent so the gradient can run edge to edge behind it.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    _snap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addListener(() {
        final run = _snapRun;
        if (run != null) setState(() => _page = run.value);
      });
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _settleTo(double target) {
    _snapRun = Tween<double>(begin: _page, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    );
    _snap
      ..reset()
      ..forward();
  }

  void _onDragUpdate(DragUpdateDetails d, double stride) {
    _snap.stop();
    setState(() {
      // Past the first and last album the drag slows down instead of stopping
      // dead.
      final next = _page - d.delta.dx / stride;
      if (next < 0) {
        _page = next / 3;
      } else if (next > _albums.length - 1) {
        _page = (_albums.length - 1) + (next - (_albums.length - 1)) / 3;
      } else {
        _page = next;
      }
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    // A flick carries to the neighbour even when the drag stopped short.
    var target = _page.roundToDouble();
    if (velocity < -320) {
      target = _page.ceilToDouble();
    } else if (velocity > 320) {
      target = _page.floorToDouble();
    }
    _settleTo(target.clamp(0, (_albums.length - 1).toDouble()));
  }

  /// The background colour, mixed between the two albums the drag sits
  /// between. Mixed here because a gradient cannot animate between two sets
  /// of colours on its own, so it would jump from one album to the next.
  Color get _tint {
    final lo = _page.floor().clamp(0, _albums.length - 1);
    final hi = _page.ceil().clamp(0, _albums.length - 1);
    final t = (_page - lo).clamp(0.0, 1.0);
    return Color.lerp(_albums[lo].tint, _albums[hi].tint, t)!;
  }

  _Album get _current => _albums[_page.round().clamp(0, _albums.length - 1)];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardSize = math.min(width * 0.62, 300.0);
    // Gap between covers. A turned cover is drawn about half as wide, so
    // they sit closer together than their full width would suggest.
    final stride = cardSize * 0.75;
    final tint = _tint;

    final topWash = Color.lerp(tint, const Color(0xFF000000), 0.55)!;

    return Scaffold(
      backgroundColor: topWash,
      // Dark by design screen: keep the iOS 26 glass surfaces dark even in
      // light theme (glass follows the interface style, not the content
      // behind it).
      brightness: Brightness.dark,
      // Let the gradient fill the whole screen, including behind the two
      // bars.
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'NOW PLAYING',
          style: TextStyle(
            color: _kTextDim,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
        // Only the iOS 26 glass is see-through on its own; every other bar
        // draws an opaque surface that would cut the gradient off.
        backgroundColor: isIOS26 ? null : const Color(0x00000000),
        // A see-through bar follows the device theme: in light theme it
        // wears light glass and the system draws its title dark. Force the
        // dark tone to match the screen.
        brightness: Brightness.dark,
        leading: const BackButton(iconColor: _kText),
      ),
      body: Container(
        // Brightest behind the covers, almost black at the top and bottom.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              topWash,
              tint,
              Color.lerp(tint, const Color(0xFF000000), 0.35)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              height: cardSize + 40,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, stride),
                onHorizontalDragEnd: _onDragEnd,
                child: Stack(
                  alignment: Alignment.center,
                  children: _buildCards(cardSize, stride),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _TrackLabel(album: _current),
            const SizedBox(height: 22),
            _ProgressBar(length: _current.length),
            const SizedBox(height: 18),
            _Transport(
              playing: _playing,
              onPlayPause: () => setState(() => _playing = !_playing),
              onPrevious: () => _settleTo(
                  math.max(0, _page.round() - 1).toDouble()),
              onNext: () => _settleTo(
                  math.min(_albums.length - 1, _page.round() + 1).toDouble()),
            ),
            // Space for the bottom bar, a bit more on Android.
            SizedBox(
              height: (isIOS26 ? 66.0 : 80.0) +
                  (Platform.isAndroid ? 28.0 : 0.0) +
                  MediaQuery.paddingOf(context).bottom,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        selectedIconColor: const Color(0xFFFF2D55),
        selectedLabelFontStyle: const TextStyle(color: Color(0xFFFF2D55)),
        backgroundColor: const Color(0x00000000),
        items: const [
          BottomNavigationBarItem(
            label: 'Now',
            icon: Icon(CupertinoIcons.circle_grid_hex_fill),
          ),
          BottomNavigationBarItem(
            label: 'Browse',
            icon: Icon(CupertinoIcons.search),
          ),
          BottomNavigationBarItem(
            label: 'Library',
            icon: Icon(CupertinoIcons.music_note_list),
          ),
        ],
      ),
    );
  }

  /// Most a cover can turn, in radians. Only the middle one stays flat.
  static const _maxTurn = 1.05;

  /// How far away the viewer is, as a multiple of the cover's width. Smaller
  /// values make the turn look stronger. Below about 3 the covers look
  /// stretched.
  static const _depthRatio = 5.0;

  /// The visible covers, furthest first so the middle one is drawn on top.
  List<Widget> _buildCards(double cardSize, double stride) {
    final visible = <MapEntry<double, Widget>>[];
    for (var i = 0; i < _albums.length; i++) {
      final offset = i - _page;
      if (offset.abs() > 2.2) continue;
      final distance = offset.abs().clamp(0.0, 2.0);
      final near = math.min(distance, 1.0);
      // A positive angle turns the right edge away, so covers left of the
      // middle need the opposite sign.
      final turn = -offset.sign * _maxTurn * _turnCurve(distance);
      visible.add(MapEntry(
        distance,
        Transform.translate(
          offset: Offset(offset * stride, 0),
          child: Transform.perspective(
            rotateY: turn,
            depth: cardSize * _depthRatio,
            child: Transform.scale(
              // Only the middle cover is full size.
              scale: 1 - 0.14 * near,
              child: _CoverCard(
                album: _albums[i],
                size: cardSize,
                // Covers darken as they move away from the middle.
                dim: 0.30 * near + 0.28 * _turnCurve(distance),
              ),
            ),
          ),
        ),
      ));
    }
    visible.sort((a, b) => b.key.compareTo(a.key));
    return [for (final e in visible) e.value];
  }

  /// Turns quickly at first, then slows, so only the cover in the middle
  /// looks flat and the ones past its neighbours all look about the same.
  static double _turnCurve(double distance) {
    final t = math.min(distance, 1.0);
    return 1 - math.pow(1 - t, 2.2).toDouble();
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({
    required this.album,
    required this.size,
    required this.dim,
  });

  final _Album album;
  final double size;
  final double dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Stands in until the artwork loads, so a card is never a hole.
        color: album.tint,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0x99000000),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Image.asset(
            album.cover,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
          if (dim > 0.01)
            Container(
              width: size,
              height: size,
              color: Color.fromRGBO(0, 0, 0, dim),
            ),
        ],
      ),
    );
  }
}

class _TrackLabel extends StatelessWidget {
  const _TrackLabel({required this.album});

  final _Album album;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kText,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          album.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _kTextDim, fontSize: 13),
        ),
      ],
    );
  }
}

/// A read-only progress line: the design calls for a hairline track, not a
/// slider with a thumb.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.length});

  final Duration length;

  static String _time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('0:00',
                  style: TextStyle(color: _kTextDim, fontSize: 11)),
              const Spacer(),
              Text(_time(length),
                  style: const TextStyle(color: _kTextDim, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Transport extends StatelessWidget {
  const _Transport({
    required this.playing,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
  });

  final bool playing;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TransportButton(
          icon: CupertinoIcons.backward_fill,
          size: 26,
          onTap: onPrevious,
        ),
        const SizedBox(width: 34),
        _TransportButton(
          icon: playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
          size: 34,
          onTap: onPlayPause,
        ),
        const SizedBox(width: 34),
        _TransportButton(
          icon: CupertinoIcons.forward_fill,
          size: 26,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 52,
        child: Center(child: Icon(icon, size: size, color: _kText)),
      ),
    );
  }
}
