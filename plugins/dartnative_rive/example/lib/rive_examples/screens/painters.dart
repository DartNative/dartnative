// Ported from rive-flutter's example/lib/examples/state_machine_painter.dart
// and example/lib/examples/animation_painter.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Upstream shows its painter classes as "an alternative controller to use
// instead of the RiveWidgetController", functionally the same as the widget
// for what the screen shows. We draw in the runtime's own view and have no
// per-frame painter to hand Dart, so each screen keeps upstream's content
// with the widget:
//
//   StateMachinePainter(withStateMachine: bind default instance)
//       → Rive(asset:)            default state machine, autoBind (default)
//   SingleAnimationPainter('idle')
//       → Rive(asset:, animationName: 'idle')
//
// Both show a CircularProgressIndicator until the file has loaded (theirs:
// `artboard == null`). Here the platform runtime loads the file with the
// view, so the view mounts at once and the spinner sits over it until the
// controller reports the file's artboards, as rive_widget.dart does.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

/// Upstream: `rewards.riv`, `file.defaultArtboard()`, the default state
/// machine, and `defaultArtboardViewModel(artboard).createDefaultInstance()`
/// bound to it — which is what `autoBind` does.
Widget buildStateMachinePainter(BuildContext context) =>
    const _PainterScreen(asset: 'assets/rive/rewards.riv');

/// Upstream: `off_road_car.riv`, `file.defaultArtboard()`, and
/// `SingleAnimationPainter('idle')`.
Widget buildSingleAnimationPainter(BuildContext context) =>
    const _PainterScreen(
      asset: 'assets/rive/off_road_car.riv',
      animationName: 'idle',
    );

class _PainterScreen extends StatefulWidget {
  const _PainterScreen({required this.asset, this.animationName});

  final String asset;
  final String? animationName;

  @override
  State<_PainterScreen> createState() => _PainterScreenState();
}

class _PainterScreenState extends State<_PainterScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Rive(
          asset: widget.asset,
          animationName: widget.animationName,
          controller: controller,
        ),
        if (!isLoaded) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
