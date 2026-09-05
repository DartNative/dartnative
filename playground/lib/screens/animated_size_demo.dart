/// AnimatedSize demo — tests expand/collapse animation via Container maxHeight.
library;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

// ─── Duration presets ─────────────────────────────────────────────────────────

const _durations = [
  (label: '100 ms', ms: 100),
  (label: '200 ms', ms: 200),
  (label: '350 ms', ms: 350),
  (label: '500 ms', ms: 500),
  (label: '800 ms', ms: 800),
];

// ─── Curve presets ────────────────────────────────────────────────────────────

const _curves = [
  (label: 'linear', curve: Curves.linear),
  (label: 'easeIn', curve: Curves.easeIn),
  (label: 'easeOut', curve: Curves.easeOut),
  (label: 'easeInOut', curve: Curves.easeInOut),
  (label: 'bounceOut', curve: Curves.bounceOut),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnimatedSizeDemo extends StatefulWidget {
  const AnimatedSizeDemo({super.key});

  @override
  State<AnimatedSizeDemo> createState() => _AnimatedSizeDemoState();
}

class _AnimatedSizeDemoState extends State<AnimatedSizeDemo> {
  bool _showPanel = false;
  bool _showSlider = false;

  // Shared settings used by all three sections.
  int _durationMs = 350;
  Curve _curve = Curves.easeInOut;

  Duration get _duration => Duration(milliseconds: _durationMs);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'AnimatedSize Demo',
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

            // ── Controls ────────────────────────────────────────────────────
            _SectionHeader('Duration'),
            const SizedBox(height: 10),
            _ChipRow(
              options: _durations.map((d) => d.label).toList(),
              selected: _durations.indexWhere((d) => d.ms == _durationMs),
              onTap: (i) => setState(() => _durationMs = _durations[i].ms),
            ),
            const SizedBox(height: 20),
            _SectionHeader('Curve'),
            const SizedBox(height: 10),
            _ChipRow(
              options: _curves.map((c) => c.label).toList(),
              selected: _curves.indexWhere((c) => c.curve == _curve),
              onTap: (i) => setState(() => _curve = _curves[i].curve),
            ),

            const SizedBox(height: 32),

            // ── Section 1: simple show/hide ─────────────────────────────────
            _SectionHeader('1. Show / Hide panel'),
            const SizedBox(height: 12),
            _ToggleButton(
              label: _showPanel ? 'Hide panel' : 'Show panel',
              onTap: () => setState(() => _showPanel = !_showPanel),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: _duration,
              curve: _curve,
              child: _showPanel
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kRowBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expanded panel',
                              style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                              'This content animates into view from zero height.',
                              style: TextStyle(
                                  color: kTextSecondary, fontSize: 14)),
                          SizedBox(height: 8),
                          Text(
                              'It uses AnimatedSize wrapping a real widget vs SizedBox.shrink.',
                              style: TextStyle(
                                  color: kTextSecondary, fontSize: 14)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 40),

            // ── Section 2: inline expansion (toolbar pattern) ───────────────
            _SectionHeader('2. Inline slider (top-bar pattern)'),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showSlider = !_showSlider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Text('Volume',
                              style:
                                  TextStyle(color: kTextPrimary, fontSize: 15)),
                          const Spacer(),
                          Text(
                            _showSlider ? '▲ hide' : '▼ show',
                            style:
                                TextStyle(color: kTextSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: _duration,
                    curve: _curve,
                    child: _showSlider
                        ? Container(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _FakeSlider(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Section 3: fast toggle stress test ──────────────────────────
            _SectionHeader('3. Fast-toggle stress test'),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tap rapidly — animation should not glitch or get stuck.',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            _FastToggleSection(duration: _duration, curve: _curve),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of tappable pill chips.
class _ChipRow extends StatelessWidget {
  final List<String> options;
  final int selected;
  final void Function(int) onTap;
  const _ChipRow(
      {required this.options, required this.selected, required this.onTap});

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Simulates a slider row (Slider widget would work too).
class _FakeSlider extends StatefulWidget {
  @override
  State<_FakeSlider> createState() => _FakeSliderState();
}

class _FakeSliderState extends State<_FakeSlider> {
  double _value = 0.6;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          activeColor: const Color(0xFF007AFF),
          inactiveColor: kChipBg,
        ),
        Text(
          'Value: ${(_value * 100).round()}%',
          style: TextStyle(color: kTextSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

/// Rapid toggle — stress tests animation interruption handling.
class _FastToggleSection extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  const _FastToggleSection({required this.duration, required this.curve});

  @override
  State<_FastToggleSection> createState() => _FastToggleSectionState();
}

class _FastToggleSectionState extends State<_FastToggleSection> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleButton(
          label: _visible ? 'Collapse' : 'Expand',
          onTap: () => setState(() => _visible = !_visible),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: widget.duration,
          curve: widget.curve,
          child: _visible
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kTileBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Fast toggle content',
                    style: TextStyle(color: kTextPrimary, fontSize: 14),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
