/// DartNative tutorial — the native canvas.
///
/// lib/screens/custom_paint_demo.dart is a BYTE-IDENTICAL copy of the
/// DartNative playground's CustomPaint demo (lib/screens/home/demo_ui.dart is
/// the playground's shared UI kit, also verbatim). When the playground screen
/// improves, this tutorial updates by copying the files again:
///   • custom_paint_demo.dart — eighteen painter sections on the platform's
///     own 2D renderer (Core Graphics on iOS, android.graphics.Canvas on
///     Android): shapes, charts, gradient shaders, the full paragraph
///     pipeline (metrics, hit testing, struts, foreground paints),
///     drawImage/drawImageRect, and two animated text painters
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/custom_paint_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const CustomPaintDemo());
}
