/// HLS Streaming demo.
///
/// Demonstrates HTTP Live Streaming playback through the plugin's built-in
/// HLS reverse proxy with segment caching. Shows stream info, cache state,
/// and allows switching between Apple's public HLS test streams.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

class HlsDemo extends StatefulWidget {
  const HlsDemo({super.key});

  @override
  State<HlsDemo> createState() => _HlsDemoState();
}

class _HlsDemoState extends State<HlsDemo> {
  // Apple's public HLS test streams.
  static const _streams = <_HlsStream>[
    _HlsStream(
      title: 'Bipbop (Basic)',
      url:
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8',
      description: 'Apple adaptive-bitrate test stream with multiple variants.',
    ),
    _HlsStream(
      title: 'Advanced fMP4',
      url:
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
      description: 'Fragmented MP4 stream with Dolby Vision + Atmos tracks.',
    ),
    _HlsStream(
      title: 'Basic 16:9 (gear)',
      url:
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
      description: 'Simple 16:9 multi-bitrate test pattern.',
    ),
  ];

  int _selectedIndex = 0;
  VideoPlayerController? _controller;
  bool _cacheEnabled = true;

  @override
  void initState() {
    super.initState();
    // Dark-by-design screen: pin dark chrome regardless of the app theme.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    _loadStream(0);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _loadStream(int index) {
    _controller?.dispose();
    _selectedIndex = index;
    final stream = _streams[index];

    _controller = VideoPlayerController(
      dataSource: VideoDataSource.network(
        stream.url,
        cacheConfig: _cacheEnabled
            ? const VideoCacheConfig(
                useCache: true,
                preCacheSize: 2 * 1024 * 1024, // 2 MB head
                maxCacheSize: 200 * 1024 * 1024, // 200 MB total
              )
            : VideoCacheConfig.none,
        videoExtension: 'm3u8',
      ),
      autoPlay: true,
      autoDispose: false,
    );
    _controller!.addListener(_onUpdate);
    _controller!.initialize();
    setState(() {});
  }

  void _onUpdate() => setState(() {});

  void _toggleCache() {
    setState(() => _cacheEnabled = !_cacheEnabled);
    // Reload with new setting.
    _loadStream(_selectedIndex);
  }

  void _clearCache() {
    VideoCache.clearCache(removeAll: true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stream = _streams[_selectedIndex];

    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'HLS Streaming',
          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
        ),
        backgroundColor: const Color(0xFF000000),
        leading: BackButton(iconColor: const Color(0xFFFFFFFF)),
        actions: [BarButtonItem(title: 'Clear Cache', onPressed: _clearCache)],
      ),
      body: Column(
        children: [
          // ── Video player ──────────────────────────────────────────
          _controller != null
              ? VideoPlayer(controller: _controller!, aspectRatio: 16 / 9)
              : AspectRatio(
                  aspectRatio: 16 / 9,
                  child: const SizedBox.shrink(),
                ),

          // ── Stream info ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream.title,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stream.description,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stream.url,
                  style: const TextStyle(
                    color: Color(0x4DFFFFFF),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // ── Cache toggle ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'HLS Proxy Cache',
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleCache,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _cacheEnabled
                          ? const Color(0xFF34C759)
                          : const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _cacheEnabled ? 'ON' : 'OFF',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Stream selector ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Test Streams',
                  style: TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _streams.length; i++)
                  _StreamTile(
                    stream: _streams[i],
                    isSelected: i == _selectedIndex,
                    onTap: () => _loadStream(i),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // ── Info footer ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: const Text(
              'Built-in proxy runs on 127.0.0.1, intercepts .m3u8 playlists\n'
              'and caches .ts segments via PINCache. Falls back to native\n'
              'AVFoundation HLS if proxy port is unavailable.',
              style: TextStyle(color: Color(0x4DFFFFFF), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stream tile ─────────────────────────────────────────────────────────────

class _StreamTile extends StatelessWidget {
  const _StreamTile({
    required this.stream,
    required this.isSelected,
    required this.onTap,
  });

  final _HlsStream stream;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1A0A84FF) : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFF0A84FF), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0A84FF)
                          : const Color(0xFFFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stream.description,
                    style: const TextStyle(
                      color: Color(0x66FFFFFF),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 20,
                color: Color(0xFF0A84FF),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Model ───────────────────────────────────────────────────────────────────

class _HlsStream {
  const _HlsStream({
    required this.title,
    required this.url,
    required this.description,
  });

  final String title;
  final String url;
  final String description;
}
