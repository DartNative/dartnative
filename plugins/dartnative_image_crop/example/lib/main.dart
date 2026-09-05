import 'dart:async';

import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
// Two example screens are bundled — flip between them by changing the
// `runApp(...)` argument below.
//   • ImageCropBasic: compact "Open / Crop" basic demo.
//   • ImageCropFull:  full editor (Cancel/Done + rotate/flip/aspect/rotate
//                      toolbar) — port of a production image-crop screen.
// ignore: unused_import — kept so you can swap the runApp() arg below.
import 'screens/image_crop_basic.dart';
// ignore: unused_import
import 'screens/image_crop_full.dart';

void main() {
  runZonedGuarded(
    () {
      DartNativeLogger.run(
        () {
          DartNativePluginRegistrant.registerAll();
          // Swap the runApp argument to switch between the two examples:
          runApp(const ImageCropBasic()); // compact basic demo
          //   runApp(const ImageCropFull());    // full editor port
        },
        // Flips dnVerboseLog = true so framework-internal diagnostic prints
        verbose: true,
        saveToFile: false,
      );
    },
    (error, stack) {
      // ignore: avoid_print
      print('[ZONE-ERR] type=${error.runtimeType} msg="$error"\n$stack');
    },
  );
}
