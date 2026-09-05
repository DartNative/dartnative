import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/gallery_demo.dart';
import 'screens/media_picker_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Named so a hot restart can replay the stack: a pushed route without a
  // registered name is dropped.
  registerRoutes({'/gallery': (_) => const GalleryDemo()});
  runApp(const MediaPickerDemo());
}
