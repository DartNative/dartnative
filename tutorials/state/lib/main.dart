/// DartNative tutorial — state, from setState up.
///
/// The two screens under lib/screens/ are BYTE-IDENTICAL copies of the
/// DartNative playground's state demos (lib/screens/home/demo_ui.dart is the
/// playground's shared UI kit, also verbatim). When the playground demos
/// improve, this tutorial updates by copying the files again:
///   • state_basics_demo.dart — Signal<T> + Computed<T> watched from plain
///     StatelessWidgets, effect() for side-effects, and Listenable.watch
///     to bridge an existing ChangeNotifier
///   • state_store_demo.dart — the Store pattern (a plain Dart class of
///     signal fields + actions) and Provided<T> per-subtree DI: two task
///     lists, each reading its own TaskStore from the context
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/home/demo_ui.dart';
import 'screens/state_basics_demo.dart';
import 'screens/state_store_demo.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  // Light look (white background), matching the site's light styling.
  playgroundPalette = kLightPalette;
  runApp(const StateHome());
}

/// Two-row launcher built from the playground's own UI kit.
class StateHome extends StatelessWidget {
  const StateHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'State',
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
            icon: CupertinoIcons.bolt_fill,
            tint: kAccentPurple,
            title: 'Basics',
            tagline: 'Signal, Computed, effect, watch — no setState',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const StateBasicsDemo()),
            ),
          ),
          const SizedBox(height: 12),
          DemoRow(
            icon: CupertinoIcons.tray_full_fill,
            tint: kAccentRed,
            title: 'Store + Provided',
            tagline: 'TaskStore + per-subtree DI with Provided',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const StateStoreDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
