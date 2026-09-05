/// DartNative tutorial — photo grid, infinitely.
///
/// The screen under lib/screens/ is a BYTE-IDENTICAL copy of the DartNative
/// playground's grid demo (lib/screens/home/demo_ui.dart is the playground's
/// shared UI kit, also verbatim). When the playground demo improves, this
/// tutorial updates by copying the files again:
///   • grid_demo.dart — three tabs: static GridView.count / GridView.builder,
///     MasonryFastGrid with variable heights + load-more, and an infinite
///     FastGrid (UICollectionView / RecyclerView) paged by native scroll
///     telemetry
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/grid_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const GridDemo());
}
