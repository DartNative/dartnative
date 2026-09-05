import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/demos.dart';
import 'screens/video_playback_demo.dart';
import 'screens/cache_demo.dart';
import 'screens/hls_demo.dart';

void main() {
  // registerAll() wires the platform bindings AND calls VideoFFIBindings.loadSymbols().
  DartNativePluginRegistrant.registerAll();
  registerRoutes({
    '/video-playback': (_) => const VideoPlaybackDemo(),
    '/cache': (_) => const CacheDemo(),
    '/hls': (_) => const HlsDemo(),
  });
  runApp(const VideoDemosScreen());
}
