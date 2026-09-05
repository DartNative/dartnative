/// Demo
///
/// Demonstrates the **3-controller prewarm architecture** for instant
/// video-to-video navigation using dartnative_video + native AVPlayer cache.
///
/// ## Steady-state — 3 controller roles
///
/// ```
///              ┌─────────────────────┐
///              │   _prevController   │  AVPlayer: prepared, paused, muted
///              └──────────┬──────────┘
///              ┌──────────▼──────────┐
///              │  _activeController  │  AVPlayer: playing, volume 1.0
///              └──────────┬──────────┘
///              ┌──────────▼──────────┐
///              │   _nextController   │  AVPlayer: prepared, paused, muted
///              └─────────────────────┘
/// ```
///
/// ## Navigation flow (goNext) — codec-slot-aware staggered prewarm
///
///   T+0ms   Promote next → active, dispose prev, prewarm NEXT
///   T+400ms Dispose old active, prewarm PREV
///   → Codec budget stays at exactly 3 slots.
library;

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

class CacheDemo extends StatefulWidget {
  const CacheDemo({super.key});

  @override
  State<CacheDemo> createState() => _CacheDemoState();
}

class _CacheDemoState extends State<CacheDemo> {
  // ── Feed URLs ─────────────────────────────────────────────────────────────
  static const List<String> _urls = [
    'https://cdn.dartpub.dev/assets/video/sintel_trailer.mp4',
    'https://cdn.dartpub.dev/assets/video/free_stock_5.mp4',
    'https://cdn.dartpub.dev/assets/video/free_stock_3.mp4',
    'https://cdn.dartpub.dev/assets/video/free_stock_4.mp4',
  ];

  // ── Controller roles ──────────────────────────────────────────────────────
  VideoPlayerController? _activeController;
  VideoPlayerController? _nextController;
  VideoPlayerController? _prevController;

  int _currentIndex = 0;
  int _requestId = 0;
  Timer? _prewarmTimer;

  // ── Silent precache state ─────────────────────────────────────────────────
  // Disk-precache status per URL index. "Loaded by player" (blue) is NOT
  // stored here — it's derived live in _isHeldByPlayer — so this map only
  // ever holds inProgress/done for URLs pushed to disk by VideoCache.preCache.
  bool _precacheInProgress = false;
  final Map<int, _UrlCacheState> _urlStates = {};

  // ignore: unused_field
  int _playStartMs = 0;

  final DateTime _t0 = DateTime.now();
  // ignore: unused_element
  String get _ts => '+${DateTime.now().difference(_t0).inMilliseconds}ms';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // url[0] is immediately loaded by the active controller. Its blue
    // "loaded by player" dot is derived live from the controller roles
    // (see _isHeldByPlayer), so there's no need to seed _urlStates here.
    _activeController = _createController(_urls[0], autoPlay: true);

