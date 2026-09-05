/// DartNative tutorial — Lottie in the hierarchy.
///
/// lib/screens/lottie/lottie_grid_demo.dart is a BYTE-IDENTICAL copy of the
/// DartNative playground's Lottie sticker-grid demo (lib/screens/home/
/// demo_ui.dart is the playground's shared UI kit, also verbatim). When the
/// playground demo improves, this tutorial updates by copying the file again.
///
/// The screen: 78 LIVE Lottie animations streamed from a CDN (.zip bundles,
/// disk-cached), recycled by a windowed FastGrid.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/lottie/lottie_grid_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const LottieGridDemo());
}
