/// Implicit-animations demo — exercises the single-value AnimatedX widgets:
///   - AnimatedAlign
///   - AnimatedPadding
///   - AnimatedRotation
///   - AnimatedScale
///   - AnimatedSlide
///
/// Same shared duration / curve controls as `animated_size_demo.dart`.
library;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

const _durations = [
  (label: '100 ms', ms: 100),
  (label: '300 ms', ms: 300),
  (label: '600 ms', ms: 600),
  (label: '1.2 s', ms: 1200),
];

const _curves = [
  (label: 'linear', curve: Curves.linear),
  (label: 'easeIn', curve: Curves.easeIn),
  (label: 'easeOut', curve: Curves.easeOut),
  (label: 'easeInOut', curve: Curves.easeInOut),
  (label: 'bounceOut', curve: Curves.bounceOut),
];

class ImplicitAnimationsDemo extends StatefulWidget {
  const ImplicitAnimationsDemo({super.key});

  @override
  State<ImplicitAnimationsDemo> createState() => _ImplicitAnimationsDemoState();
}

class _ImplicitAnimationsDemoState extends State<ImplicitAnimationsDemo> {
  int _durationMs = 300;
  Curve _curve = Curves.easeInOut;

  // Per-section state.
  int _alignIndex = 0;
  bool _padExpanded = false;
  double _rotateTurns = 0.0;
  double _scaleValue = 1.0;
  bool _slideRight = false;
  bool _posTopLeft = true;
  CrossFadeState _crossFade = CrossFadeState.showFirst;

  Duration get _duration => Duration(milliseconds: _durationMs);

  static const _alignments = <AlignmentGeometry>[
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerRight,
    Alignment.bottomRight,
    Alignment.bottomCenter,
    Alignment.bottomLeft,
    Alignment.centerLeft,
    Alignment.center,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Implicit Animations',
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
                height: isIOS26 ? 8 : 20),

            // ── Shared controls ─────────────────────────────────────────────
            _SectionHeader('Duration'),
            const SizedBox(height: 8),
            _ChipRow(
              options: _durations.map((d) => d.label).toList(),
              selected: _durations.indexWhere((d) => d.ms == _durationMs),
              onTap: (i) => setState(() => _durationMs = _durations[i].ms),
            ),
            const SizedBox(height: 16),
            _SectionHeader('Curve'),
            const SizedBox(height: 8),
            _ChipRow(
              options: _curves.map((c) => c.label).toList(),
              selected: _curves.indexWhere((c) => c.curve == _curve),
              onTap: (i) => setState(() => _curve = _curves[i].curve),
            ),

            const SizedBox(height: 28),

            // ── 1. AnimatedAlign ────────────────────────────────────────────
            _SectionHeader('1. AnimatedAlign'),
            const SizedBox(height: 6),
            const _Caption(
              'Tap the "Next alignment" button to cycle through 9 '
              'alignments. The dot tweens smoothly between any two '
              'positions.',
            ),
            const SizedBox(height: 10),
            _Card(
              height: 200,
              child: AnimatedAlign(
                alignment: _alignments[_alignIndex],
                duration: _duration,
                curve: _curve,
                child: _Dot(color: const Color(0xFF0A84FF)),
              ),
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: 'Next alignment '
                  '(${_alignmentName(_alignments[_alignIndex])})',
              onTap: () => setState(
                () => _alignIndex = (_alignIndex + 1) % _alignments.length,
              ),
            ),

            const SizedBox(height: 36),

