// A port of rive-flutter's `example/lib/pacing_overlay.dart` chip.
//
// Theirs measures the Rive renderer's own pacing through rive_native's
// deferred-pacing diagnostics — a Flutter-texture concept we have no
// equivalent for. What carries over is the part a developer reads: a speed
// icon at the top right that toggles a frame-rate readout.
//
// Theirs floats above the whole navigator through `MaterialApp(builder:)`.
// Ours is a bar button on every screen (PerfAction): DartNative's bars are
// native, so the bar places it like any of its buttons — a Liquid Glass
// capsule on iOS 26, the bar's own inset and centre line elsewhere. A chip
// in `App(builder:)`'s layer cannot see the bar, and could only guess where
// it is. The readout is drawn in the screen's body (PerfOverlayHost), just
// under the bar.
//
// Ours counts DartNative UI frames. The artboard is advanced by the platform
// runtime on its own display link, so this reports the host app's frames,
// not Rive's — stated on the panel rather than left to look like a number
// it is not.

import 'dart:async';

import 'package:dartnative/dartnative.dart';

import 'theme.dart';

/// Whether the readout shows. One value for the whole app: each screen is
/// a root of its own, and no inherited state crosses from one to another.
final _perfVisible = ValueNotifier<bool>(false);

/// The speed icon as a bar button: put it in an AppBar's actions.
class PerfAction extends StatelessWidget {
  const PerfAction({super.key, this.color = const Color(0xFFFFFFFF)});

  /// The icon's colour while the readout is off: the bar's foreground.
  final Color color;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: _perfVisible,
        builder: (context, visible, _) => IconButton(
          icon: Icon(
            Icons.speed,
            color: visible ? const Color(0xFF7FD4A0) : color,
          ),
          onPressed: () => _perfVisible.value = !visible,
        ),
      );
}

/// Wraps a screen's body; shows the host app's UI frame rate at its top
/// right while PerfAction has it on. The body keeps the size it has without
/// the host (StackFit.expand): a loose Stack would let a scroll view shrink
/// to its content, and in DartNative collapse it.
class PerfOverlayHost extends StatefulWidget {
  const PerfOverlayHost({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<PerfOverlayHost> createState() => _PerfOverlayHostState();
}

class _PerfOverlayHostState extends State<PerfOverlayHost> {
  Timer? _timer;
  int _frames = 0;
  int _fps = 0;
  DateTime _lastSample = DateTime.now();

  bool get _visible => _perfVisible.value;

  void _onVisible() {
    setState(() {});
    if (_visible) {
      _start();
    } else {
      _stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _perfVisible.addListener(_onVisible);
    if (_visible) _start();
  }

  // Frames are counted from the frame timings, Flutter's own per-frame
  // report. A post-frame callback that re-registers itself is no frame
  // counter here: DartNative runs post-frame callbacks as microtasks, so
  // one would re-run forever without yielding and freeze the app.
  void _start() {
    _lastSample = DateTime.now();
    _frames = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), _sample);
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) => _frames += timings.length;

  void _sample(Timer _) {
    final now = DateTime.now();
    final micros = now.difference(_lastSample).inMicroseconds;
    _lastSample = now;
    if (micros <= 0 || !mounted) return;
    setState(() {
      _fps = (_frames / (micros / 1e6)).round();
      _frames = 0;
    });
  }

  @override
  void dispose() {
    _perfVisible.removeListener(_onVisible);
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible)
          Positioned(
            right: 16,
            top: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xB0000000),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ui: $_fps fps\n'
                  'renderer: Rive native\n'
                  'the artboard runs on the platform\n'
                  "display link, not Flutter's — this\n"
                  'counts host UI frames only',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF7FD4A0),
                    fontSize: 11,
                    fontFamily: monoFont,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
