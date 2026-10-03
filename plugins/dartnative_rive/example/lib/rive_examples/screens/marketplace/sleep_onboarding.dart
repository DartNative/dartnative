// Not upstream's: a file from the Rive Marketplace, played as published.
//
// "Sleep onboarding screen" by marciofpantoja
// (https://rive.app/marketplace/19960-38531-sleep-onboarding-screen/), UI
// design and illustration by Afsar Hossen (@imshuvo97), licensed under
// CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). The file is
// bundled unmodified; assets/rive/marketplace/NOTICE.md and the plugin's
// THIRD_PARTY_NOTICES carry the attribution, and the screen shows it.
//
// An onboarding screen the size of a phone's (1125 x 2435), on its default
// state machine, "Velocidade normal". Its own listeners make it play: a tap
// on the branch shakes it, a tap on either bird squashes it, and the button
// presses. Nothing here talks to the file.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../../theme.dart';

Widget buildSleepOnboarding(BuildContext context) => const _SleepOnboarding();

/// The credit CC BY 4.0 asks for: title, creator and whom the creator names,
/// source, licence, and whether the file was changed.
const sleepOnboardingCredit =
    '"Sleep onboarding screen" by marciofpantoja, UI design and illustration '
    'by Afsar Hossen (@imshuvo97), '
    'rive.app/marketplace/19960-38531-sleep-onboarding-screen, licensed '
    'under CC BY 4.0 (creativecommons.org/licenses/by/4.0). Unmodified.';

class _SleepOnboarding extends StatelessWidget {
  const _SleepOnboarding();

  // Kept clear of the home indicator, as the Audio screen is.
  @override
  Widget build(BuildContext context) => const SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Rive(
                asset: 'assets/rive/marketplace/sleep_onboarding.riv',
                fit: RiveFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tap the branch, the birds or the button.\n'
                '$sleepOnboardingCredit',
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
