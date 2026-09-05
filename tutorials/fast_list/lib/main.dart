/// DartNative tutorial — lists that never jank.
///
/// The screen under lib/screens/ is a BYTE-IDENTICAL copy of the DartNative
/// playground's FastList demo (lib/screens/home/demo_ui.dart is the
/// playground's shared UI kit, also verbatim). When the playground demo
/// improves, this tutorial updates by copying the files again:
///   • fast_list_demo.dart — the full long-list recipe on the platform's
///     native list (UITableView / RecyclerView): itemBuilder, onScroll
///     pagination (50 → 10,000 rows), stableItems, keepAliveCount content
///     windowing, FastListController index scrolling — with the playground's
///     honest mount-time + RSS memory harness in the result line
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/fast_list_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const FastListDemo());
}
