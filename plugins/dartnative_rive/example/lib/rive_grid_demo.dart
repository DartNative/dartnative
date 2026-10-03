import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import 'rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'rive_examples/theme.dart';

/// A grid of Rive artboards in a [FastGrid].
///
/// Each cell mounts its own native Rive view. `keepAliveCount` holds a band of
/// cells around the viewport so scrolling back does not pay the file load
/// again — the same argument the Lottie grid makes, and the reason a recycling
/// grid is the right control here rather than a scrolling Column.
class RiveGridDemo extends StatefulWidget {
  const RiveGridDemo({super.key});

  @override
  State<RiveGridDemo> createState() => _RiveGridDemoState();
}

class _RiveGridDemoState extends State<RiveGridDemo> {
  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
  }

  // The four samples, repeated so the grid is long enough to recycle.
  static const _assets = [
    'assets/rive/Bear.riv',
    'assets/rive/rating_animation.riv',
    'assets/rive/light_switch.riv',
    'assets/rive/leg_day_events_example.riv',
  ];

  static const _cellCount = 40;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Grid',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [PerfAction(color: Color(0xFF000000))],
      ),
      body: PerfOverlayHost(
        child: FastGrid(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.all(12),
          childAspectRatio: 1,
          // Hold a band of cells either side of the viewport so scrolling back
          // finds them already loaded.
          keepAliveCount: 8,
          itemCount: _cellCount,
          itemBuilder: (context, index) {
            final asset = _assets[index % _assets.length];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Rive(
                asset: asset,
                fit: RiveFit.contain,
                alignment: RiveAlignment.center,
                // Bear.riv has no state machine: only the classic runtime
                // plays its animation.
                legacy: asset == 'assets/rive/Bear.riv',
              ),
            );
          },
        ),
      ),
    );
  }
}
