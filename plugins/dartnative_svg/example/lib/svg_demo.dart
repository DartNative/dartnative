/// dartnative_svg demo screen — exercises each SvgPicture constructor.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_svg/dartnative_svg.dart';

const String _inlineTriangle = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#4CAF50">
  <polygon points="12 2 22 22 2 22"/>
</svg>
''';

// Wikipedia's "SVG logo" — a small, stable public SVG used as a smoke test
// for the network constructor. Replace with your own URL in real apps.
const String _networkUrl =
    'https://upload.wikimedia.org/wikipedia/commons/4/4f/SVG_Logo.svg';

class SvgDemo extends StatelessWidget {
  const SvgDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'SVG',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          // 1. Asset
          _DemoTile(
            label: 'SvgPicture.asset',
            child: SizedBox(
              width: 96,
              height: 96,
              child: SvgPicture.asset('assets/svg/heart.svg'),
            ),
          ),

          // 2. Inline XML string
          _DemoTile(
            label: 'SvgPicture.string',
            child: SizedBox(
              width: 96,
              height: 96,
              child: SvgPicture.string(_inlineTriangle),
            ),
          ),

          // 3. Different fit modes (asset).
          _DemoTile(
            label: 'SvgFit.cover · contain · fill',
            child: Row(
              children: [
                _Box(child: SvgPicture.asset(
                    'assets/svg/star.svg',
                    fit: SvgFit.cover)),
                SizedBox(width: 12),
                _Box(child: SvgPicture.asset(
                    'assets/svg/star.svg',
                    fit: SvgFit.contain)),
                SizedBox(width: 12),
                _Box(child: SvgPicture.asset(
                    'assets/svg/star.svg',
                    fit: SvgFit.fill)),
              ],
            ),
          ),

          // 4. colorTint — overrides every fill / stroke with one colour.
          //    The heart asset is pink (#E91E63); the tint forces lime so
          //    you can tell at a glance whether the srcIn filter is active.
          _DemoTile(
            label: 'colorTint: lime (srcIn) — heart asset is pink',
            child: SizedBox(
              width: 96,
              height: 96,
              child: SvgPicture.asset(
                'assets/svg/heart.svg',
                colorTint: Color(0xFF7CFC00),
              ),
            ),
          ),

          // 5. Network — downloads once and renders.
          _DemoTile(
            label: 'SvgPicture.network',
            child: SizedBox(
              width: 160,
              height: 160,
              child: SvgPicture.network(_networkUrl),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tiny presentation helpers (kept inline to keep the demo self-contained) ──

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A2530),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        color: const Color(0xFF263238),
        child: child,
      );
}
