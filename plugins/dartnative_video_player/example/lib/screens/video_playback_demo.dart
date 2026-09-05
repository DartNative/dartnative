/// Video Playback demo.
///
/// Showcases the convenience [VideoPlayerWithControls] widget — a single
/// widget that wraps a video player with an overlay controls UI.
library;

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

class VideoPlaybackDemo extends StatefulWidget {
  const VideoPlaybackDemo({super.key});

  @override
  State<VideoPlaybackDemo> createState() => _VideoPlaybackDemoState();
}

class _VideoPlaybackDemoState extends State<VideoPlaybackDemo> {
  static const _videoUrl =
      'https://cdn.dartpub.dev/assets/video/sintel_trailer.mp4';

  late final VideoPlayerController _controller;

  /// Periodic timer to force rebuilds so [MediaQuery.orientationOf] picks up
  /// device rotation.  dartnative has no InheritedWidget-based orientation
  /// or lifecycle observer, so a manual poll is the pragmatic workaround.
  Timer? _orientationTimer;

  /// While non-null, a listener waiting for the phone to be physically upright
  /// so it can re-enable free rotation after a "minimize" locked us to portrait.
  VoidCallback? _unlockOnPortrait;

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
    _orientationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _orientationTimer?.cancel();
    _disarmUnlockOnPortrait();
    // Never leave the app orientation-locked once this screen is gone.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// Return to portrait when the user taps "minimize" in landscape fullscreen.
  ///
  /// The minimize button only exists in landscape, so the phone is physically
  /// landscape here. Locking to portraitUp rotates the UI upright and keeps it
  /// there even while the phone is still held sideways — restoring rotation
  /// immediately would make iOS follow the device straight back to landscape.
  /// Rotation is re-enabled only once the user physically turns the phone
  /// upright (like YouTube's minimize), so landscape fullscreen still works.
  void _forcePortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _armUnlockOnPortrait();
  }

  void _armUnlockOnPortrait() {
    _disarmUnlockOnPortrait();
    void listener() {
      if (DeviceOrientationListener.current == DeviceOrientation.portraitUp) {
        _disarmUnlockOnPortrait();
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }

    _unlockOnPortrait = listener;
    DeviceOrientationListener.currentNotifier.addListener(listener);
  }

  void _disarmUnlockOnPortrait() {
    final listener = _unlockOnPortrait;
    if (listener != null) {
      DeviceOrientationListener.currentNotifier.removeListener(listener);
      _unlockOnPortrait = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: isLandscape
          ? null
          : AppBar(
              title: const Text(
                'Video Playback',
                style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
              ),
              backgroundColor: const Color(0xFF000000),
              leading: BackButton(iconColor: const Color(0xFFFFFFFF)),
            ),
      body: Container(
        color: const Color(0xFF000000),
        child: VideoPlayerWithControls(
          controller: _controller,
          controlsMode: VideoControlsMode.bottomBar,
          onExitFullScreen: _forcePortrait,
        ),
      ),
    );
  }
}
