import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import 'rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'rive_examples/theme.dart';

/// A port of rive-ios's own Layout demo
/// (`Example-iOS/Source/Examples/Storyboard/Layout.swift`), which cycles every
/// fit and alignment on one artboard.
///
/// This is the sharpest rendering comparison available: run it beside the
/// native demo with the same `truck.riv` and the two should be
/// indistinguishable, because the same C++ renderer draws both.
///
/// It is also the one screen that would catch a wrong `RiveFit` mapping. The
/// three enums disagree on ordering — iOS puts `fitHeight` before `fitWidth`
/// and `scaleDown` before `noFit` — so the bridges map by NAME. A mistake
/// there is invisible in code review and obvious here: pick `fitWidth` and the
/// truck should fill the width, not the height.
class RiveLayoutDemo extends StatefulWidget {
  const RiveLayoutDemo({super.key});

  @override
  State<RiveLayoutDemo> createState() => _RiveLayoutDemoState();
}

class _RiveLayoutDemoState extends State<RiveLayoutDemo> {
  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
  }

  RiveFit _fit = RiveFit.contain;
  RiveAlignment _alignment = RiveAlignment.center;

  /// What each fit should do, so the screen can be judged without the native
  /// app side by side.
  static const _fitExpect = <RiveFit, String>{
    RiveFit.fill: 'stretches to the box, ignoring aspect ratio',
    RiveFit.contain: 'fits inside the box, whole truck visible',
    RiveFit.cover: 'fills the box, truck cropped',
    RiveFit.fitWidth: 'spans the full WIDTH, may crop top and bottom',
    RiveFit.fitHeight: 'spans the full HEIGHT, may crop the sides',
    RiveFit.none: 'drawn at its authored size, no scaling',
    RiveFit.scaleDown: 'like contain, but never scales up',
    RiveFit.layout: 'artboard resizes itself to the box',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Layout',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [PerfAction(color: Color(0xFF000000))],
      ),
      body: PerfOverlayHost(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A visible frame, so the fit's effect on the box is obvious.
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  border: Border.all(color: const Color(0xFFD0D0D4)),
                ),
                child: Rive(
                  asset: 'assets/rive/truck.riv',
                  fit: _fit,
                  alignment: _alignment,
                  // truck.riv has no state machine: only the classic runtime
                  // plays its animation.
                  legacy: true,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The grey box is the widget bounds — watch how the truck sits '
                'in it.',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 20),

              const _Title('fit'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in RiveFit.values)
                    _Chip(
                      label: f.name,
                      selected: f == _fit,
                      onTap: () => setState(() => _fit = f),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '→ ${_fitExpect[_fit]}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 20),

              const _Title('alignment'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in RiveAlignment.values)
                    _Chip(
                      label: a.name,
                      selected: a == _alignment,
                      onTap: () => setState(() => _alignment = a),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '→ the truck moves to that corner or edge. Most visible with a '
                'fit that leaves space, such as contain or none.',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF111111) : const Color(0xFFEFEFF0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? const Color(0xFFFFFFFF) : const Color(0xFF333333),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
