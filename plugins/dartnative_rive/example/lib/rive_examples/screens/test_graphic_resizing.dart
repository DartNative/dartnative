// Ported from rive-flutter's example/lib/examples/test_graphic_resizing.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Theirs, kept: an AnimationController tweening the widget's box between
// the full screen and half of it, 2 s each way, forever — to see whether the
// graphic flickers as its texture is recreated. Ours swaps only the load:
// RiveWidgetBuilder over rating.riv becomes Rive(asset:). On the native
// side a resize is a frame change on the platform view, so what this tests
// here is the plugin's layout path under continuous resizing.

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildTestGraphicResizing(BuildContext context) =>
    const _TestGraphicResizing();

class _TestGraphicResizing extends StatefulWidget {
  const _TestGraphicResizing();

  @override
  State<_TestGraphicResizing> createState() => _TestGraphicResizingState();
}

class _TestGraphicResizingState extends State<_TestGraphicResizing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _sizeAnimation,
      builder: (context, child) => SizedBox(
        width: screenSize.width * _sizeAnimation.value,
        height: screenSize.height * _sizeAnimation.value,
        child: const Rive(
          asset: 'assets/rive/rating.riv',
          stateMachineName: 'State Machine 1',
        ),
      ),
    );
  }
}
