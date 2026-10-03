// Ported from rive-flutter's example/lib/examples/rive_audio.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream's point, in their words: "There is nothing special that needs to
// be done to get audio working at runtime." That holds for us too — the
// native runtimes play the file's embedded audio themselves.
//
//   FileLoader.fromAsset(…) + ArtboardSelector.byName('Lip_sync_2')
//     →  Rive(asset: …, artboardName: 'Lip_sync_2')
//
// See: https://rive.app/docs/editor/events/audio-events

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildRiveAudio(BuildContext context) => const _RiveAudio();

class _RiveAudio extends StatelessWidget {
  const _RiveAudio();

  // Kept clear of the home indicator; upstream's page runs under it.
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Expanded(
              child: Rive(
                asset: 'assets/rive/lip-sync.riv',
                artboardName: 'Lip_sync_2',
                fit: RiveFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Audio is embedded in the .riv and played by the native '
                'runtime. Turn the ringer on — iOS mutes it otherwise.',
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
