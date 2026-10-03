// Ported from rive-flutter's example/lib/examples/test_memory_cleanup.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Theirs, kept: a 110 ms timer that mounts and unmounts the Rive widget, so
// every toggle creates and disposes a file, a controller and a texture —
// watch memory while it runs. Ours keeps the timer and the toggle; the
// widget it toggles is Rive(asset:), whose element creates and disposes the
// platform view and the native file on each mount. This is the screen for
// the Android per-view File leak tracked as H4 in FEATURES_WIP.md.

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

Widget buildTestMemoryCleanup(BuildContext context) =>
    const _TestMemoryCleanup();

class _TestMemoryCleanup extends StatefulWidget {
  const _TestMemoryCleanup();

  @override
  State<_TestMemoryCleanup> createState() => _TestMemoryCleanupState();
}

class _TestMemoryCleanupState extends State<_TestMemoryCleanup> {
  Timer? _visibilityTimer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _visibilityTimer = Timer.periodic(
      const Duration(milliseconds: 110),
      (_) => setState(() => _isVisible = !_isVisible),
    );
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: _isVisible
            ? const Rive(
                asset: 'assets/rive/rating.riv',
                stateMachineName: 'State Machine 1',
              )
            : const SizedBox.shrink(),
      );
}
