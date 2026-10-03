// Ported from rive-flutter's example/lib/examples/semantics.dart
// (0.15.0-dev.3). Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   File.asset(…) + RiveWidgetController(file)  →  RiveController() + Rive(asset:)
//   RiveWidget(semantics: auto)                 →  Rive(semantics: RiveSemantics.auto)
//   DropdownButton(isDense:)                    →  dropped: DartNative's has none
//   Force semantics / Debugger chips, S and D   →  the note Semantics [Omni] shows:
//   keys, SemanticsDebugger                         Flutter framework tools
//   Scaffold + AppBar                           →  the catalogue shell's
//   textTheme.bodySmall                         →  semanticsNoteStyle
//   readout right under its graphic             →  12pt between them
//
// Their loading spinner goes: each file loads on the platform side with its
// view. The properties are read before the views mount, as upstream reads
// them before the widgets exist, and bind when the views do.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../theme.dart';
import 'semantics_omni.dart'
    show harnessIndex, semanticsNote, semanticsNoteStyle;

Widget buildSemantics(BuildContext context) => const ExampleSemantics();

/// Demonstrates [Rive.semantics].
///
/// A dropdown selects one semantics example at a time; each graphic uses
/// [RiveSemantics.auto], so nothing tracks semantics until a screen reader
/// connects.
class ExampleSemantics extends StatefulWidget {
  const ExampleSemantics({super.key});

  @override
  State<ExampleSemantics> createState() => _ExampleSemanticsState();
}

/// One selectable semantics example: a display name, an optional
/// explanation shown under the picker, and the widgets to show.
class _ExampleEntry {
  final String name;
  final String? info;
  final List<Widget> Function() build;
  const _ExampleEntry({required this.name, this.info, required this.build});
}

class _ExampleSemanticsState extends State<ExampleSemantics> {
  final tabController = RiveController();
  final dropdownController = RiveController();
  final focusListController = RiveController();
  final zeroAreaController = RiveController();
  late final ViewModelInstanceEnum enumProperty;
  late final ViewModelInstanceString lastPressedProperty;
  String enumValue = '';
  String lastPressed = '';
  int selectedExample = harnessIndex;

  @override
  void initState() {
    super.initState();
    enumProperty = tabController.viewModelInstance.enumerator('enumProperty');
    enumValue = enumProperty.value;
    enumProperty.addListener(_onEnumChanged);

    lastPressedProperty =
        zeroAreaController.viewModelInstance.string('lastPressed');
    lastPressed = lastPressedProperty.value;
    lastPressedProperty.addListener(_onLastPressedChanged);
  }

  void _onEnumChanged(String value) {
    setState(() => enumValue = value);
  }

  void _onLastPressedChanged(String value) {
    setState(() => lastPressed = value);
  }

  @override
  void dispose() {
    enumProperty.removeListener(_onEnumChanged);
    lastPressedProperty.removeListener(_onLastPressedChanged);
    enumProperty.dispose();
    lastPressedProperty.dispose();
    tabController.dispose();
    dropdownController.dispose();
    focusListController.dispose();
    zeroAreaController.dispose();
    super.dispose();
  }

  List<_ExampleEntry> _entries() => [
        _ExampleEntry(
          name: 'Tabs',
          info: 'Three tabs writing enumProperty. Activate them with a tap '
              'or a screen reader action; the readout shows the bound value.',
          build: () => [
            SizedBox(
              height: 200,
              child: Rive(
                asset: 'assets/rive/tabtest.riv',
                controller: tabController,
                semantics: RiveSemantics.auto,
              ),
            ),
            const SizedBox(height: 12),
            Text('enumProperty: $enumValue', style: _text),
          ],
        ),
        _ExampleEntry(
          name: 'Expandable dropdown',
          info: 'A data-bound list behind an expandable button - expansion '
              'state and list items flow into the semantic tree.',
          build: () => [
            SizedBox(
              height: 400,
              child: Rive(
                asset: 'assets/rive/data_binding_lists.riv',
                controller: dropdownController,
                semantics: RiveSemantics.auto,
              ),
            ),
          ],
        ),
        _ExampleEntry(
          name: 'Focusable list',
          info: 'Cards wired into the focus system (Element 1..5). Move '
              'screen reader focus across them - the previous card must '
              'drop its focused state, and focus leaving the graphic must '
              'clear it.',
          build: () => [
            SizedBox(
              height: 500,
              child: Rive(
                asset: 'assets/rive/semantic_list_scroll_focus_fixed.riv',
                controller: focusListController,
                semantics: RiveSemantics.auto,
              ),
            ),
          ],
        ),
        _ExampleEntry(
          name: 'Zero-area cases',
          info: 'Empty groups, a card collapsing through zero width, a '
              'group scaling through zero, and a hidden subtree. Children '
              'of collapsed containers must stay reachable; hidden content '
              'must never appear. Taps write lastPressed.',
          build: () => [
            SizedBox(
              height: 800,
              child: Rive(
                asset: 'assets/rive/zero_area_semantics.riv',
                controller: zeroAreaController,
                semantics: RiveSemantics.auto,
              ),
            ),
            const SizedBox(height: 12),
            Text('lastPressed: $lastPressed', style: _text),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    final entry = entries[selectedExample];

    final graphics = ListView(
      padding: const EdgeInsets.all(16),
      children: entry.build(),
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
              DropdownButton<int>(
                value: selectedExample,
                items: [
                  for (var i = 0; i < entries.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(entries[i].name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedExample = value);
                  }
                },
              ),
            ],
          ),
        ),
        if (entry.info != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(entry.info!, style: semanticsNoteStyle),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(semanticsNote, style: semanticsNoteStyle),
        ),
        Expanded(child: graphics),
      ],
    );
  }
}

/// Upstream's Text on its Material theme: body text, 14 logical pixels.
const _text = TextStyle(
  color: Color(0xFFFFFFFF),
  fontSize: 14,
  fontFamily: monoFont,
);
