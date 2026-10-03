// Ported from rive-flutter's example/lib/examples/pause_play.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream toggles `controller.active`, which stops advancing the state
// machine. Ours maps onto the runtime's own transport:
//
//   controller.active = true   →  controller.play()
//   controller.active = false  →  controller.pause()
//
// Their file is rewards.riv at Fit.layout with layoutScaleFactor 1/3; same
// here.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildPausePlay(BuildContext context) => const _PausePlay();

class _PausePlay extends StatefulWidget {
  const _PausePlay();

  @override
  State<_PausePlay> createState() => _PausePlayState();
}

class _PausePlayState extends State<_PausePlay> {
  final _controller = RiveController();

  // Upstream starts paused (`isPlaying = false`, applied in onLoaded).
  bool _isPlaying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  // Kept clear of the home indicator; upstream's page runs under it.
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Rive(
                asset: 'assets/rive/rewards.riv',
                fit: RiveFit.layout,
                layoutScaleFactor: 1 / 3,
                // Upstream applies `active = isPlaying` on load, so the
                // artboard is still until the button is pressed.
                autoplay: false,
                controller: _controller,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              // Upstream's ElevatedButton.icon, in the example's own style.
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPlaying ? 'Pause' : 'Play',
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 15,
                          fontFamily: monoFont,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
