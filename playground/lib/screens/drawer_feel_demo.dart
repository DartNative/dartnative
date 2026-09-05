import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

/// Demonstrates the push-style drawer and its release behaviour.
///
/// This screen uses `push` (the default): panel and screen slide together as
/// one plane, as in Gmail. The other style, `slideOver` — the screen lifts
/// over a fixed panel as a shadowed card, as in X — is what the playground's
/// own drawer uses: try the hamburger on the home screen.
///
/// On release, each platform resolves the target its own way: iOS projects
/// where the panel was heading from the finger's velocity; Android applies
/// the Material 400 dp/s flick threshold. The panel then settles with an
/// eased animation whose duration scales with the remaining distance and
/// the release speed.
class DrawerFeelDemo extends StatefulWidget {
  const DrawerFeelDemo({super.key});

  @override
  State<DrawerFeelDemo> createState() => _DrawerFeelDemoState();
}

class _DrawerFeelDemoState extends State<DrawerFeelDemo> {
  final _key = GlobalKey<SliderMenuContainerState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.78;
    // House pattern (hero_demo, grid_demo, …): palette getters follow the
    // playground's theme switcher — no bespoke dark-mode detection here.
    final dark = playgroundPalette.brightness == Brightness.dark;
    // The panel surface follows the theme (white in light, near-black in
    // dark), with its text colour paired to it.
    final panel = dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final panelText = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    return SliderMenuContainer(
      sliderKey: _key,
      isDraggable: true,
      sliderMenuOpenSize: width,
      sliderMenu: Container(
        color: panel,
        child: Center(
          child: Text(
            'Drag me shut.\nThen flick me shut.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: panelText,
                fontSize: 17,
                decoration: TextDecoration.none),
          ),
        ),
      ),
      // The screen carries a hairline on its leading edge: in push style the
      // panel and screen form one flat plane, and in dark theme their two
      // surfaces are close enough that the seam needs a line to read at all.
      sliderMain: Stack(
        children: [
          Positioned.fill(child: _screen()),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 1,
            child: Container(
                color: dark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFD1D1D6)),
          ),
        ],
      ),
    );
  }

  Widget _screen() {
    return Scaffold(
        backgroundColor: kHomeBg,
        appBar: AppBar(title: const Text('Drawer feel')),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Platform.isIOS
                      ? 'iOS: the drawer settles to wherever your finger '
                          'was heading when you let go.'
                      : 'Android: a flick past 400 dp/s decides the '
                          'direction, otherwise the halfway point does.',
                  style: TextStyle(fontSize: 15, color: kTextPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  'This screen uses the push style. The slideOver style — '
                  'the screen lifting over the panel as a shadowed card — is '
                  'the playground\'s own drawer: try the hamburger on the '
                  'home screen.',
                  style: TextStyle(fontSize: 13, color: kTextSecondary),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Drag from anywhere to pull the drawer in.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          // ignore: prefer_const_constructors
                          'Watch what happens the moment you let go:\n\n'
                          '• flick it — it keeps your speed and carries on\n'
                          '• release half-way without moving — it glides to '
                          'the nearer side\n'
                          '• flick it back — the throw wins over the '
                          'halfway point',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.5, color: kTextPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _key.currentState?.toggle(),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Toggle (programmatic)',
                        style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            decoration: TextDecoration.none)),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
