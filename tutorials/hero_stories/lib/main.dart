/// DartNative tutorial — a story viewer with Hero.
///
/// lib/screens/hero_demo.dart is a BYTE-IDENTICAL copy of the DartNative
/// playground's Hero demo (lib/screens/home/demo_ui.dart is the playground's
/// shared UI kit, also verbatim). When the playground demo improves, this
/// tutorial updates by copying the files again.
///
/// The launcher below PUSHES the demo screen — in the playground it is pushed
/// from the hub, and its top bar draws its own back button, which needs a
/// route underneath to pop back to.
import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'screens/hero_demo.dart';
import 'screens/home/demo_ui.dart';

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const HeroHome());
}

/// One-row launcher built from the playground's own UI kit.
class HeroHome extends StatelessWidget {
  const HeroHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Hero stories',
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
            icon: CupertinoIcons.person_crop_circle_fill,
            tint: kAccentPink,
            title: 'Story viewer',
            tagline: 'Hero morph, RouteTransition.none, drag-to-close',
            onTap: (ctx) => Navigator.push(
              ctx,
              PageRoute(builder: (_) => const HeroDemo()),
            ),
          ),
        ],
      ),
    );
  }
}
