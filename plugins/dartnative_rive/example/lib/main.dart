import 'dart:io' show File, Platform;

import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'rive_controls_demo.dart';
import 'rive_grid_demo.dart';
import 'rive_hit_test_demo.dart';
import 'rive_layout_demo.dart';
import 'rive_flutter_examples_demo.dart';
import 'rive_examples/app.dart';
import 'rive_official/events.dart';
import 'rive_official/inputs.dart';
import 'rive_sources_demo.dart';

void main() {
  // Verbose on: this example exists to exercise the plugin, and the bridge's
  // own diagnostics (`[DNRive] …` — the resolved artboard and state machine,
  // the input roster, and a warning for any input name the file does not
  // define) are gated on this flag. Set it to false for a quiet run.
  DartNativeLogger.run(
    () {
      // Platform bindings + every plugin's FFI symbols. Keep this as the FIRST
      // line of main() — see lib/dartnative_plugin_registrant.dart.
      DartNativePluginRegistrant.registerAll();

      // Named routes, so a hot restart replays the navigation stack.
      registerRoutes({
        '/controls': (_) => const RiveControlsDemo(),
        '/grid': (_) => const RiveGridDemo(),
        '/hit-test': (_) => const RiveHitTestDemo(),
        '/flutter-examples': (_) => const RiveFlutterExamplesDemo(),
        '/layout': (_) => const RiveLayoutDemo(),
        '/sources': (_) => const RiveSourcesDemo(),
        '/official-inputs': (_) => const ExampleInputs(),
        '/official-events': (_) => const ExampleEvents(),
        '/rive-examples': (_) => const RiveExamplesApp(),
      });

      // The example's screens are dark in either theme: light status-bar
      // icons. The white demos switch to dark ones (whiteScreenStatusBar).
      SystemChrome.defaultStyle = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      );
      // Upstream's app opens on its examples menu; so does ours.
      //
      // `--dart-define=DN_SCREEN="Responsive Layouts"` opens one screen
      // directly instead — the simulator cannot be tapped from a script, so
      // that is how each screen is launched to be screenshotted. The same
      // name in the process environment does it for an installed build
      // (`SIMCTL_CHILD_DN_SCREEN=… xcrun simctl launch …`), so every screen
      // can be walked without rebuilding. Both unset in a normal run.
      // `push:<name>` opens the menu instead and pushes that screen from it
      // twice, the way a tap does, so a first and a second open show up side
      // by side in the jank logs.
      const compiled = String.fromEnvironment('DN_SCREEN');
      final screen = compiled.isNotEmpty ? compiled : _runtimeScreen();
      runApp(
        App(
          title: 'Rive Example',
          // Upstream's darkTheme with themeMode: ThemeMode.dark. DN's App
          // takes the app's brightness from `theme` only, so the dark theme
          // goes there: native views, Android's Material picker among them,
          // are built dark, as in upstream's app. Its font, bar colour and
          // primary colour are set by the screens (rive_examples/theme.dart).
          theme: ThemeData.dark(),
          home: screen.isEmpty
              ? const RiveExamplesApp()
              : screen.startsWith('push:')
                  ? RiveExamplesApp(autoPush: screen.substring(5))
                  : RiveExampleScreen(screen),
        ),
      );
    },
    verbose: true,
    saveToFile: false,
  );
}

/// The screen named outside the build: `DN_SCREEN` in the process
/// environment, or the one line of a switch file — `/tmp/dn_screen.txt`, a
/// host file the simulator's sandbox lets the app read, or on Android the
/// same name in the app's own files dir, which `adb shell run-as` can write
/// for a debug build. The screenshot walk writes it before each launch.
/// None of these exist in a normal run.
String _runtimeScreen() {
  final env = Platform.environment['DN_SCREEN'];
  if (env != null && env.isNotEmpty) return env;
  for (final path in const [
    '/tmp/dn_screen.txt',
    '/data/data/com.dartnative.dartnative_rive_example/files/dn_screen.txt',
  ]) {
    try {
      final f = File(path);
      if (f.existsSync()) return f.readAsStringSync().trim();
    } catch (_) {}
  }
  return '';
}
