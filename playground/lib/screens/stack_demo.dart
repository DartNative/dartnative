/// Stack + Positioned demo — validates all StackNativeElement layout paths.
///
/// Section A (Flutter official examples):
///   A1 — basic non-Positioned overlap (topStart anchor)
///   A2 — Positioned corner placement
///   A3 — Positioned.fill overlay
///
/// Section B (alignment variants):
///   B1 — alignment switcher with three nested coloured boxes
///   B2 — Alignment.center with non-Positioned children
///
/// Section C (StackFit):
///   C1 — StackFit.expand forces children to fill
///
/// Section D (complex patterns from Gee app):
///   D1 — Positioned.fill column + Positioned bottom overlay (full‑screen host)
///   D2 — Expanded > Stack > Offstage switcher
///   D3 — Stack(alignment: center) with Transform-layered cards (carousel)
///   D4 — Stack(fit: expand) inside SizedBox (inner card)
library;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

// ── Alignment presets ─────────────────────────────────────────────────────────

const _alignments = [
  (label: 'topStart', value: Alignment.topLeft),
  (label: 'topCenter', value: Alignment.topCenter),
  (label: 'topEnd', value: Alignment.topRight),
  (label: 'centerLeft', value: Alignment.centerLeft),
  (label: 'center', value: Alignment.center),
  (label: 'centerRight', value: Alignment.centerRight),
  (label: 'bottomLeft', value: Alignment.bottomLeft),
  (label: 'bottomCenter', value: Alignment.bottomCenter),
  (label: 'bottomRight', value: Alignment.bottomRight),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class StackDemo extends StatefulWidget {
  const StackDemo({super.key});

  @override
  State<StackDemo> createState() => _StackDemoState();
}

class _StackDemoState extends State<StackDemo> {
  // B1 alignment switcher
  int _alignIdx = 4; // Alignment.center

  // D2 Offstage tab switcher
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Stack Demo',
          style: TextStyle(
              color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.bold),
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
                height: isIOS26 ? 8 : 24),

            // ── A1: basic non-Positioned overlap ───────────────────────────
            _SectionHeader('A1 — Non-Positioned overlap (topStart)'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'Three boxes at default topStart. Blue (80) on top, Red (100) on bottom.'),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: Stack(
                  children: [
                    Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFFEF5350)),
                    Container(
                        width: 90, height: 90, color: const Color(0xFF4CAF50)),
                    Container(
                        width: 80, height: 80, color: const Color(0xFF2196F3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── A2: Positioned corner placement ────────────────────────────
            _SectionHeader('A2 — Positioned children'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'Indigo top-left, red top-right, green bottom-left, blue bottom-right.'),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    children: [
                      Container(width: 300, height: 300, color: kTileBg),
                      Positioned(
                        left: 20,
                        top: 20,
                        width: 80,
                        height: 80,
                        child: Container(color: const Color(0xFF3F51B5)),
                      ),
                      Positioned(
                        right: 20,
                        top: 20,
                        width: 80,
                        height: 80,
                        child: Container(color: const Color(0xFFEF5350)),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 20,
                        width: 80,
                        height: 80,
                        child: Container(color: const Color(0xFF4CAF50)),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 20,
                        width: 80,
                        height: 80,
                        child: Container(color: const Color(0xFF2196F3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── A3: Positioned.fill semi-transparent overlay ───────────────
            _SectionHeader('A3 — Positioned.fill overlay'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'Blue base box + semi-transparent red Positioned.fill overlay.'),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 120,
                  child: Stack(
                    children: [
                      Container(
                          width: 200,
                          height: 120,
                          color: const Color(0xFF2196F3)),
                      Positioned.fill(
                        child: Container(color: const Color(0x88EF5350)),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: Center(
                          child: Text(
                            'Positioned.fill overlay',
                            style: TextStyle(
                                color: kTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── B1: alignment switcher ─────────────────────────────────────
            _SectionHeader('B1 — alignment switcher'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'Non-Positioned children positioned by Stack.alignment. '
                'Tap a chip to change it.'),
            const SizedBox(height: 12),
            _ChipRow(
              options: _alignments.map((a) => a.label).toList(),
              selected: _alignIdx,
              onTap: (i) => setState(() => _alignIdx = i),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: _alignments[_alignIdx].value,
                    children: [
                      Container(
                          width: 300,
                          height: 300,
                          color: const Color(0xFF4CAF50)),
                      Container(
                          width: 200,
                          height: 200,
                          color: const Color(0xFFFFEB3B)),
                      Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFEF5350)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── B2: Alignment.center with non-Positioned layers ────────────
            _SectionHeader('B2 — Alignment.center layered cards'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'Two Transform-offset cards centered in the Stack — '
                'replicates the Gee app card carousel pattern.'),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: SizedBox(
                  width: 330,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // back card — offset + rotated
                      Transform.translate(
                        offset: const Offset(-4, 10),
                        child: Transform.rotate(
                          angle: 0.07,
                          child: Container(
                            width: 280,
                            height: 180,
                            decoration: BoxDecoration(
                              color: kChipBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      // front card
                      Container(
                        width: 280,
                        height: 180,
                        decoration: BoxDecoration(
                          color: kRowBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kTextTertiary, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            'Front card',
                            style: TextStyle(color: kTextPrimary, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── C1: StackFit.expand ────────────────────────────────────────
            _SectionHeader('C1 — StackFit.expand'),
            const SizedBox(height: 4),
            _SectionSubtitle('All children forced to fill the Stack. '
                'Green fills 200×120, then semi-transparent blue covers it entirely.'),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: const Color(0xFF4CAF50)),
                      Container(color: const Color(0x772196F3)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── D1: full-screen host pattern ───────────────────────────────
            _SectionHeader('D1 — Positioned.fill host + bottom overlay'),
            const SizedBox(height: 4),
            _SectionSubtitle('Positioned.fill column drives layout. '
                'Positioned(bottom: 16) floats a pill on top.'),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 260,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(color: kRowBg),
                          child: Column(
                            children: [
                              Container(
                                height: 44,
                                color: kTileBg,
                                child: Center(
                                  child: Text(
                                    'nav bar',
                                    style: TextStyle(
                                        color: kTextPrimary, fontSize: 14),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'content area',
                                    style: TextStyle(
                                        color: kTextTertiary, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kTextTertiary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                'floating pill',
                                style: TextStyle(
                                    color: kTextPrimary, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── D2: Expanded > Stack > Offstage switcher ───────────────────
            _SectionHeader('D2 — Expanded > Stack > Offstage'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'Three Offstage slots inside a Stack inside Expanded. '
                'Only the active slot is visible; Stack height follows Expanded.'),
            const SizedBox(height: 12),
            // Tab chips
            _ChipRow(
              options: const ['Chat', 'Home', 'Feed'],
              selected: _activeTab,
              onTap: (i) => setState(() => _activeTab = i),
            ),
            const SizedBox(height: 8),
            _Card(
              child: SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Offstage(
                      offstage: _activeTab != 0,
                      child: Container(
                        color: const Color(0xFF1C3A5E),
                        child: Center(
                          child: Text('Chat',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),
                    ),
                    Offstage(
                      offstage: _activeTab != 1,
                      child: Container(
                        color: kRowBg,
                        child: Center(
                          child: Text('Home',
                              style:
                                  TextStyle(color: kTextPrimary, fontSize: 18)),
                        ),
                      ),
                    ),
                    Offstage(
                      offstage: _activeTab != 2,
                      child: Container(
                        color: const Color(0xFF1A3A1A),
                        child: Center(
                          child: Text('Feed',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── D3: Stack(fit: expand) inside SizedBox ─────────────────────
            _SectionHeader('D3 — StackFit.expand card with gradient overlay'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'SizedBox > Stack(fit: expand) — card page fills bounds, '
                'gradient + Positioned label float above.'),
            const SizedBox(height: 12),
            _Card(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // card background
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E3A8A),
                              Color(0xFF3B82F6),
                            ],
                          ),
                        ),
                      ),
                      // gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00000000),
                                Color(0xBB000000),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // bottom label
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fixed light-on-dark text: the card sits on a blue
                            // gradient in both themes, so it never follows the
                            // palette's light-mode text colors.
                            Text(
                              'Card Title',
                              style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Subtitle · StackFit.expand',
                              style: TextStyle(
                                  color: Color(0xFF8E8E93), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ── E: Flutter-compat — Stack flow-child + IgnorePointer ──────────
            // These cases exercise two Flutter-parity behaviors:
            //   1. The first non-positioned child stays in normal flow (the
            //      Stack gets a correct measured height in a ListView cell).
            //   2. IgnorePointer is layout-transparent (its child renders).
            //
            // PASS criteria:
            //   E1 — green bubble visible, cell has natural height (not 0).
            //   E2 — three coloured items visible inside IgnorePointer.
            //   E3 — AnimatedSwitcher-style toggle: both states render correctly.

            // ── E1: content + Positioned.fill overlay (the _TurnHighlight idiom)
            _SectionHeader('E1 — Content + Positioned.fill overlay'),
            const SizedBox(height: 4),
            _SectionSubtitle('Green bubble (non-positioned) sizes the Stack. '
                'Semi-transparent overlay (Positioned.fill + IgnorePointer) floats above. '
                'Cell must NOT collapse to 0 height.'),
            const SizedBox(height: 12),
            _Card(
              child: _E1OverlayDemo(),
            ),
            const SizedBox(height: 28),

            // ── E2: IgnorePointer passthrough
            _SectionHeader('E2 — IgnorePointer passthrough'),
            const SizedBox(height: 4),
            _SectionSubtitle('IgnorePointer wraps a Column of items. '
                'All three rows must be visible (previously subtree was dropped).'),
            const SizedBox(height: 12),
            _Card(
              child: IgnorePointer(
                ignoring: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _DemoRow(
                        label: 'Row 1 inside IgnorePointer',
                        color: Color(0xFFEF5350)),
                    SizedBox(height: 8),
                    _DemoRow(
                        label: 'Row 2 inside IgnorePointer',
                        color: Color(0xFF4CAF50)),
                    SizedBox(height: 8),
                    _DemoRow(
                        label: 'Row 3 inside IgnorePointer',
                        color: Color(0xFF2196F3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── E3: Stack inside ListView cell (height must not collapse)
            _SectionHeader('E3 — Stack in ListView cell — height check'),
            const SizedBox(height: 4),
            _SectionSubtitle(
                'Three chat-bubble-style cells. Each is a Stack with a Column '
                'content child + Positioned.fill highlight overlay. '
                'All three cells must be visible and have natural height.'),
            const SizedBox(height: 12),
            ...[
              ('Hello, how are you?', false),
              ('I am doing great, thanks for asking!', true),
              ('What can I help you with today?', false),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Stack(
                  children: [
                    // Main content — sizes the Stack (flow child)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kRowBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$2 ? '★ highlighted' : 'normal',
                            style: TextStyle(
                              color: item.$2
                                  ? const Color(0xFFFFD60A)
                                  : kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Overlay — floats above (Positioned.fill + IgnorePointer)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: item.$2
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0x22FFD60A),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// ── E1 demo widget ─────────────────────────────────────────────────────────────

class _E1OverlayDemo extends StatefulWidget {
  const _E1OverlayDemo();

  @override
  State<_E1OverlayDemo> createState() => _E1OverlayDemoState();
}

class _E1OverlayDemoState extends State<_E1OverlayDemo> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stack: first non-positioned child (bubble) must size the Stack.
        Stack(
          children: [
            // Flow child — gives the Stack its height.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, how are you?',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Non-positioned child → sizes the Stack',
                    style: TextStyle(color: Color(0xFF80CBC4), fontSize: 12),
                  ),
                ],
              ),
            ),
            // Overlay — floats above, must not affect Stack height.
            Positioned.fill(
              child: IgnorePointer(
                child: _highlighted
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0x33FFD700),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _highlighted = !_highlighted),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _highlighted
                  ? 'Overlay: ON — tap to hide'
                  : 'Overlay: OFF — tap to show',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ── E2 demo row ────────────────────────────────────────────────────────────────

class _DemoRow extends StatelessWidget {
  const _DemoRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: kTextPrimary, fontSize: 14),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: TextStyle(
          color: kTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionSubtitle extends StatelessWidget {
  const _SectionSubtitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: TextStyle(color: kTextSecondary, fontSize: 13),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kRowBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onTap,
  });
  final List<String> options;
  final int selected;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: i == selected ? const Color(0xFF0A84FF) : kTileBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    color: i == selected
                        ? const Color(0xFFFFFFFF)
                        : kTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
