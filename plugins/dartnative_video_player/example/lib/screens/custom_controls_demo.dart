/// Custom Video Controls demo.
///
/// Shows how to build YouTube-style controls from scratch using the raw
/// [VideoPlayer] widget (no [VideoPlayerWithControls]).  Demonstrates:
///   • Thin red progress line (always visible at video bottom)
///   • Red circle scrubber that appears on touch
///   • Centered play/pause overlay with 3-second auto-hide
///   • Drag-to-seek via [GestureDetector] pan gestures
///   • Time labels (position / duration)
library;

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

class CustomControlsDemo extends StatefulWidget {
  const CustomControlsDemo({super.key});

  @override
  State<CustomControlsDemo> createState() => _CustomControlsDemoState();
}

class _CustomControlsDemoState extends State<CustomControlsDemo> {
  static const _videoUrl =
      'https://cdn.dartpub.dev/assets/video/sintel_trailer.mp4';

  late final VideoPlayerController _controller;

  /// Whether the overlay controls (play/pause + time) are visible.
  bool _showControls = true;

  /// Auto-hide timer — hides controls 3 s after last interaction.
  Timer? _hideTimer;

  /// Orientation poll (dartnative has no lifecycle observer).
  Timer? _orientationTimer;

  /// Whether the user is dragging the progress bar.
  bool _dragging = false;

  /// Held drag fraction while dragging (0.0–1.0).
  double? _dragFraction;

  /// Seek target while waiting for the controller to catch up.
  int? _seekTargetMs;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController(
      dataSource: VideoDataSource.network(
        _videoUrl,
        cacheConfig: const VideoCacheConfig(useCache: false),
      ),
      autoPlay: true,
      autoDispose: false,
    );
    _controller.initialize();
    _controller.addListener(_onControllerUpdate);
    _startHideTimer();

