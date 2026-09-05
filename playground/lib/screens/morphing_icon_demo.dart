/// Morphing-icon demo — exercises `CustomPaint` + `Path` interpolation.
///
/// A morphing icon that interpolates between two shapes — the native
/// CustomPaint pipeline drives shape-to-shape interpolation at 60 fps with
/// no `dartnative_skia` dependency.
///
/// Two morphs side by side, both lerping point-by-point between
/// same-topology source/target polygons:
///   1. **Square ⇄ Circle** — 64 perimeter points each.
///   2. **Play ▶ ⇄ Stop ■** — 32 points each. Both shapes are single
///      closed polygons; the triangle vertices fan out into the square
///      corners as t goes 0 → 1.
///
/// **Why not play ⇄ pause?** The pause icon is two *disjoint*
/// rectangles — topologically different from a triangle (one connected
/// shape). A naive point-by-point lerp between them produces a bowtie
/// artifact (diagonal connector lines through the middle as the polygon
/// "jumps" from the left rectangle to the right). Real play⇄pause
/// morphs in apps use two separate paths or a topology-aware tween.
/// Play ⇄ stop is the cleanest single-polygon analog.
///
/// Both morphs run from a single slider so they animate together.
library;

import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class MorphingIconDemo extends StatefulWidget {
  const MorphingIconDemo({super.key});

  @override
  State<MorphingIconDemo> createState() => _MorphingIconDemoState();
}

