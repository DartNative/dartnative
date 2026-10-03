// Not upstream's: an illustration as one artboard.
//
// dragon_ball.riv is a traced picture — 32 colour layers, some sixty
// thousand vertices — with a little that moves: nine stones that bob and
// tilt, and a glow that swells over each energy ball. It shows a heavy,
// mostly still artboard at the size of the screen, and a file made without
// the Rive editor: tool/dragon_ball/build.sh writes it from the SVG. It is
// DartNative's own, not a Marketplace file; it sits in that section as the
// other large, file-only demo.
//
// The picture was generated with Craiyon
// (https://www.craiyon.com/fr/image/ngkUyMYoSyKO_gBOI_zQ6Q). The file leaves
// out Craiyon's logo in its bottom right corner; Craiyon's terms accept a
// credit in text beside the image instead, which this screen shows.
//
// The file embeds a sound, dragonball_sound_4s.mp3 beside it (the power-up
// of dragonball_sound.mp3 without its first four seconds), which plays each
// time the loop starts: an audio event its animation fires, played by the
// native runtime itself, as on the Audio screen.
//
// Rive(asset:) plays the file's default state machine, which loops its one
// animation. The file is large, so the spinner the painters' screens show
// is here too: the platform runtime loads the file with the view, the view
// mounts at once, and the spinner sits over it until the controller reports
// the file's artboards.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../../theme.dart';

Widget buildDragonBall(BuildContext context) => const _DragonBall();

/// Where the picture comes from, as Craiyon's terms ask, and the sound.
const dragonBallCredit = 'Traced from an image generated with Craiyon: '
    'craiyon.com/fr/image/ngkUyMYoSyKO_gBOI_zQ6Q\n'
    'Sound: "Anime Powerup (Dragonball becoming Super Saiyan)", '
    'Sound Library.';

class _DragonBall extends StatefulWidget {
  const _DragonBall();

  @override
  State<_DragonBall> createState() => _DragonBallState();
}

class _DragonBallState extends State<_DragonBall> {
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
                    asset: 'assets/rive/marketplace/dragon_ball.riv',
                    controller: controller,
                  ),
                  if (!isLoaded)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '$dragonBallCredit\n'
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
