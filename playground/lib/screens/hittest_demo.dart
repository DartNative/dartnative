// HitTestBehavior demo — opaque vs translucent, as in Flutter.
//
// Two offset areas: RED (left/top) counts taps; BLUE (right/bottom), in
// front, counts long presses and has no onTap. BLUE's colour sits under an
// IgnorePointer, so its detector's child draws nothing for the touch.
//
// opaque       → BLUE takes every touch in its box: a tap on the overlap
//                reaches nothing.
// translucent  → the touch also reaches what is behind BLUE: a tap on the
//                overlap counts on RED, a long press still counts on BLUE.

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class HitTestDemo extends StatefulWidget {
  const HitTestDemo({super.key});
  @override
  State<HitTestDemo> createState() => _HitTestDemoState();
}

class _HitTestDemoState extends State<HitTestDemo> {
  int _blueLongPressCount = 0;
  int _redTapCount = 0;
  bool _translucent = false;

  void _redOnTap() => setState(() => _redTapCount++);

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
                  _blueLongPressCount = 0;
                  _redTapCount = 0;
                }),
              ),
              const SizedBox(width: 10),
              _Chip(
                label: 'translucent',
                selected: _translucent,
                onTap: () => setState(() {
                  _translucent = true;
                  _blueLongPressCount = 0;
                  _redTapCount = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _translucent
                ? 'Tap the overlap → RED counts'
                : 'Tap the overlap → nothing counts',
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
                  count: _redTapCount,
                  label: 'RED taps',
                  color: const Color(0xFFEF5350)),
              const SizedBox(width: 24),
              _Counter(
                  count: _blueLongPressCount,
                  label: 'BLUE long presses',
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
                    onTap: _redOnTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: _OverlayLabel(text: 'RED', count: _redTapCount),
                    ),
                  ),
                ),
                // BLUE — right/bottom portion visible, overlaps RED in middle.
                // Its colour ignores the pointer: the detector's child draws
                // nothing for the touch, so its behaviour decides.
                Positioned(
                  left: 70,
                  top: 70,
                  width: 200,
                  height: 200,
                  child: GestureDetector(
                    behavior: _translucent
                        ? HitTestBehavior.translucent
                        : HitTestBehavior.opaque,
                    onLongPress: () => setState(() => _blueLongPressCount++),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xCC44AAFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white54, width: 3),
                        ),
                        child: _OverlayLabel(
                            text: 'BLUE', count: _blueLongPressCount),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap where BLUE covers RED, then long-press BLUE.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                decoration: TextDecoration.none),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'BLUE handles only long presses. Opaque keeps every touch in '
              'its box; translucent lets a tap it does not handle reach RED '
              'behind it, as in Flutter.',
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