class _MorphingIconDemoState extends State<MorphingIconDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _slider = 0.0;
  bool _autoPlaying = false;

  // Note: no WidgetsBindingObserver needed. The framework's Ticker
  // auto-mutes (and cancels its underlying timer) on
  // AppLifecycleState.paused/inactive, so this demo gets background-pause
  // for free — like every other AnimationController user.

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        setState(() => _slider = _controller.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAutoplay() {
    if (_autoPlaying) {
      _controller.stop();
      setState(() => _autoPlaying = false);
    } else {
      setState(() => _autoPlaying = true);
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasWidth = MediaQuery.of(context).size.width - 32;
    // Two side-by-side painters in one Stage; each gets half the width.
    final halfWidth = canvasWidth / 2;
    final stageHeight = 220.0;

    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Morphing icon',
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
        child: ListView(
          children: [
            SizedBox(
                // Bar clearance is AUTOMATIC (extendBodyBehindAppBar +
                // null-padding scrollable -> Scaffold applies safeTop+toolbar);
                // keep only a small gap.
                height: isIOS26 ? 8 : 12),

            const _SectionTitle('Path interpolation via CustomPaint'),
            const _SectionBody(
              'Two shapes morph as you drag the slider, or hit Play to '
              'auto-loop. Both painters lerp between two same-length '
              'point sets — no Skia involved.',
            ),
            const SizedBox(height: 10),

            _Stage(
              height: stageHeight,
              child: Row(
                children: [
                  CustomPaint(
                    size: Size(halfWidth, stageHeight),
                    painter: _SquareToCirclePainter(t: _slider),
                  ),
                  CustomPaint(
                    size: Size(halfWidth, stageHeight),
                    painter: _PlayStopPainter(t: _slider),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Slider + autoplay toggle.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Fixed-width container so the "Morph: 0%" → "100%"
                      // string-length jump doesn't shift the Spacer (and
                      // with it, the Play/Stop button) sideways every
                      // time the leading digit count changes.
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Morph: ${(_slider * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleAutoplay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _autoPlaying
                                ? const Color(0xFFFF453A)
                                : const Color(0xFF0A84FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _autoPlaying ? 'Stop loop' : 'Play loop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _slider,
                    min: 0,
                    max: 1,
                    activeColor: const Color(0xFF0A84FF),
                    inactiveColor: kChipBg,
                    onChanged: _autoPlaying
                        ? null
                        : (v) => setState(() => _slider = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Both painters sample their source and target shapes to '
                'the same number of points (64 and 32 respectively), then '
                'linearly interpolate each point by t. The recorded display '
                'list is shipped as one mutation per tick; shouldRepaint '
                'only fires when t actually changes.',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────

/// Morph between a square and a circle. Both shapes are sampled at the
/// same `N` perimeter points, then each pair lerps by `t`.
class _SquareToCirclePainter extends CustomPainter {
  final double t;
  const _SquareToCirclePainter({required this.t});

  static const int _samples = 64;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - 24;
    final half = radius; // square half-side = circle radius for area parity

    // Build the morphed path point-by-point.
    final path = Path();
    for (var i = 0; i < _samples; i++) {
      final progress = i / _samples; // 0..1 around the perimeter
      final theta = progress * 2 * math.pi - math.pi / 2;
      // Circle sample at this angle.
      final cxp = cx + math.cos(theta) * radius;
      final cyp = cy + math.sin(theta) * radius;
      // Square sample at the same angle — project the ray onto the
      // square's perimeter.
      final sx = math.cos(theta);
      final sy = math.sin(theta);
      final scale = half / math.max(sx.abs(), sy.abs());
      final sxp = cx + sx * scale;
      final syp = cy + sy * scale;
      // Lerp circle → square as t goes 0 → 1.
      final x = cxp + (sxp - cxp) * t;
      final y = cyp + (syp - cyp) * t;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0A84FF);
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF64D2FF);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_SquareToCirclePainter oldDelegate) => oldDelegate.t != t;
}

/// Morph between a play-triangle ▶ and a stop-square ■. Both shapes are
/// single closed polygons sampled at the same number of points so each
/// vertex lerps cleanly with no topology artifacts.
///
/// The triangle's three corners "fan out" toward the four square corners
/// as t goes 0 → 1. By the way, this is also the cleanest illustration
/// of WHY linear point-by-point morphs work — the source and target
/// share a single connected boundary, so every intermediate frame is
/// also a clean simple polygon.
class _PlayStopPainter extends CustomPainter {
  final double t;
  const _PlayStopPainter({required this.t});

  static const int _samples = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 24;

    final play = _samplePlayTriangle(cx, cy, r);
    final stop = _sampleStopSquare(cx, cy, r);

    // Build the morphed path.
    final path = Path();
    for (var i = 0; i < _samples; i++) {
      final px = play[i * 2];
      final py = play[i * 2 + 1];
      final qx = stop[i * 2];
      final qy = stop[i * 2 + 1];
      final x = px + (qx - px) * t;
      final y = py + (qy - py) * t;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD60A);
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFF9F0A);
    canvas.drawPath(path, stroke);
  }

  /// Sample the play triangle into [_samples] points, walking three
  /// edges. Interleaved (x, y, x, y, …).
  static List<double> _samplePlayTriangle(double cx, double cy, double r) {
    // Triangle pointing right: vertices at top-left, mid-right, bottom-left
    // (walked CW so the orientation matches the square sample).
    final v0x = cx - r * 0.5;
    final v0y = cy - r * 0.87;
    final v1x = cx + r;
    final v1y = cy;
    final v2x = cx - r * 0.5;
    final v2y = cy + r * 0.87;
    // 11 + 11 + 10 = 32 — must equal _samples.
    final out = <double>[];
    void edge(double ax, double ay, double bx, double by, int n) {
      for (var i = 0; i < n; i++) {
        final f = i / n;
        out.add(ax + (bx - ax) * f);
        out.add(ay + (by - ay) * f);
      }
    }

    edge(v0x, v0y, v1x, v1y, 11);
    edge(v1x, v1y, v2x, v2y, 11);
    edge(v2x, v2y, v0x, v0y, 10);
    assert(out.length == _samples * 2);
    return out;
  }

  /// Sample the stop square into [_samples] points, walking four edges
  /// CW starting near the top. Aligned with the triangle's starting
  /// vertex so the morph looks like a natural fan-out.
  static List<double> _sampleStopSquare(double cx, double cy, double r) {
    // Square side ≈ same area as the triangle's bounding diamond so the
    // shape doesn't visually pop in size as it morphs.
    final half = r * 0.85;
    final tl = [cx - half, cy - half];
    final tr = [cx + half, cy - half];
    final br = [cx + half, cy + half];
    final bl = [cx - half, cy + half];
    // 8 samples per edge × 4 edges = 32 points.
    final out = <double>[];
    void edge(List<double> a, List<double> b, int n) {
      for (var i = 0; i < n; i++) {
        final f = i / n;
        out.add(a[0] + (b[0] - a[0]) * f);
        out.add(a[1] + (b[1] - a[1]) * f);
      }
    }

    edge(tl, tr, 8); // top
    edge(tr, br, 8); // right
    edge(br, bl, 8); // bottom
    edge(bl, tl, 8); // left
    assert(out.length == _samples * 2);
    return out;
  }

  @override
  bool shouldRepaint(_PlayStopPainter oldDelegate) => oldDelegate.t != t;
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

class _Stage extends StatelessWidget {
  final Widget child;
  final double height;
  const _Stage({required this.child, this.height = 220});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: kRowBg,
      ),
      child: child,
    );
  }
}
