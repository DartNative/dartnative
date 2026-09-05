import 'package:dartnative/dartnative.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const PathProviderExampleApp());
}

class PathProviderExampleApp extends StatelessWidget {
  const PathProviderExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const PathScreen();
}

/// Resolves the three app directories synchronously and shows them.
class PathScreen extends StatelessWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No await — these return a String path directly.
    final docs = getApplicationDocumentsDirectory();
    final support = getApplicationSupportDirectory();
    final tmp = getTemporaryDirectory();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _entry('Documents', docs),
              const SizedBox(height: 18),
              _entry('Support', support),
              const SizedBox(height: 18),
              _entry('Temporary', tmp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(String label, String path) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0A84FF),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        path,
        style: const TextStyle(color: Color(0xFFE5E5EA), fontSize: 13),
      ),
    ],
  );
}
