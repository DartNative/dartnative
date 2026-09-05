/// Portrait-mode video controls — bottom bar with play/pause, position,
/// progress slider, and remaining time.
///
/// Portrait video controls.
library;

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

import 'video_utils.dart';

class VideoPortraitControls extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoPortraitControls({super.key, required this.controller});

  @override
  State<VideoPortraitControls> createState() => _VideoPortraitControlsState();
}

class _VideoPortraitControlsState extends State<VideoPortraitControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  void _onPlayPause() {
    final c = widget.controller;
    if (c.positionMs >= c.durationMs && c.durationMs > 0) {
      c.seekTo(const Duration(seconds: 0));
      c.play();
    } else {
      if (c.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final dur = c.durationMs;
    final pos = c.positionMs.clamp(0, dur > 0 ? dur : 1);
    final position = Duration(milliseconds: pos);
    final remaining = dur > 0
        ? Duration(milliseconds: dur - pos)
        : Duration.zero;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play/Pause button
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: _onPlayPause,
                borderRadius: BorderRadius.circular(30),
                child: Icon(
                  c.isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: const Color(0xFFFFFFFF),
                  size: 22,
                ),
              ),
            ),
            // Position
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                formatDuration(position),
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Progress Slider
            SizedBox(
              width: 200,
              child: Slider(
                value: pos.toDouble(),
                min: 0,
                max: dur > 0 ? dur.toDouble() : 1,
                onChanged: (v) {
                  c.seekTo(Duration(milliseconds: v.toInt()));
                },
                activeColor: const Color(0xB3FAFAFA),
                inactiveColor: const Color(0x1A969696),
                thumbColor: const Color(0xFFFAFAFA),
              ),
            ),
            // Remaining
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                formatDuration(remaining),
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
