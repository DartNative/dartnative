// Ported from rive-flutter's example/lib/examples/rive_widget.dart and
// rive_widget_builder.dart. Copyright (c) 2020 Rive, MIT; see
// THIRD_PARTY_NOTICES.
//
// Upstream:
//   file = await File.asset('assets/rewards.riv', riveFactory: …)
//   controller = RiveWidgetController(file)   // binds the default view
//                                             // model instance, no values set
//   RiveWidget(controller:, fit: Fit.layout, layoutScaleFactor: 1 / 3)
//
// Ours: the same file, RiveFit.layout, layoutScaleFactor 1 / 3. Their
// controller binds the file's default view-model instance and sets no
// value; `Rive.autoBind` (on by default) does the same through rive-ios's
// enableAutoBind / rive-android's autoBind, so both show the artboard's
// default bound state.
//
// The Builder variant differs upstream only in switching over
// RiveLoading / RiveFailed / RiveLoaded while the file loads; both show a
// CircularProgressIndicator until it has (theirs: `isInitialized`). Here
// the platform runtime loads the file with the view, so the view mounts at
// once and the spinner sits over it until the controller reports the
// file's artboards. Both screens are this one widget.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildRiveWidget(BuildContext context) => const _RiveWidgetScreen();

Widget buildRiveWidgetBuilder(BuildContext context) =>
    const _RiveWidgetScreen();

class _RiveWidgetScreen extends StatefulWidget {
  const _RiveWidgetScreen();

  @override
  State<_RiveWidgetScreen> createState() => _RiveWidgetScreenState();
}

class _RiveWidgetScreenState extends State<_RiveWidgetScreen> {
  final controller = RiveController();

  bool get isInitialized => controller.artboardNames.isNotEmpty;

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
          asset: 'assets/rive/rewards.riv',
          controller: controller,
          fit: RiveFit.layout,
          layoutScaleFactor: 1 / 3,
        ),
        if (!isInitialized) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
