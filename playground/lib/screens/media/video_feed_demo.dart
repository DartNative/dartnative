/// Infinite video feed demo.
///
/// A vertical [PageView] of full-screen videos with no end: `PageView.builder`
/// with a null `itemCount` adds pages as the user nears the last one. One
/// swipe is one page, on the platform's own paging. Players are pooled around
/// the page under the finger (the page, the next two, the previous one), the
/// first bytes of the pages after those are fetched into the disk cache ahead
/// of time, and playback switches as a swipe crosses the midpoint, so the next
/// video is already showing its first frame when its page arrives.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

import '../home/demo_ui.dart' show playgroundOverlayStyle;

/// Live players around the current page: the page, two ahead and one behind
/// on iOS, which is the whole pool window; three on Android, where hardware
/// decoder instances are scarcer.
final int _kMaxLivePlayers = Platform.isIOS ? 4 : 3;

/// Pages ahead of the current one that get a live player.
const int _kPreloadAhead = 2;

/// Pages beyond the pool window whose first bytes are fetched anyway, so the
/// fetch starts a page before the player is created.
const int _kPreCacheBeyond = 1;

/// Bytes fetched ahead per upcoming page: several seconds of a 720p clip.
const int _kPreCacheBytes = 2 * 1024 * 1024;
const int _kDiskCacheBytes = 100 * 1024 * 1024;

/// A player that left the window is paused at once and disposed after this
/// grace, so a swipe straight back finds it still alive.
const Duration _kDisposeGrace = Duration(milliseconds: 250);

class _FeedVideo {
  const _FeedVideo(
    this.id,
    this.file,
    this.posterFile,
    this.width,
    this.height,
    this.seconds,
  );

  final int id;
  final String file;
  final String posterFile;
  final int width;
  final int height;
  final int seconds;

  String get url => 'https://videos.pexels.com/video-files/$id/$file';
  String get poster => 'https://images.pexels.com/videos/$id/pictures/$posterFile';
  double get aspectRatio => width / height;
}

/// Free clips from Pexels; the feed loops over them.
const List<_FeedVideo> _kVideos = [
  _FeedVideo(5329239, '5329239-hd_1080_2048_25fps.mp4', 'preview-0.jpeg', 1080, 2048, 64),
  _FeedVideo(5386411, '5386411-hd_1080_2048_25fps.mp4', 'preview-0.jpeg', 1080, 2048, 15),
  _FeedVideo(1409899, '1409899-hd_1280_720_25fps.mp4', 'preview-0.jpg', 1280, 720, 21),
  _FeedVideo(7438482, '7438482-hd_1080_1872_30fps.mp4', 'preview-0.jpeg', 1080, 1872, 9),
  _FeedVideo(856973, '856973-hd_1280_720_25fps.mp4', 'preview-0.jpg', 1280, 720, 14),
  _FeedVideo(2169880, '2169880-hd_1280_720_30fps.mp4', 'preview-0.jpg', 1280, 720, 86),
  _FeedVideo(3163534, '3163534-hd_1280_720_30fps.mp4', 'preview-0.jpg', 1280, 720, 30),
  _FeedVideo(1093662, '1093662-hd_1280_720_30fps.mp4', 'preview-0.jpg', 1280, 720, 30),
  _FeedVideo(1093667, '1093667-hd_1280_720_30fps.mp4', 'preview-0.jpg', 1280, 720, 13),
];

class VideoFeedDemo extends StatefulWidget {
  const VideoFeedDemo({super.key});

  @override
  State<VideoFeedDemo> createState() => _VideoFeedDemoState();
}