    // Delay prewarm by 1s so the active controller's codec allocation settles.
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _prewarmAdjacent();
      // Repaint so the freshly prewarmed "next" controller lights up blue.
      setState(() {});
    });

    // Kick off silent background precaching.
    _precacheAll();
  }

  @override
  void dispose() {
    _prewarmTimer?.cancel();
    _activeController?.dispose();
    _nextController?.dispose();
    _prevController?.dispose();
    super.dispose();
  }

  // ── Controller factory ────────────────────────────────────────────────────

  VideoPlayerController _createController(
    String url, {
    required bool autoPlay,
  }) {
    final controller = VideoPlayerController(
      dataSource: VideoDataSource.network(
        url,
        cacheConfig: VideoCacheConfig(
          useCache: true,
          preCacheSize: 400 * 1024,
          maxCacheSize: 200 * 1024 * 1024,
          key: url,
        ),
      ),
      autoPlay: autoPlay,
      autoDispose: false,
    );
    controller.setLooping(true);
    controller.initialize();
    return controller;
  }

  // ── Prewarm system ────────────────────────────────────────────────────────

  void _prewarmAdjacent({bool nextOnly = false, bool prevOnly = false}) {
    if (!prevOnly) {
      final nextIdx = _currentIndex + 1;
      if (nextIdx < _urls.length && _nextController == null) {
        _nextController = _createController(_urls[nextIdx], autoPlay: false);
        _nextController!.setVolume(0.0);
      }
    }
    if (!nextOnly) {
      final prevIdx = _currentIndex - 1;
      if (prevIdx >= 0 && _prevController == null) {
        _prevController = _createController(_urls[prevIdx], autoPlay: false);
        _prevController!.setVolume(0.0);
      }
    }
  }

  void _disposePrewarmed() {
    _nextController?.dispose();
    _nextController = null;
    _prevController?.dispose();
    _prevController = null;
  }

  // ── Play with initialized-event fallback ──────────────────────────────────

  void _playController(VideoPlayerController controller) {
    _requestId++;
    final myId = _requestId;
    _playStartMs = DateTime.now().millisecondsSinceEpoch;

    controller.setVolume(1.0);

    Future.delayed(const Duration(milliseconds: 120), () {
      if (_requestId != myId) return;
      if (controller.isInitialized) {
        controller.play();
        return;
      }
      // Wait for initialized event.
      late void Function() listener;
      listener = () {
        if (controller.isInitialized) {
          controller.removeListener(listener);
          if (_requestId != myId) return;
          controller.play();
        }
      };
      controller.addListener(listener);
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  // Stable tear-off targets so the GestureDetector / BarButtonItem callback
  // identity never changes across `setState` rebuilds. The dartnative
  // framework calls `releaseCallback(...).close()` on the previous tap
  // NativeCallable whenever the new widget's callback `!=` the old one —
  // and a still-in-flight tap whose trampoline gets `.close()`d will SIGABRT
  // with "Callback invoked after it has been deleted." Bug-free path:
  //   - Use method tear-offs, NOT inline closures.
  //   - Use the SAME method object for the "disabled" case too — passing
  //     `null` would also flip identity each rebuild.

  void _goNextIgnored() {}

  void _goPrevIgnored() {}

  void _onSelectivePressed() {
    if (!_precacheInProgress) _clearCache(false);
  }

  void _onClearAllPressed() {
    if (!_precacheInProgress) _clearCache(true);
  }

  void _goNext() {
    if (_currentIndex >= _urls.length - 1) return;
    _prewarmTimer?.cancel();
    final oldActive = _activeController;

    VideoPlayerController? newController;
    if (_nextController != null) {
      newController = _nextController;
      _nextController = null;
    }
    _disposePrewarmed();

    newController ??= _createController(
      _urls[_currentIndex + 1],
      autoPlay: false,
    );

    if (newController.isInitialized) {
      newController.setVolume(0.0);
      newController.pause();
    }
    if (oldActive?.isInitialized == true) {
      oldActive!.setVolume(0.0);
      oldActive.pause();
    }

    _activeController = newController;
    _currentIndex++;
    _playController(_activeController!);

    // Staggered prewarm: NEXT immediately, PREV after 400ms.
    _prewarmAdjacent(nextOnly: true);
    _prewarmTimer = Timer(const Duration(milliseconds: 400), () {
      oldActive?.dispose();
      _prewarmAdjacent();
      // Repaint so the newly prewarmed PREV controller lights up blue.
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  void _goPrev() {
    if (_currentIndex <= 0) return;
    _prewarmTimer?.cancel();
    final oldActive = _activeController;

    VideoPlayerController? newController;
    if (_prevController != null) {
      newController = _prevController;
      _prevController = null;
    }
    _disposePrewarmed();

    newController ??= _createController(
      _urls[_currentIndex - 1],
      autoPlay: false,
    );

    if (newController.isInitialized) {
      newController.setVolume(0.0);
      newController.pause();
    }
    if (oldActive?.isInitialized == true) {
      oldActive!.setVolume(0.0);
      oldActive.pause();
    }

    _activeController = newController;
    _currentIndex--;
    _playController(_activeController!);

    _prewarmAdjacent(prevOnly: true);
    _prewarmTimer = Timer(const Duration(milliseconds: 400), () {
      oldActive?.dispose();
      _prewarmAdjacent();
      // Repaint so the newly prewarmed NEXT controller lights up blue.
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  // ── Background precaching ─────────────────────────────────────────────────

  Set<String> _activePlayerUrls() {
    final urls = <String>{};
    if (_currentIndex >= 0 && _currentIndex < _urls.length) {
      urls.add(_urls[_currentIndex]);
    }
    if (_currentIndex + 1 < _urls.length) urls.add(_urls[_currentIndex + 1]);
    if (_currentIndex - 1 >= 0) urls.add(_urls[_currentIndex - 1]);
    return urls;
  }

  Future<void> _precacheAll() async {
    setState(() => _precacheInProgress = true);
    try {
      // Skip disk-precaching any URL a live player already holds — those dots
      // are painted blue by _isHeldByPlayer at build time, and precaching a
      // URL the active player is already streaming just wastes bandwidth.
      final activeUrls = _activePlayerUrls();
      final urlsToCache = <int>[];
      for (int i = 0; i < _urls.length; i++) {
        if (!activeUrls.contains(_urls[i])) {
          urlsToCache.add(i);
        }
      }

      for (final i in urlsToCache) {
        setState(() => _urlStates[i] = _UrlCacheState.inProgress);
        VideoCache.preCache(
          _urls[i],
          cacheKey: _urls[i],
          preCacheSize: 400 * 1024,
        );
        // Small delay between precaches to avoid contention.
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _urlStates[i] = _UrlCacheState.done);
      }
    } finally {
      setState(() => _precacheInProgress = false);
    }
  }

  void _clearCache(bool removeAll) {
    VideoCache.clearCache(removeAll: removeAll);
    setState(() {
      // _urlStates now tracks disk-precache status only; blue "held by
      // player" dots are derived live, so a bare clear is enough.
      _urlStates.clear();
    });
    if (!removeAll) {
      _precacheAll();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < _urls.length - 1;
    final instantReady = _instantReadyCount;
    final allInstant = instantReady == _urls.length;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text(
          'Prewarm Cache Demo (3-controllers)',
          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
        ),
        leading: BackButton(iconColor: const Color(0xFFFFFFFF)),
        backgroundColor: const Color(0xFF000000),
        actions: [
          BarButtonItem(title: 'Selective', onPressed: _onSelectivePressed),
          BarButtonItem(title: 'Clear All', onPressed: _onClearAllPressed),
        ],
      ),
      body: Container(
        color: const Color(0xFF000000),
        child: Column(
          children: [
            // ── Status bar ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    allInstant
                        ? MaterialSymbolsRounded.check_circle
                        : MaterialSymbolsRounded.downloading,
                    color: allInstant
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFFFFAB40),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allInstant
                          ? 'All ${_urls.length} videos start instantly — no buffering ✓'
                          : '$instantReady of ${_urls.length} ready for instant start — caching the rest…',
                      style: TextStyle(
                        color: allInstant
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFFFFAB40),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Cache dot grid ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _urls.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _buildCacheDot(i),
                  ],
                ],
              ),
            ),

            // ── Video player ────────────────────────────────────────────
            // AspectRatio is passed directly to VideoPlayer — the native
            // renderer (Android VideoTextureView cover matrix / iOS
            // .resizeAspectFill) fills the slot while preserving the
            // video's natural aspect ratio.
            Expanded(
              child: Center(
                child: _activeController != null
                    ? VideoPlayer(
                        controller: _activeController!,
                        aspectRatio: 9 / 16,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // ── Prev / Next controls ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: canPrev ? _goPrev : _goPrevIgnored,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: canPrev
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x00000000),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            MaterialSymbolsRounded.arrow_back_ios,
                            size: 16,
                            color: canPrev
                                ? const Color(0xFFFFFFFF)
                                : const Color(0x3DFFFFFF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Prev',
                            style: TextStyle(
                              color: canPrev
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0x3DFFFFFF),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1} / ${_urls.length}',
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: canNext ? _goNext : _goNextIgnored,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: canNext
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x00000000),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color: canNext
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0x3DFFFFFF),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            MaterialSymbolsRounded.arrow_forward_ios,
                            size: 16,
                            color: canNext
                                ? const Color(0xFFFFFFFF)
                                : const Color(0x3DFFFFFF),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Legend ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: const Text(
                '🔵 Loaded   🟢 Cached   🟠 Caching   ⚪ Not ready\n'
                'Blue and green start instantly · white buffers on open.',
                style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// True when a live controller (active / prewarmed next / prewarmed prev)
  /// currently holds this index's video — i.e. it's "loaded by player".
  bool _isHeldByPlayer(int index) {
    if (index == _currentIndex) return true;
    if (_nextController != null && index == _currentIndex + 1) return true;
    if (_prevController != null && index == _currentIndex - 1) return true;
    return false;
  }

  /// How many videos would start instantly right now — i.e. either held open
  /// in a live player (🔵) or fully cached to disk (🟢). This is the number
  /// the user actually cares about: "how many start with no buffering?"
  int get _instantReadyCount {
    var n = 0;
    for (int i = 0; i < _urls.length; i++) {
      if (_isHeldByPlayer(i) || _urlStates[i] == _UrlCacheState.done) n++;
    }
    return n;
  }

  Widget _buildCacheDot(int index) {
    // "Loaded by player" is a live fact about the controller roles, so it's
    // derived on every build and wins over the stored disk-precache status.
    final state = _isHeldByPlayer(index)
        ? _UrlCacheState.byPlayer
        : (_urlStates[index] ?? _UrlCacheState.pending);
    final isActive = index == _currentIndex;

    final Color bg;
    final IconData icon;
    // Android composites alpha in sRGB without P3 promotion, so 0x99 over
    // black reads noticeably darker than on iOS. 0xCC (~80%) matches the
    // perceived brightness across platforms.
    switch (state) {
      case _UrlCacheState.done:
        bg = Color(isActive ? 0xFF69F0AE : 0xCC69F0AE);
        icon = MaterialSymbolsRounded.check_circle;
      case _UrlCacheState.inProgress:
        bg = Color(isActive ? 0xFFFFAB40 : 0xCCFFAB40);
        icon = MaterialSymbolsRounded.downloading;
      case _UrlCacheState.byPlayer:
        bg = Color(isActive ? 0xFF40C4FF : 0xCC40C4FF);
        icon = MaterialSymbolsRounded.play_circle;
      case _UrlCacheState.pending:
        bg = const Color(0x3DFFFFFF);
        icon = MaterialSymbolsRounded.radio_button_unchecked;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isActive ? 32 : 26,
          height: isActive ? 32 : 26,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: const Color(0xFFFFFFFF), width: 2)
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: isActive ? 18 : 14,
              color: const Color(0xFF000000),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${index + 1}',
          style: TextStyle(
            color: isActive ? const Color(0xFFFFFFFF) : const Color(0x61FFFFFF),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

enum _UrlCacheState { pending, byPlayer, inProgress, done }
