// Ported from rive-flutter's example/lib/examples/hit_test_behaviour.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Theirs: a red 300x300 box that counts taps, with the Rive button drawn
// over it; four buttons switch `RiveWidget.hitTestBehavior`, and more
// switch the mouse cursor. Ours keeps the box, the counter, the file and
// the four behaviours — `Rive.hitTestBehavior` takes the same values. The
// cursor half has no meaning on a phone and is left out, said on screen.
//
// This is the screen that shows what hitTestBehavior does with a NATIVE
// view underneath: the platform view takes the touch first, so `opaque`
// and `translucent` differ from Flutter's in the way the README describes.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildHitTestBehaviour(BuildContext context) => const _HitTest();

class _HitTest extends StatefulWidget {
  const _HitTest();

  @override
  State<_HitTest> createState() => _HitTestState();
}

class _HitTestState extends State<_HitTest> {
  int count = 0;
  RiveHitTestBehavior hitTestBehavior = RiveHitTestBehavior.opaque;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => count++),
                    child: Container(
                      width: 300,
                      height: 300,
                      color: const Color(0xFFF44336),
                    ),
                  ),
                ),
                Center(
                  // Unsized, as upstream's RiveWidget: it fills the Stack,
                  // so `opaque` covers the whole area, not just the box.
                  child: Rive(
                    // A changed behaviour is applied through reconfigure.
                    key: ValueKey(hitTestBehavior),
                    asset: 'assets/rive/button.riv',
                    hitTestBehavior: hitTestBehavior,
                  ),
                ),
              ],
            ),
          ),
          _line('Underlying container tapped: $count'),
          _line('Current hit test behaviour: $hitTestBehavior'),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in RiveHitTestBehavior.values)
                  _Button(b.name, () => setState(() => hitTestBehavior = b)),
              ],
            ),
          ),
          _line('Mouse cursor: no cursor on a phone — not ported.'),
          // Upstream's last child is an Expanded holding the cursor buttons;
          // keeping the Expanded keeps the box above at the same height.
          const Expanded(child: SizedBox.shrink()),
        ],
      );

  static Widget _line(String text) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 13,
            fontFamily: monoFont,
          ),
        ),
      );
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 14,
              fontFamily: monoFont,
            ),
          ),
        ),
      );
}
