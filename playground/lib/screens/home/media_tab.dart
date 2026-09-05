/// Media tab — images, video (dartnative_video_player), audio
/// (dartnative_audio), and on-device TTS (dartnative_supertonic_tts).
/// The video/audio/TTS screens are the plugins' own examples, ported.
import 'package:dartnative/dartnative.dart';

import '../image_demo.dart';
import '../media/audio_demo.dart';
import '../media/cache_demo.dart';
import '../media/camera_demo.dart';
import '../media/custom_controls_demo.dart';
import '../media/hls_demo.dart';
import '../media/supertonic_demo.dart';
import '../media/video_playback_demo.dart';
import 'demo_ui.dart';

class MediaTab extends StatelessWidget {
  const MediaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kHomeBg,
      child: ListView(
        children: [
          SizedBox(height: tabListTopGap(context)),
          const SectionHeader('IMAGES'),
          DemoRow(
            icon: CupertinoIcons.photo_fill,
            tint: kAccentBlue,
            title: 'Image & Caching',
            tagline: 'Cache policies, precache, BoxFit, eviction',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const ImageDemo(), settings: '/image'),
            ),
          ),
          const SectionHeader('VIDEO'),
          DemoRow(
            icon: CupertinoIcons.play_rectangle_fill,
            tint: kAccentRed,
            title: 'Video Playback',
            tagline: 'AVPlayer / ExoPlayer over FFI',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const VideoPlaybackDemo(),
                settings: '/video-playback',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.arrow_2_circlepath,
            tint: kAccentOrange,
            title: 'Cache & PreCache',
            tagline: 'Warm the cache before first play',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const CacheDemo(),
                settings: '/video-cache',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.slider_horizontal_3,
            tint: kAccentTeal,
            title: 'Custom Video Controls',
            tagline: 'Chrome-less player, your own UI',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const CustomControlsDemo(),
                settings: '/video-controls',
              ),
            ),
          ),
          DemoRow(
            icon: CupertinoIcons.wifi,
            tint: kAccentIndigo,
            title: 'HLS Streaming',
            tagline: 'Live / adaptive streams',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                  builder: (_) => const HlsDemo(), settings: '/video-hls'),
            ),
          ),
          const SectionHeader('CAMERA'),
          DemoRow(
            icon: CupertinoIcons.camera_fill,
            tint: kAccentYellow,
            title: 'Camera',
            tagline: 'Live preview + capture · AVFoundation / CameraX',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                  builder: (_) => const CameraDemo(), settings: '/camera'),
            ),
          ),
          const SectionHeader('AUDIO'),
          DemoRow(
            icon: CupertinoIcons.speaker_2_fill,
            tint: kAccentGreen,
            title: 'Audio Player',
            tagline: 'Assets, URLs, PCM streaming',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const AudioDemo(), settings: '/audio'),
            ),
          ),
          const SectionHeader('TTS'),
          DemoRow(
            icon: CupertinoIcons.bubble_left_fill,
            tint: kAccentPurple,
            title: 'SuperTonic TTS',
            tagline: 'On-device speech synthesis (ONNX)',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(
                builder: (_) => const SuperTonicDemo(),
                settings: '/tts-supertonic',
              ),
            ),
          ),
          SizedBox(height: tabListBottomGap(context)),
        ],
      ),
    );
  }
}
