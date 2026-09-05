/// Demo for [DeviceOrientationListener] — the standalone API that reports
/// the *physical* 4-way device orientation, distinct from MediaQuery.
///
/// Confirms end-to-end that:
///   - iOS UIDevice.orientationDidChangeNotification reaches Dart.
///   - Android OrientationEventListener (accelerometer-driven) reaches
///     Dart, with native-side de-bouncing.
///   - The 4-way enum distinguishes landscapeLeft from landscapeRight,
///     and portraitUp from portraitDown — things MediaQuery's binary
///     Orientation.portrait/landscape can't see.
///   - The native listener stops when the last Dart listener detaches.
///
/// For the rationale (why this exists alongside MediaQuery, what makes
/// it the right tool for camera-plugin preview rotation), see the
/// library doc on `DeviceOrientationListener`.
library;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class DeviceOrientationDemo extends StatefulWidget {
  const DeviceOrientationDemo({super.key});

  @override
  State<DeviceOrientationDemo> createState() => _DeviceOrientationDemoState();
}

class _DeviceOrientationDemoState extends State<DeviceOrientationDemo> {
  DeviceOrientation _current = DeviceOrientation.portraitUp;
  int _changeCount = 0;

  @override
  void initState() {
    super.initState();
    // Subscribing here starts the native listener (lazy).
    DeviceOrientationListener.currentNotifier.addListener(_onOrientation);
    // Seed with the current value in case the listener has already
    // received the first event.
    _current = DeviceOrientationListener.current;
  }

  @override
  void dispose() {
    DeviceOrientationListener.currentNotifier.removeListener(_onOrientation);
    super.dispose();
  }

  void _onOrientation() {
    if (!mounted) return;
    setState(() {
      _current = DeviceOrientationListener.current;
      _changeCount++;
    });
  }

  String _orientationLabel(DeviceOrientation o) {
    switch (o) {
      case DeviceOrientation.portraitUp:
        return 'portraitUp';
      case DeviceOrientation.portraitDown:
        return 'portraitDown';
      case DeviceOrientation.landscapeLeft:
        return 'landscapeLeft';
      case DeviceOrientation.landscapeRight:
        return 'landscapeRight';
    }
  }

  /// Single arrow character that visually points in the orientation's
  /// direction. Kept as a separate field (large + above the label) so
  /// the visual indicator reads at a glance and the text below labels it.
  String _orientationArrow(DeviceOrientation o) {
    switch (o) {
      case DeviceOrientation.portraitUp:
        return '⬆';
      case DeviceOrientation.portraitDown:
        return '⬇';
      case DeviceOrientation.landscapeLeft:
        return '⬅';
      case DeviceOrientation.landscapeRight:
        return '➡';
    }
  }

  Color _accent(DeviceOrientation o) {
    switch (o) {
      case DeviceOrientation.portraitUp:
        return const Color(0xFF30D158);
      case DeviceOrientation.portraitDown:
        return const Color(0xFFFF453A);
      case DeviceOrientation.landscapeLeft:
        return const Color(0xFF0A84FF);
      case DeviceOrientation.landscapeRight:
        return const Color(0xFFFFD60A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(_current);
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Device orientation',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        // ListView (not Column) so the demo scrolls cleanly in landscape —
        // the MediaQuery card needs to stay reachable on small heights.
        child: ListView(
          children: [
            SizedBox(
                // Bar clearance is AUTOMATIC (extendBodyBehindAppBar +
                // null-padding scrollable -> Scaffold applies safeTop+toolbar);
                // keep only a small gap.
                height: isIOS26 ? 8 : 16),
            const _SectionTitle('DeviceOrientationListener'),
            const _SectionBody(
              'Rotate the device. The reading below comes from the platform '
              'orientation observer (UIDevice on iOS, OrientationEventListener '
              'on Android) via DeviceOrientationListener. Works even when the '
              'app is locked to portrait — try the SystemChrome lock button '
              'and rotate. Distinguishes landscapeLeft from landscapeRight '
              'and portraitUp from portraitDown.',
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent, width: 2),
              ),
              child: Column(
                children: [
                  // Big visual arrow — reads at a glance.
                  Text(
                    _orientationArrow(_current),
                    style: TextStyle(
                      color: accent,
                      fontSize: 64,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Text label directly under the arrow — labels what the
                  // arrow means.
                  Text(
                    _orientationLabel(_current),
                    style: TextStyle(
                      color: accent,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Index: ${_current.index} · changes since open: $_changeCount',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'The native observer is lazy: starts when the first Dart '
                'listener subscribes, stops when the last unsubscribes. '
                'Apps that never read orientation pay zero sensor power.',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Layout chrome ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        text,
        style: TextStyle(
          color: kTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: TextStyle(
          color: kTextSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
