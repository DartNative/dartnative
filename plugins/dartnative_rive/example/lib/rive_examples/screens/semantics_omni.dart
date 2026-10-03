// Ported from rive-flutter's example/lib/examples/semantics_omni.dart
// (0.15.0-dev.3). Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(…) + file.artboardNames   →  Rive(asset:) + controller.artboardNames
//   ArtboardSelector.byIndex(i)          →  Rive(artboardName: artboardNames[i])
//   RiveWidget(semantics: auto)          →  Rive(semantics: RiveSemantics.auto)
//   DropdownButton(isDense:)             →  dropped: DartNative's has none
//   Force semantics / Debugger chips,    →  a note: both are Flutter framework
//   S and D keys, SemanticsDebugger          tools, and here Rive's own view
//                                            hands its tree to VoiceOver or
//                                            TalkBack itself
//   Scaffold + AppBar                    →  the catalogue shell's
//
// The file loads with the view, so the names arrive once the default
// artboard shows; the picker then selects the first, as upstream's index 0.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';

Widget buildSemanticsOmni(BuildContext context) => const ExampleSemanticsOmni();

/// All-purpose semantics testing against a single file, `semantics.riv`.
///
/// This is the primary semantics test surface: one omni file holding many
/// artboards, each exercising a semantics case. Pick an artboard from the
/// dropdown to test it in isolation.
class ExampleSemanticsOmni extends StatefulWidget {
  const ExampleSemanticsOmni({super.key});

  @override
  State<ExampleSemanticsOmni> createState() => _ExampleSemanticsOmniState();
}

class _ExampleSemanticsOmniState extends State<ExampleSemanticsOmni> {
  final controller = RiveController();
  List<String> artboardNames = const [];
  int selectedArtboard = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onFileLoaded);
  }

  void _onFileLoaded() {
    if (controller.artboardNames.isEmpty || artboardNames.isNotEmpty) return;
    setState(() {
      artboardNames = controller.artboardNames;
      selectedArtboard = harnessIndex.clamp(0, artboardNames.length - 1);
    });
    dnLog('[DN-Harness] artboards ${artboardNames.length}: '
        '${artboardNames.join(' | ')}');
  }

  void _selectArtboard(int index) {
    if (index == selectedArtboard) return;
    setState(() => selectedArtboard = index);
  }

  @override
  void dispose() {
    controller.removeListener(_onFileLoaded);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final graphic = Rive(
      asset: 'assets/rive/semantics.riv',
      artboardName: artboardNames.isEmpty ? null : artboardNames[selectedArtboard],
      controller: controller,
      // The omni artboards are layout-based, so fill the available view.
      fit: RiveFit.layout,
      semantics: RiveSemantics.auto,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (artboardNames.isNotEmpty)
                DropdownButton<int>(
                  value: selectedArtboard,
                  items: [
                    for (var i = 0; i < artboardNames.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(artboardNames[i]),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _selectArtboard(value);
                  },
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(semanticsNote, style: semanticsNoteStyle),
        ),
        Expanded(child: graphic),
      ],
    );
  }
}

/// Only for the walk harness: the artboard (Semantics [Examples]: the
/// example) to open on, the index after `#` in the screen switch, e.g.
/// `Semantics [Omni]#3`. Zero, the upstream default, in a normal run.
int harnessIndex = 0;

/// What stands in for upstream's "Force semantics" and "Debugger" chips.
const semanticsNote = 'Turn on VoiceOver (iOS) or TalkBack (Android) to '
    "explore the artboard's semantics: Rive's view hands them to the screen "
    "reader itself. Upstream's Force semantics and Debugger chips are "
    'Flutter framework tools.';

/// Upstream's `textTheme.bodySmall` on its dark theme.
const semanticsNoteStyle = TextStyle(
  color: Color(0xB3FFFFFF),
  fontSize: 12,
  fontFamily: monoFont,
);
