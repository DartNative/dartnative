import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  // dartnative_splash is a build-time tool — no runtime plugins to load. The
  // splash itself is drawn natively by the OS before this entrypoint runs;
  // registerAll() just wires the platform bindings.
  DartNativePluginRegistrant.registerAll();
  runApp(const SplashExampleApp());
}

class SplashExampleApp extends StatelessWidget {
  const SplashExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const WelcomeScreen();
}

/// Bare welcome screen shown the moment the native splash disappears.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/dn-logo.png', width: 96, height: 96),
            const SizedBox(height: 24),
            const Text(
              'Welcome',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The native splash you just saw was generated\nby dartnative_splash.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
