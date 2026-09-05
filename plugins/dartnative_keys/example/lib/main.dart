import 'package:dartnative/dartnative.dart';
import 'package:dartnative_keys/dartnative_keys.dart';

import 'dartnative_plugin_registrant.dart';

void main() async {
  // registerAll() wires the platform bindings AND calls KeysBindings.loadSymbols().
  DartNativePluginRegistrant.registerAll();
  // Parse the bundled `.dnkeys` once, before reading any key.
  await DnKeys.load();
  runApp(const KeysDemo());
}

class KeysDemo extends StatelessWidget {
  const KeysDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = DnKeys.all;
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'dartnative_keys',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            keys.isEmpty
                ? 'No keys loaded.'
                : 'Loaded ${keys.length} keys from the bundled .dnkeys:',
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (keys.isEmpty)
            const Text(
              'Copy .dnkeys.example to .dnkeys, add a value, and make sure '
              '`.dnkeys` is listed under flutter: assets:.',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, height: 1.4),
            ),
          ...keys.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      color: Color(0xFF32D74B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value.isEmpty ? '(empty)' : e.value,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
