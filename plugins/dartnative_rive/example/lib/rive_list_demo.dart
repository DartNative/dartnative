import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import 'rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'rive_examples/theme.dart';

/// The Grid's artboards as the rows of a recycling [FastList]: one artboard
/// per row, a fixed row height, the same keep-alive band — the list half of
/// the fast family under the same load as the grid.
class RiveListDemo extends StatefulWidget {
  const RiveListDemo({super.key});

  @override
  State<RiveListDemo> createState() => _RiveListDemoState();
}

class _RiveListDemoState extends State<RiveListDemo> {
  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
  }

  // The Grid's four samples, repeated so the list is long enough to recycle.
  static const _assets = [
    'assets/rive/Bear.riv',
    'assets/rive/rating_animation.riv',
    'assets/rive/light_switch.riv',
    'assets/rive/leg_day_events_example.riv',
  ];
  static const _rowCount = 40;
  static const _rowHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'List',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [PerfAction(color: Color(0xFF000000))],
      ),
      body: PerfOverlayHost(
        child: FastList(
          itemCount: _rowCount,
          itemExtent: _rowHeight + 12,
          padding: const EdgeInsets.all(12),
          // Hold a band of rows either side of the viewport so scrolling back
          // finds them already loaded.
          keepAliveCount: 8,
          itemBuilder: (context, index) {
            final asset = _assets[index % _assets.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: _rowHeight,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
