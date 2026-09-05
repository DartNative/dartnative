/// DartNative tutorial — a camera screen.
///
/// lib/screens/media/camera_demo.dart is a BYTE-IDENTICAL copy of the
/// DartNative playground's camera demo (lib/screens/home/demo_ui.dart is the
/// playground's shared UI kit, also verbatim). When the playground demo
/// improves, this tutorial updates by copying the files again.
///
/// The launcher below PUSHES the camera screen — in the playground it is
/// pushed from the Media hub, and its custom chrome draws its own back
/// chevron, which needs a route underneath to pop back to.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/media/camera_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const CameraHome());
}

/// One-row launcher built from the playground's own UI kit.
class CameraHome extends StatelessWidget {
  const CameraHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Camera',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DemoRow(
            icon: CupertinoIcons.camera_fill,
            tint: kAccentBlue,
            title: 'Camera',
            tagline: 'Photo + video capture, flash, flip, crop',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const CameraDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
