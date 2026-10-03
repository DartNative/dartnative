// Not upstream's: a file from the Rive Marketplace, played as published.
//
// "StudioRun - A Cosmic Game by TheLittleLabs" by thelittlelabs
// (https://rive.app/marketplace/26133-49002-studiorun-a-cosmic-game-by-thelittlelabs/),
// licensed under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/).
// The file is bundled unmodified; assets/rive/marketplace/NOTICE.md and the
// plugin's THIRD_PARTY_NOTICES carry the attribution, and the screen shows
// it.
//
// A whole game in one file: menus, a runner, coins, music and sound effects,
// all the file's own state machines and nested artboards, played by taps.
// Its sounds are audio events its artboards own, so they stop when the view
// goes, as on the Audio screen. The artboard is 1920 x 1080 and shown whole.
//
// The file is large (13 MB, most of it audio), so the spinner the Dragon
// Ball screen shows is here too, until the controller reports the file's
// artboards.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../../theme.dart';

Widget buildStudioRun(BuildContext context) => const _StudioRun();

/// The credit CC BY 4.0 asks for: title, creator, source, licence, and
/// whether the file was changed.
const studioRunCredit =
    '"StudioRun - A Cosmic Game by TheLittleLabs" by thelittlelabs, '
    'rive.app/marketplace/26133-49002-studiorun-a-cosmic-game-by-thelittlelabs, '
    'licensed under CC BY 4.0 (creativecommons.org/licenses/by/4.0). '
    'Unmodified.';

class _StudioRun extends StatefulWidget {
  const _StudioRun();

  @override
  State<_StudioRun> createState() => _StudioRunState();
}

class _StudioRunState extends State<_StudioRun> {
  final controller = RiveController();

  bool get isLoaded => controller.artboardNames.isNotEmpty;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onController);
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onController);
    controller.dispose();
    super.dispose();
  }

  // Kept clear of the home indicator, as the Audio screen is.
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Rive(
                    asset: 'assets/rive/marketplace/studiorun.riv',
                    controller: controller,
                    fit: RiveFit.contain,
                  ),
                  if (!isLoaded)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '$studioRunCredit\n'
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
