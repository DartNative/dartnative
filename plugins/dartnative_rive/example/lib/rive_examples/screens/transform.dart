// Ported from rive-flutter's example/lib/examples/transform.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Theirs shows the same artboard twice, side by side — once through the
// Rive renderer and once through Flutter's — each under a `Transform` that
// scales with a drag and rotates continuously, with the view model's
// `rendererName` string set to which renderer drew it. We have one
// renderer, so one panel, and the string says so: "Rive native".
//
// The transform is DartNative's `Transform`, applied to the platform view.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildTransform(BuildContext context) => const ExampleTransform();

class ExampleTransform extends StatefulWidget {
  const ExampleTransform({super.key});

  @override
  State<ExampleTransform> createState() => _ExampleTransformState();
}

class _ExampleTransformState extends State<ExampleTransform>
    with SingleTickerProviderStateMixin {
  final controller = RiveController();
  late final AnimationController _rotation;
  double scale = 1.5;

  @override
  void initState() {
    super.initState();
    // Drives a continuous Z rotation on top of the user-controlled scale, as
    // upstream does.
    _rotation = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    controller.viewModelInstance.string('rendererName').value = 'Rive native';
  }

  @override
  void dispose() {
    _rotation.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onVerticalDragUpdate: (d) => setState(
          () => scale = (scale + d.delta.dy * 0.008).clamp(0.1, 5.0),
        ),
        child: AnimatedBuilder(
          animation: _rotation,
          builder: (context, child) => Transform.rotate(
            angle: _rotation.value * 2 * 3.141592653589793,
            child: Transform.scale(scale: scale, child: child),
          ),
          child: Rive(
            asset: 'assets/rive/rive_rendering_test.riv',
            artboardName: 'Rive Rendering',
            fit: RiveFit.contain,
            controller: controller,
          ),
        ),
      );
}
