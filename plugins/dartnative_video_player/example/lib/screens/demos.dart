/// Video Player demo launcher.
///
/// Lists all available video demos. Tap any card to navigate.
/// Card style matches the DartNative demos page (superellipse r=34, dark bg).
library;

import 'package:dartnative/dartnative.dart';

import 'video_playback_demo.dart';
import 'custom_controls_demo.dart';
import 'cache_demo.dart';
import 'hls_demo.dart';

class VideoDemosScreen extends StatefulWidget {
  const VideoDemosScreen({super.key});

  @override
  State<VideoDemosScreen> createState() => _VideoDemosScreenState();
}

class _VideoDemosScreenState extends State<VideoDemosScreen> {
  @override
  void initState() {
    super.initState();
    // Dark app background → white status bar icons.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Color(0xFF1C1C1E),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'Video Player Demos',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          _DemoCard(
            title: 'Video Playback',
            body:
                'Core playback features: play, pause, resume, seek, skip '
                'forward/backward, speed control, and a full video '
                'controller overlay with progress bar.',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const VideoPlaybackDemo(),
                settings: '/video-playback',
              ),
            ),
          ),
          _DemoCard(
            title: 'Cache & PreCache',
            body:
                '3-controller prewarm architecture for instant video-to-video '
                'navigation. Background precaching with byte-limited disk '
                'cache, color-coded cache state, and selective eviction.',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const CacheDemo(),
                settings: '/cache',
              ),
            ),
          ),
          _DemoCard(
            title: 'Custom Video Controls',
            body:
                'YouTube-style controls built from scratch — thin red '
                'progress line, circle scrubber, centered play/pause, '
                'drag-to-seek, and mute toggle. No VideoPlayerWithControls.',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const CustomControlsDemo(),
                settings: '/custom-controls',
              ),
            ),
          ),
          _DemoCard(
            title: 'HLS Streaming',
            body:
                'HTTP Live Streaming playback with caching reverse proxy. '
                'Playlist parsing, segment caching, and adaptive bitrate '
                'streaming info.',
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => const HlsDemo(),
                settings: '/hls',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final void Function(BuildContext ctx) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(34),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
