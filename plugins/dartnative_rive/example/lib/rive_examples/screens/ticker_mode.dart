// Ported from rive-flutter's example/lib/examples/ticker_mode.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream wraps the widget in Flutter's `TickerMode(enabled:)`: disabled,
// the widget's ticker stops and the animation freezes. A native view has no
// Flutter ticker, so the same effect is the runtime's own transport —
//
//   TickerMode(enabled: false)  →  controller.pause()
//   TickerMode(enabled: true)   →  controller.play()
//
// The file, the label text and the toggle are theirs. Note their initial
// state: `tickerMode = false`, so the artboard starts frozen.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildTickerMode(BuildContext context) => const _TickerMode();

class _TickerMode extends StatefulWidget {
  const _TickerMode();

  @override
  State<_TickerMode> createState() => _TickerModeState();
}

class _TickerModeState extends State<_TickerMode> {
  final _controller = RiveController();
  var tickerMode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Kept clear of the home indicator; upstream's page runs under it.
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Rive(
                asset: 'assets/rive/little_machine.riv',
                stateMachineName: 'State Machine 1',
                autoplay: false, // their TickerMode starts disabled
                controller: _controller,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                tickerMode ? 'Ticker mode enabled' : 'Ticker mode disabled',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 14,
                  fontFamily: monoFont,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  setState(() => tickerMode = !tickerMode);
                  if (tickerMode) {
                    _controller.play();
                  } else {
                    _controller.pause();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Toggle ticker mode',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                      fontFamily: monoFont,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
