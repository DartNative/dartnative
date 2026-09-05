// HitTestBehavior demo — validates opaque vs translucent.
//
// Two offset containers: RED (left/top) and BLUE (right/bottom).
// The overlapping area tests gesture absorption vs forwarding.
//
// opaque       → BLUE absorbs taps on its area. RED only gets taps on its
//                non-overlapping region.
// translucent  → BLUE fires its own callback AND natively forwards the tap
//                to overlapping siblings drawn beneath it (RED) whose bounds
//                contain the touch point. Tap on the overlapping area
//                increments BOTH counters — no `passThrough` Dart API needed.

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class HitTestDemo extends StatefulWidget {
  const HitTestDemo({super.key});
  @override
  State<HitTestDemo> createState() => _HitTestDemoState();
}

class _HitTestDemoState extends State<HitTestDemo> {
  int _topTapCount = 0;
  int _bottomTapCount = 0;
  bool _translucent = false;

  void _bottomOnTap() => setState(() => _bottomTapCount++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'HitTestBehavior Demo',
          style: TextStyle(
              color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBarBg,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // ── Behavior chips (two options) ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(
                label: 'opaque',
                selected: !_translucent,
                onTap: () => setState(() {
                  _translucent = false;
                  _topTapCount = 0;
                  _bottomTapCount = 0;
                }),
              ),
              const SizedBox(width: 10),
              _Chip(
                label: 'translucent',
                selected: _translucent,
                onTap: () => setState(() {
                  _translucent = true;
                  _topTapCount = 0;
                  _bottomTapCount = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _translucent
                ? 'Tap BLUE → BLUE + RED both increment'
                : 'Tap BLUE → only BLUE increments',
            style: TextStyle(
              color: _translucent
                  ? const Color(0xFF34C759)
                  : const Color(0xFF888888),
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          // ── Counters ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Counter(
                  count: _bottomTapCount,
                  label: 'RED',
                  color: const Color(0xFFEF5350)),
              const SizedBox(width: 24),
              _Counter(
                  count: _topTapCount,
                  label: 'BLUE',
                  color: const Color(0xFF44AAFF)),
            ],
          ),
          const SizedBox(height: 24),
          // ── Offset containers ────────────────────────────────────────────
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              children: [
                // RED — left/top portion visible
                Positioned(
                  left: 10,
                  top: 10,
                  width: 200,
                  height: 200,
                  child: GestureDetector(
                    onTap: _bottomOnTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: _OverlayLabel(text: 'RED', count: _bottomTapCount),
                    ),
                  ),
                ),
                // BLUE — right/bottom portion visible, overlaps RED in middle
                Positioned(
                  left: 70,
                  top: 70,
                  width: 200,
                  height: 200,
                  child: GestureDetector(
                    behavior: _translucent
                        ? HitTestBehavior.translucent
                        : HitTestBehavior.opaque,
                    onTap: () => setState(() => _topTapCount++),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF44AAFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white54, width: 3),
                      ),
                      child: _OverlayLabel(text: 'BLUE', count: _topTapCount),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the BLUE area.  Red (left/top corner) is always tappable.',
            style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                decoration: TextDecoration.none),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'HitTestBehavior.translucent on the top view fires its own '
              'callback AND forwards the tap to overlapping siblings drawn '
              'beneath it whose bounds contain the touch point.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Label overlay for each container ──────────────────────────────────────────

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.text, required this.count});
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
                color: kTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none),
          ),
          Text(
            '$count',
            style: TextStyle(
                color: kTextPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF44AAFF) : kChipBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : kTextSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

// ── Counter chip ──────────────────────────────────────────────────────────────

class _Counter extends StatelessWidget {
  const _Counter(
      {required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none)),
          Text(label,
              style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  decoration: TextDecoration.none)),
        ],
      ),
    );
  }
}
