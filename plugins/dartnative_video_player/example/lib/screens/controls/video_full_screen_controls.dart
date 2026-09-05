/// Full-screen video controls overlay — tap to show/hide, with center
/// play/pause/rewind/forward buttons, bottom progress bar, and auto-hide.
///
/// Full-screen video controls.
library;

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

import 'video_utils.dart';

class VideoFullScreenControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onExitFullScreen;

  const VideoFullScreenControls({
    super.key,
    required this.controller,
    this.onExitFullScreen,
  });

  @override
  State<VideoFullScreenControls> createState() =>
      _VideoFullScreenControlsState();
}

class _VideoFullScreenControlsState extends State<VideoFullScreenControls> {
  bool _visible = true;
  Timer? _hideTimer;

  static const _skipDuration = Duration(seconds: 5);
  static const _autoHideDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  // ── Visibility ──────────────────────────────────────────────────────────

  void _toggleControls() {
    setState(() => _visible = !_visible);
    if (_visible && widget.controller.isPlaying) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDuration, () {
      if (!mounted) return;
      if (widget.controller.isPlaying) {
        setState(() => _visible = false);
      }
    });
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _playPause() {
    final c = widget.controller;
    if (c.positionMs >= c.durationMs && c.durationMs > 0) {
      c.seekTo(const Duration(seconds: 0));
      c.play();
      setState(() => _visible = false);
    } else if (c.isPlaying) {
      c.pause();
      setState(() => _visible = true);
    } else {
      c.play();
      setState(() => _visible = false);
    }
  }

  void _rewind() {
    final target = (widget.controller.positionMs - _skipDuration.inMilliseconds)
        .clamp(0, widget.controller.durationMs);
    widget.controller.seekTo(Duration(milliseconds: target));
    _cancelAndRestartTimer();
  }

  void _forward() {
    final target = (widget.controller.positionMs + _skipDuration.inMilliseconds)
        .clamp(0, widget.controller.durationMs);
    widget.controller.seekTo(Duration(milliseconds: target));
    _cancelAndRestartTimer();
  }

  void _onSeek(double value) {
    widget.controller.seekTo(Duration(milliseconds: value.toInt()));
    _cancelAndRestartTimer();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final dur = c.durationMs;
    final pos = c.positionMs.clamp(0, dur > 0 ? dur : 1);
    final position = Duration(milliseconds: pos);
    final duration = Duration(milliseconds: dur);

    return Stack(
      children: [
        // Tap anywhere to toggle controls
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleControls,
            child: Container(color: const Color(0x00000000)),
          ),
        ),

        // Double-tap zones: left = rewind, right = forward
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _rewind,
                  child: Container(color: const Color(0x00000000)),
                ),
              ),
              const Spacer(),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _forward,
                  child: Container(color: const Color(0x00000000)),
                ),
              ),
            ],
          ),
        ),

        // Background overlay
        if (_visible)
          Positioned.fill(child: Container(color: const Color(0x40000000))),

        // Center buttons: rewind, play/pause, forward
        if (_visible)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CircleButton(
                  icon: CupertinoIcons.gobackward,
                  onTap: _rewind,
                  size: 48,
                  iconSize: 25,
                ),
                const SizedBox(width: 35),
                _CircleButton(
                  icon: c.isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  onTap: _playPause,
                  size: 64,
                  iconSize: 34,
                ),
                const SizedBox(width: 35),
                _CircleButton(
                  icon: CupertinoIcons.goforward,
                  onTap: _forward,
                  size: 48,
                  iconSize: 25,
                ),
              ],
            ),
          ),

        // Bottom bar: position / duration + fullscreen icon + slider
        if (_visible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Time row + fullscreen icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            formatDuration(position),
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' / ${formatDuration(duration)}',
                            style: const TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (widget.onExitFullScreen != null)
                        GestureDetector(
                          onTap: widget.onExitFullScreen,
                          child: const Icon(
                            CupertinoIcons.fullscreen_exit,
                            color: Color(0xFFFFFFFF),
                            size: 26,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Progress slider
                  Slider(
                    value: pos.toDouble(),
                    min: 0,
                    max: dur > 0 ? dur.toDouble() : 1,
                    onChanged: _onSeek,
                    activeColor: const Color(0xB3FAFAFA),
                    inactiveColor: const Color(0x1A969696),
                    thumbColor: const Color(0xFFFAFAFA),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Circular icon button ──────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.iconSize = 25,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Center(
          child: Icon(icon, size: iconSize, color: const Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}
