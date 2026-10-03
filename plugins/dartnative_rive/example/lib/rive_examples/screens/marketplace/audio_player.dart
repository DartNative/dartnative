// Not upstream's: a file from the Rive Marketplace, played as published.
//
// "Audio Player" by RiottersDesign
// (https://rive.app/marketplace/28160-53178-audio-player/), licensed under
// CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). The file is
// bundled unmodified; assets/rive/marketplace/NOTICE.md and the plugin's
// THIRD_PARTY_NOTICES carry the attribution, and the screen shows it.
//
// Its two scripts drive it: one plays the file's three embedded tracks and
// moves the playhead by the real playback time, the other turns the volume
// knob. They read and write the file's view model, so the view needs it
// bound, which Rive(asset:) does by default (autoBind). The buttons, the knob
// and the track changes are all the file's own.
//
// The one thing the screen does is stop the music when it goes. A script
// plays its sounds on Rive's audio engine with no artboard to own them
// (rive-runtime's lua_audio.cpp passes none, up to its current main), and
// the runtime stops an artboard's own sounds only when the artboard goes:
// tearing the view down would leave the track playing to its end, and
// neither RiveRuntime nor rive-android can stop one file's sounds from
// outside. So on dispose the screen presses the player's own Stop, as the
// file's Stop button does: 3 into the view model's `command` (Play writes 1,
// Pause 2). The script stops the sound as the value changes, and the write
// goes out before the view's teardown: a State is disposed before its
// children are unmounted, and both travel in the same ordered mutations.
//
// The artboard is 1400 x 900, with the player in its middle 916 units across
// and light backdrop on either side. Shown whole, the player would fill two
// thirds of a phone's width; so the view gets a box of the artboard's height
// and the player's width plus a little, and RiveFit.cover crops the backdrop
// at its sides. Cropping only ever takes backdrop, so nothing of the player
// is lost on any screen: the box is as large as the space allows.
//
// The file is large, so the spinner the Dragon Ball screen shows is here
// too, until the controller reports the file's artboards.

import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../../theme.dart';

Widget buildAudioPlayer(BuildContext context) => const _AudioPlayer();

/// The part of the artboard the view shows, width over height: the player's
/// 916 units across and 24 more each side, by the artboard's 900.
const _shown = (916 + 2 * 24) / 900;

/// What the file's Stop button writes into its view model's `command`.
const _stop = 3.0;

/// The credit CC BY 4.0 asks for — title, creator, source, licence, and
/// whether the file was changed — and the music the file embeds, by name.
const audioPlayerCredit =
    '"Audio Player" by RiottersDesign, rive.app/marketplace/'
    '28160-53178-audio-player, licensed under CC BY 4.0 '
    '(creativecommons.org/licenses/by/4.0). Unmodified.\n'
    'Music in the file: "Slide" by Simon Osterhold, "Happy like You" by Loya, '
    '"Big Shot" by Vic Sage and ZISO.';

class _AudioPlayer extends StatefulWidget {
  const _AudioPlayer();

  @override
  State<_AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<_AudioPlayer> {
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
    controller.viewModelInstance.number('command').value = _stop;
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(
                      constraints.maxWidth, constraints.maxHeight * _shown);
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: width / _shown,
                      child: Stack(
                        children: [
                          Rive(
                            asset: 'assets/rive/marketplace/audio_player.riv',
                            controller: controller,
                            fit: RiveFit.cover,
                          ),
                          if (!isLoaded)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '$audioPlayerCredit\n'
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
