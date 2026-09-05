/// DartNative tutorial — native video in the hierarchy.
///
/// The two screens under lib/screens/media/ are BYTE-IDENTICAL copies of the
/// DartNative playground's video demos (lib/screens/home/demo_ui.dart is the
/// playground's shared UI kit, also verbatim). When the playground demos
/// improve, this tutorial updates by copying the files again:
///   • video_playback_demo.dart — VideoPlayerWithControls, the ready-made
///     player: play/pause, ±10 s, scrubber and fullscreen in one widget
///   • custom_controls_demo.dart — YouTube-style controls built from scratch
///     on the raw VideoPlayer + the same VideoPlayerController
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/media/custom_controls_demo.dart';
import 'screens/media/video_playback_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const VideoHome());
}

/// Two-row launcher built from the playground's own UI kit.
class VideoHome extends StatelessWidget {
  const VideoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Native video',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DemoRow(
            icon: CupertinoIcons.play_rectangle_fill,
            tint: kAccentRed,
            title: 'Playback',
            tagline: 'VideoPlayerWithControls — the ready-made player',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const VideoPlaybackDemo()),
            ),
          ),
          const SizedBox(height: 12),
          DemoRow(
            icon: CupertinoIcons.slider_horizontal_3,
            tint: kAccentTeal,
            title: 'Custom controls',
            tagline: 'YouTube-style UI on the chrome-less VideoPlayer',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const CustomControlsDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
