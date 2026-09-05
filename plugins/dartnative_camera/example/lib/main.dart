import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/camera_demo.dart';

Future<void> main() async {
  final license = DartNativeLicense.instance;

  // Register plugins before runApp() so the license check knows which
  // plugins the app uses.
  DartNativePluginRegistrant.registerAll();

  // On-device builds pass the license key at run time:
  //   dn run -d <device> --dart-define=DN_LICENSE_KEY=<key> \
  //     --dart-define=DN_APP_ID=<bundle-id>
  // With no key passed (desktop) this is skipped.
  const licenseKey = String.fromEnvironment('DN_LICENSE_KEY');
  if (licenseKey.isNotEmpty) {
    try {
      await license.launchCheck(
        licenseKey,
        appId: const String.fromEnvironment(
          'DN_APP_ID',
          defaultValue: 'dev.dartnative.example.camera',
        ),
      );
    } catch (e) {
      // Don't hang on the splash if the license server is unreachable — log the
      // real cause; runApp()'s validate() renders the license-error screen below.
      print('[example] launchCheck failed (continuing to validate): $e');
    }
  }

  // runApp() validates the framework + each linked plugin's entitlement and
  // renders the native license-error screen on failure — so no explicit
  // validate() here (that would throw before runApp and bypass the screen).
  runApp(App(home: const CameraDemo()));
}
