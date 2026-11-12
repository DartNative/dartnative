/// DartNative tutorial: a camera screen.
///
/// lib/screens/media/camera_demo.dart is a BYTE-IDENTICAL copy of the
/// DartNative playground's camera demo. When the playground demo improves,
/// this tutorial updates by copying the file again. The app opens on it
/// directly; with no screen below it, its back button stays hidden.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/media/camera_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const CameraDemo());
}