    _orientationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });

    // Lock this screen to portrait only.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Transparent system bar overlays with light (white) text.
    SystemChrome.setStatusBarColor(const Color.fromARGB(0, 0, 0, 0));
    SystemChrome.setNavigationBarColor(const Color.fromARGB(0, 0, 0, 0));
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _orientationTimer?.cancel();
    // Restore all orientations when leaving this screen.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    // Restore default status bar.
    SystemChrome.setStatusBarColor(null);
    SystemChrome.setNavigationBarColor(null);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  // ── Controller listener ─────────────────────────────────────────────────

  void _onControllerUpdate() {
    if (!mounted) return;
    // Clear held drag fraction once controller catches up.
    if (_seekTargetMs != null && !_dragging && _dragFraction != null) {
      final diff = (_controller.positionMs - _seekTargetMs!).abs();
      if (diff < 500) {
        _dragFraction = null;
        _seekTargetMs = null;
      }
    }
    setState(() {});
  }

  // ── Auto-hide timer ─────────────────────────────────────────────────────

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_controller.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _controller.isPlaying) _startHideTimer();
  }

  // ── Play / Pause ────────────────────────────────────────────────────────

  void _playPause() {
    final c = _controller;
    if (c.positionMs >= c.durationMs && c.durationMs > 0) {
      c.seekTo(Duration.zero);
      c.play();
    } else if (c.isPlaying) {
      c.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      c.play();
      _startHideTimer();
    }
  }

  // ── Skip ±10 s ──────────────────────────────────────────────────────────

  void _skipBack() {
    final target = (_controller.positionMs - 10000).clamp(
      0,
      _controller.durationMs,
    );
    _controller.seekTo(Duration(milliseconds: target));
    _startHideTimer();
  }

  void _skipForward() {
    final target = _controller.positionMs + 10000;
    if (target > _controller.durationMs) {
      _controller.seekTo(Duration(milliseconds: _controller.durationMs));
      _controller.pause();
    } else {
      _controller.seekTo(Duration(milliseconds: target));
    }
    _startHideTimer();
  }

  // ── Seek by drag ────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details, double barWidth) {
    _dragging = true;
    _showControls = true;
    _hideTimer?.cancel();
    setState(() {
      _dragFraction = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double barWidth) {
    setState(() {
      _dragFraction = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragging = false;
    _commitSeek();
    _startHideTimer();
  }

  void _onTapDown(TapDownDetails details, double barWidth) {
    setState(() {
      _dragFraction = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
    });
    _commitSeek();
    _startHideTimer();
  }

  void _commitSeek() {
    if (_dragFraction != null && _controller.durationMs > 0) {
      final ms = (_dragFraction! * _controller.durationMs).toInt();
      _seekTargetMs = ms;
      _controller.seekTo(Duration(milliseconds: ms));
    }
  }

  // ── Time formatting ─────────────────────────────────────────────────────

  String _formatMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final fraction =
        _dragFraction ??
        (_controller.durationMs > 0
            ? (_controller.positionMs / _controller.durationMs).clamp(0.0, 1.0)
            : 0.0);

    // Progress bar width = full screen width (edge-to-edge).
    final barWidth = screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: isLandscape
          ? null
          : AppBar(
              title: const Text(
                'Custom Controls',
                style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
              ),
              backgroundColor: const Color(0xFF000000),
              leading: BackButton(iconColor: const Color(0xFFFFFFFF)),
            ),
      body: Container(
        color: const Color(0xFF000000),
        child: Column(
          children: [
            // Video + overlay stack.
            Stack(
              children: [
                // Raw video player — no built-in controls.
                VideoPlayer(controller: _controller, aspectRatio: 16 / 9),

                // Tap target for show/hide + play/pause
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _toggleControls,
                    onDoubleTap: _playPause,
                    child: Container(
                      color: const Color(0x00000000), // transparent hit area
                    ),
                  ),
                ),

                // ── Centered transport: ⏪10 | ▶ | 10⏩ ─────────────────
                // Always present, hidden via Opacity to keep Stack child
                // indices stable (avoids reconciler index-mismatch).
                // Opacity must be INSIDE Positioned (Stack strips outer wrappers).
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Replay 10 s ──
                          GestureDetector(
                            onTap: _skipBack,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(0, 0, 0, 0.5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Icon(
                                  MaterialSymbolsRounded.replay_10,
                                  size: 28,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // ── Play / Pause (filled) ──
                          GestureDetector(
                            onTap: _playPause,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(0, 0, 0, 0.5),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Center(
                                child: Icon(
                                  _controller.isPlaying
                                      ? CupertinoIcons.pause_fill
                                      : CupertinoIcons.play_fill,
                                  size: 36,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // ── Forward 10 s ──
                          GestureDetector(
                            onTap: _skipForward,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(0, 0, 0, 0.5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Icon(
                                  MaterialSymbolsRounded.forward_10,
                                  size: 28,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Time labels (bottom-left / bottom-right) ───────────
                Positioned(
                  left: 12,
                  bottom: 14,
                  child: Opacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    child: Text(
                      _formatMs(_controller.positionMs),
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 14,
                  child: Opacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    child: Text(
                      _formatMs(_controller.durationMs),
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // ── YouTube-style thin progress bar (always visible) ───
                // Last child = highest z-index so drag is never blocked
                // by the tap-target overlay or transport buttons above.
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: GestureDetector(
                    // `opaque` makes the (otherwise transparent) 44-pt hit
                    // strip claim hit-test ownership instead of falling
                    // through to the tap-target overlay below it.
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _onPanStart(d, barWidth),
                    onPanUpdate: (d) => _onPanUpdate(d, barWidth),
                    onPanEnd: _onPanEnd,
                    onTapDown: (d) => _onTapDown(d, barWidth),
                    child: Container(
                      width: barWidth,
                      height: 44,
                      color: const Color(0x00000000), // transparent hit area
                      child: Stack(
                        children: [
                          // Background track at the very bottom of the
                          // 44-px hit area (flush with the video's edge).
                          Positioned(
                            left: 0,
                            bottom: 0,
                            width: barWidth,
                            height: 3,
                            child: Container(
                              color: const Color.fromRGBO(255, 255, 255, 0.2),
                            ),
                          ),
                          // Played (red fill)
                          Positioned(
                            left: 0,
                            bottom: 0,
                            width: (barWidth * fraction).clamp(0.0, barWidth),
                            height: 3,
                            child: Container(color: const Color(0xFFFF0000)),
                          ),
                          // Red circle scrubber — straddle the video border.
                          Positioned(
                            left: ((barWidth * fraction) - 6).clamp(
                              0.0,
                              barWidth - 12,
                            ),
                            bottom: -4,
                            width: 12,
                            height: 12,
                            child: Opacity(
                              opacity: _showControls ? 1.0 : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Transparent spacer so the scrubber circle isn't clipped.
            const SizedBox(height: 6),

            // Below-video info area
            Expanded(
              child: Container(
                color: const Color(0xFF000000),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custom Video Controls',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'YouTube-style controls built from scratch using the raw '
                      'VideoPlayer widget, GestureDetector, Stack, and '
                      'Positioned — no VideoPlayerWithControls.',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Volume',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            final v = _controller.volume > 0.0 ? 0.0 : 1.0;
                            _controller.setVolume(v);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3C),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Icon(
                                _controller.volume > 0.0
                                    ? MaterialSymbolsRounded.volume_up
                                    : MaterialSymbolsRounded.volume_off,
                                size: 22,
                                color: const Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
