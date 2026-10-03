// Ported from rive-flutter's example/lib/examples/multi_touch.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream is a bare RiveWidgetBuilder over multitouch.riv — no controls, the
// artboard's own listeners do everything. Ours is the same file with no
// controls, so this is a direct comparison of touch delivery.
//
// This one is worth watching closely: their widget receives pointers through
// the Flutter gesture arena, ours through the platform view's own touch
// handling. Two fingers at once on the two rectangles is the test.
//
// Upstream has no caption; ours says what the file's listeners do, as nothing
// in it moves: the top rectangle is green while pressed (pointer down sets
// isHovered, pointer up clears it), and a tap flips the nested artboard's
// rectangle below it.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildMultiTouch(BuildContext context) => const _MultiTouch();

class _MultiTouch extends StatelessWidget {
  const _MultiTouch();

  // Kept clear of the home indicator; upstream's page runs under it.
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Expanded(
              child: Rive(
                asset: 'assets/rive/multitouch.riv',
                stateMachineName: 'State Machine 1',
                fit: RiveFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hold the top rectangle with one finger and tap the bottom one '
                'with another: both react at once. The top one is green while '
                'pressed; each tap flips the bottom one.',
                style: TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontSize: 12,
                  fontFamily: monoFont,
                ),
              ),
            ),
          ],
        ),
      );
}
