// Not upstream's: a file from the Rive Marketplace, played as published.
//
// "Big Wheel Demo" by JcToon
// (https://rive.app/marketplace/9939-18941-big-wheel-demo/), licensed under
// CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). The file is
// bundled unmodified; assets/rive/marketplace/NOTICE.md and the plugin's
// THIRD_PARTY_NOTICES carry the attribution, and the screen shows it.
//
// In the creator's words: "By clicking on the character, you can change the
// head, body, or the size of the big wheel." A tap on the character fires
// the file's own triggers (Head, Body, Wheels), through its state machine's
// listeners, and plays its one sound: an audio event its artboard owns, so
// it stops when the view goes, as on the Audio screen. The artboard is
// 1080 x 1080 and shown whole.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../../theme.dart';

Widget buildBigWheel(BuildContext context) => const _BigWheel();

/// The credit CC BY 4.0 asks for: title, creator, source, licence, and
/// whether the file was changed.
const bigWheelCredit = '"Big Wheel Demo" by JcToon, '
    'rive.app/marketplace/9939-18941-big-wheel-demo, licensed under '
    'CC BY 4.0 (creativecommons.org/licenses/by/4.0). Unmodified.';

class _BigWheel extends StatelessWidget {
  const _BigWheel();

  // Kept clear of the home indicator, as the Audio screen is.
  @override
  Widget build(BuildContext context) => const SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Rive(
                asset: 'assets/rive/marketplace/big_wheel.riv',
                fit: RiveFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tap the character to change its head, body or wheel.\n'
                '$bigWheelCredit\n'
                'Turn the ringer on — iOS mutes it otherwise.',
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