            // ── 2. AnimatedPadding ──────────────────────────────────────────
            _SectionHeader('2. AnimatedPadding'),
            const SizedBox(height: 6),
            const _Caption(
              'Tap to toggle the padding value. More padding squeezes '
              'the green box smaller; less padding lets it grow. Only '
              'the wrapping insets animate — the box itself is the '
              'same widget.',
            ),
            const SizedBox(height: 10),
            _Card(
              child: AnimatedPadding(
                padding: EdgeInsets.all(_padExpanded ? 40 : 8),
                duration: _duration,
                curve: _curve,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: _padExpanded ? 'Decrease padding' : 'Increase padding',
              onTap: () => setState(() => _padExpanded = !_padExpanded),
            ),

            const SizedBox(height: 36),

            // ── 3. AnimatedRotation ─────────────────────────────────────────
            _SectionHeader('3. AnimatedRotation'),
            const SizedBox(height: 6),
            const _Caption(
              'Tap to add ¼ turn. Values are in turns (1.0 = 360°). '
              'The widget multiplies by 2π internally.',
            ),
            const SizedBox(height: 10),
            _Card(
              height: 200,
              child: Center(
                child: AnimatedRotation(
                  turns: _rotateTurns,
                  duration: _duration,
                  curve: _curve,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF453A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '🧭',
                        style: TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: '+¼ turn (current: ${_rotateTurns.toStringAsFixed(2)})',
              onTap: () => setState(() => _rotateTurns += 0.25),
            ),

            const SizedBox(height: 36),

            // ── 4. AnimatedScale ────────────────────────────────────────────
            _SectionHeader('4. AnimatedScale'),
            const SizedBox(height: 6),
            const _Caption(
              'Tap to cycle through 0.5×, 1×, 1.5×, 2×. '
              'Scaling is uniform around the centre.',
            ),
            const SizedBox(height: 10),
            _Card(
              height: 220,
              child: Center(
                child: AnimatedScale(
                  scale: _scaleValue,
                  duration: _duration,
                  curve: _curve,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF9F0A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: 'Next scale '
                  '(current: ${_scaleValue.toStringAsFixed(1)}×)',
              onTap: () => setState(() {
                final next = {
                  0.5: 1.0,
                  1.0: 1.5,
                  1.5: 2.0,
                  2.0: 0.5,
                }[_scaleValue];
                _scaleValue = next ?? 1.0;
              }),
            ),

            const SizedBox(height: 36),

            // ── 5. AnimatedSlide ────────────────────────────────────────────
            _SectionHeader('5. AnimatedSlide'),
            const SizedBox(height: 6),
            const _Caption(
              'Tap to slide left ↔ right. Offset is in logical pixels '
              '(differs from Flutter\'s fraction-of-size AnimatedSlide).',
            ),
            const SizedBox(height: 10),
            _Card(
              height: 160,
              child: Center(
                child: AnimatedSlide(
                  offset:
                      _slideRight ? const Offset(80, 0) : const Offset(-80, 0),
                  duration: _duration,
                  curve: _curve,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF5AF2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '➡️',
                        style: TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: _slideRight ? 'Slide left' : 'Slide right',
              onTap: () => setState(() => _slideRight = !_slideRight),
            ),

            const SizedBox(height: 36),

            // ── 6. AnimatedPositioned ───────────────────────────────────────
            _SectionHeader('6. AnimatedPositioned'),
            const SizedBox(height: 6),
            const _Caption(
              'Tween the box between two positions inside a Stack. '
              'left/top/right/bottom/width/height all interpolate '
              'independently; the enclosing Stack re-emits position '
              'insets on every tick.',
            ),
            const SizedBox(height: 10),
            _Card(
              height: 220,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use a consistent axis convention on both ends — always
                  // `left` + `top` with explicit `width`/`height`. Mixing
                  // (left,top) on one end with (right,bottom) on the other
                  // makes the per-edge tween hold the box at the source
                  // anchor until t=1 and then snap (Flutter has the same
                  // limitation — its docs recommend `AnimatedPositioned
                  // .fromRect` for cases that switch anchors). With known
                  // bounds we just compute the destination top-left and
                  // every edge tweens smoothly.
                  const stackHeight = 220.0;
                  const inset = 16.0;
                  // Same width/height on both ends → constant shape
                  // during the move. Only left/top change, so the box
                  // slides diagonally without resizing.
                  const boxW = 80.0;
                  const boxH = 80.0;
                  final endLeft = constraints.maxWidth - boxW - inset;
                  final endTop = stackHeight - boxH - inset;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        left: _posTopLeft ? inset : endLeft,
                        top: _posTopLeft ? inset : endTop,
                        width: boxW,
                        height: boxH,
                        duration: _duration,
                        curve: _curve,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF64D2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '📦',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: _posTopLeft ? 'Send to bottom-right' : 'Send to top-left',
              onTap: () => setState(() => _posTopLeft = !_posTopLeft),
            ),

            const SizedBox(height: 36),

            // ── 7. AnimatedCrossFade ────────────────────────────────────────
            _SectionHeader('7. AnimatedCrossFade'),
            const SizedBox(height: 6),
            const _Caption(
              'Cross-fade between two children. During the transition '
              'both are stacked with reciprocal opacities; outside it, '
              'only the active child is mounted.',
            ),
            const SizedBox(height: 10),
            _Card(
              height: 180,
              child: Center(
                child: AnimatedCrossFade(
                  crossFadeState: _crossFade,
                  duration: _duration,
                  curve: _curve,
                  firstChild: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32D74B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'First',
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  secondChild: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF453A),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'Second',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: _crossFade == CrossFadeState.showFirst
                  ? 'Show second (circle)'
                  : 'Show first (square)',
              onTap: () => setState(
                () => _crossFade = _crossFade == CrossFadeState.showFirst
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ),

            const SizedBox(height: 36),

            // ── Stress: change all 7 at once ────────────────────────────────
            _SectionHeader('Bonus — fire all seven at once'),
            const SizedBox(height: 6),
            const _Caption(
              'Single tap should retarget every demo above to a new state '
              'simultaneously. Mid-flight interrupts should resume smoothly '
              'rather than snap.',
            ),
            const SizedBox(height: 10),
            _ToggleButton(
              label: 'Randomise all',
              onTap: () => setState(() {
                _alignIndex = (_alignIndex + 3) % _alignments.length;
                _padExpanded = !_padExpanded;
                _rotateTurns += 0.5;
                _scaleValue = _scaleValue == 1.0 ? 1.5 : 1.0;
                _slideRight = !_slideRight;
                _posTopLeft = !_posTopLeft;
                _crossFade = _crossFade == CrossFadeState.showFirst
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst;
              }),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  String _alignmentName(AlignmentGeometry a) {
    if (a == Alignment.topLeft) return 'topLeft';
    if (a == Alignment.topCenter) return 'topCenter';
    if (a == Alignment.topRight) return 'topRight';
    if (a == Alignment.centerRight) return 'centerRight';
    if (a == Alignment.bottomRight) return 'bottomRight';
    if (a == Alignment.bottomCenter) return 'bottomCenter';
    if (a == Alignment.bottomLeft) return 'bottomLeft';
    if (a == Alignment.centerLeft) return 'centerLeft';
    if (a == Alignment.center) return 'center';
    return 'custom';
  }
}

// ── Local helpers ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: TextStyle(
          color: kTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: TextStyle(color: kTextSecondary, fontSize: 12),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final double? height;
  const _Card({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kRowBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ToggleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final int selected;
  final void Function(int) onTap;
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == selected ? const Color(0xFF007AFF) : kTileBg,
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    color: i == selected
                        ? const Color(0xFFFFFFFF)
                        : kTextSecondary,
                    fontSize: 13,
                    fontWeight:
                        i == selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
