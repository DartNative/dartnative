import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'dartnative_plugin_registrant.dart';
import 'lottie_assets_grid_demo.dart';
import 'lottie_controls_demo.dart';
import 'lottie_grid_demo.dart';

void main() {
  runZonedGuarded(
    () {
      DartNativeLogger.run(
        () {
          DartNativePluginRegistrant.registerAll();
          print('[Logger] Log file: ${DartNativeLogger.filePath}');
          runApp(const _App());
        },
        // Quiet by default. The plugin's per-cell/per-URL logs (and the
        // framework's) are gated on this flag — flip to `true` to debug.
        verbose: false,
        saveToFile: false,
      );
    },
    (error, stack) {
      print('[main] UNCAUGHT ERROR: $error\n$stack');
    },
  );
}

// ── App shell ─────────────────────────────────────────────────────────────────

class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White-by-design (the dn create template pattern): a clear glass AppBar
      // over a white Scaffold background, with the light trait so iOS 26
      // glass/keyboard stay light even in Dark Mode.
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'dartnative_lottie',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        // No backgroundColor → fully clear iOS 26 glass bar; the white
        // Scaffold.backgroundColor shows through it.
      ),
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Button(
                title: 'Controls Demo',
                variant: ButtonVariant.filled,
                onPressed: () => Navigator.push(
                  context,
                  PageRoute(builder: (_) => const LottieControlsDemo()),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Button(
                title: 'Sticker Grid Demo (URL)',
                variant: ButtonVariant.filled,
                onPressed: () => Navigator.push(
                  context,
                  PageRoute(builder: (_) => const LottieGridDemo()),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Button(
                title: 'Sticker Grid Demo (Assets)',
                variant: ButtonVariant.filled,
                onPressed: () => Navigator.push(
                  context,
                  PageRoute(builder: (_) => const LottieAssetsGridDemo()),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