class _VideoFeedDemoState extends State<VideoFeedDemo> {
  final Map<int, VideoPlayerController> _players = {};
  final Map<int, StreamSubscription<VideoEvent>> _events = {};
  final Set<int> _disposing = {};
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    // A dark, full-bleed screen whatever the app theme.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    VideoCache.configure(maxCacheSize: _kDiskCacheBytes);
    _ensureWindow(0);
  }

  @override
  void dispose() {
    for (final s in _events.values) {
      s.cancel();
    }
    for (final p in _players.values) {
      p.dispose();
    }
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
    super.dispose();
  }

  _FeedVideo _videoAt(int page) => _kVideos[page % _kVideos.length];

  // ── Player pool ────────────────────────────────────────────────────────────

  void _ensureWindow(int center) {
    // Filled in the order the user needs it: the page under the finger, then
    // the next, then the previous, then the one after next.
    final wanted = <int>[
      center,
      center + 1,
      center - 1,
      for (var k = 2; k <= _kPreloadAhead; k++) center + k,
    ].where((page) => page >= 0);

    for (final page in wanted) {
      if (_players.containsKey(page)) continue;
      if (_players.length >= _kMaxLivePlayers) {
        if (page != center) break;
        // The current page never waits for the grace: the live player
        // farthest from it goes now.
        final victim = _players.keys.reduce(
          (a, b) => (a - center).abs() >= (b - center).abs() ? a : b,
        );
        _drop(victim);
      }
      _create(page);
    }

    // The first bytes of what is coming, into the disk cache.
    final last = center + _kPreloadAhead + _kPreCacheBeyond;
    for (var page = center + 1; page <= last; page++) {
      final url = _videoAt(page).url;
      VideoCache.preCache(url, cacheKey: url, preCacheSize: _kPreCacheBytes);
    }
  }

  void _create(int page) {
    final video = _videoAt(page);
    final player = VideoPlayerController(
      dataSource: VideoDataSource.network(
        video.url,
        cacheConfig: VideoCacheConfig(
          useCache: true,
          preCacheSize: _kPreCacheBytes,
          maxCacheSize: _kDiskCacheBytes,
          key: video.url,
        ),
        videoExtension: 'mp4',
        // Start on half a second of media instead of the player's default.
        bufferingConfig: VideoBufferingConfig.feed,
      ),
      autoPlay: false,
      autoDispose: false,
    );
    player.setHintAspectRatio(video.aspectRatio);
    player.setFit(BoxFit.cover);
    _events[page] = player.events.listen((event) {
      if (!mounted || event.type != VideoEventType.initialized) return;
      player.setLooping(true);
      player.setFit(BoxFit.cover);
      if (page == _activePage) player.play();
      // The page shows the player from its first decodable frame on; the
      // poster stays until then.
      setState(() {});
    });
    _players[page] = player;
    player.initialize();
  }

  void _drop(int page) {
    _disposing.remove(page);
    _events.remove(page)?.cancel();
    _players.remove(page)?.dispose();
  }

  void _releaseOutside(int center) {
    final keep = <int>{
      center - 1,
      center,
      for (var k = 1; k <= _kPreloadAhead; k++) center + k,
    };
    for (final page in _players.keys.toList()) {
      if (keep.contains(page) || _disposing.contains(page)) continue;
      _disposing.add(page);
      _players[page]?.pause();
      Future.delayed(_kDisposeGrace, () {
        _disposing.remove(page);
        if (!mounted) return;
        if (_activePage - 1 <= page && page <= _activePage + _kPreloadAhead) {
          return;
        }
        _drop(page);
        _ensureWindow(_activePage);
        setState(() {});
      });
    }
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  /// Fires as a swipe crosses the midpoint between two pages.
  void _onPageChanged(int page) {
    _activePage = page;
    _ensureWindow(page);
    for (final entry in _players.entries) {
      if (entry.key == page) {
        if (entry.value.isInitialized) entry.value.play();
      } else {
        entry.value.pause();
      }
    }
    _releaseOutside(page);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.dark,
      backgroundColor: Colors.black,
      // The bar floats over the video: a clear surface, and the feed runs
      // the full height behind it.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Video #$_activePage',
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
        ),
        leading: BackButton(iconColor: const Color(0xFFFFFFFF)),
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        // One extra page built on each side, which is the pool window.
        allowImplicitScrolling: true,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, page) => _FeedPage(
          video: _videoAt(page),
          player: _players[page],
          isActive: page == _activePage,
        ),
      ),
    );
  }
}

/// One full-screen page. Its structure is fixed: the poster, a player slot
/// that is empty until the first frame can be decoded, then the overlays.
/// Filling the slot changes one child; inserting the player instead would
/// move every overlay.
class _FeedPage extends StatelessWidget {
  const _FeedPage({
    required this.video,
    required this.player,
    required this.isActive,
  });

  final _FeedVideo video;
  final VideoPlayerController? player;
  final bool isActive;

  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final ready = player != null && player!.isInitialized;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(video.poster, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: ready
              ? VideoPlayer(controller: player!, fit: BoxFit.cover)
              : const SizedBox.shrink(),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: insets.bottom + 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A Row keeps the capsule its own width instead of the
              // column's full width.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Badge(
                    child: Text(
                      isActive ? '● PLAYING' : '○ PAUSED',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF4ADE80) : _white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pexels · ${video.id} · ${video.seconds}s',
                style: const TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: const BoxDecoration(
      color: Color(0x99000000),
      // A capsule: a radius past half the height rounds the ends fully.
      borderRadius: BorderRadius.all(Radius.circular(999)),
    ),
    child: child,
  );
}
