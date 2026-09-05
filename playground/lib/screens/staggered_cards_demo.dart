/// Staggered cards entrance — "a row of
/// cards that fade in, then slide up, then settle — all using
/// implicit-animation widgets composed in a `Column`."
///
/// Each card composes [AnimatedOpacity] (fade) + [AnimatedSlide] (slide up
/// from below) — two implicit-animation widgets. The "stagger" is just a 150ms `Future.delayed`
/// between flipping each card's "shown" flag; no orchestration framework
/// needed, no `dartnative_skia` import.
///
/// On entry the cards rise into view one after another. The "Replay"
/// button resets and replays the sequence so you can see it again
/// without re-navigating to the screen.
library;

import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class StaggeredCardsDemo extends StatefulWidget {
  const StaggeredCardsDemo({super.key});

  @override
  State<StaggeredCardsDemo> createState() => _StaggeredCardsDemoState();
}

class _StaggeredCardsDemoState extends State<StaggeredCardsDemo> {
  // Per-card "visible" flags. AnimatedOpacity/AnimatedSlide tween based
  // on these. A card is initially invisible (faded + 40 px below); we
  // flip the flag to trigger the entrance animation.
  final List<bool> _visible = [false, false, false, false];

  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    // Schedule the first stagger run after the screen mounts so the
    // user actually sees the entrance (otherwise it would happen before
    // they can look).
    Timer(const Duration(milliseconds: 200), _runStagger);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _runStagger() async {
    // Reset to invisible synchronously, then flip each card on a
    // staggered delay.
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _visible.length; i++) {
        _visible[i] = false;
      }
    });
    // Let the framework process the reset frame before starting the
    // entrance sequence — otherwise the first card may flip "shown"
    // before the "hidden" state has actually been painted.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    for (var i = 0; i < _visible.length; i++) {
      if (!mounted) return;
      setState(() => _visible[i] = true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Staggered cards',
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
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _SectionTitle('Fade + slide-up, staggered'),
            const _SectionBody(
              'Four cards rise into view with a 150 ms delay between each, '
              'composing AnimatedOpacity (0→1) and AnimatedSlide (Offset(0, 40)→Offset.zero). '
              'No Skia, no orchestration framework — just two '
              'implicit-animation widgets and a staggered setState.',
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _Card(
                    visible: _visible[0],
                    title: 'Recently played',
                    body: 'Track 1 · 3:42 · Last week',
                    accent: const Color(0xFF0A84FF),
                  ),
                  _Card(
                    visible: _visible[1],
                    title: 'New releases',
                    body: '32 new tracks · This Friday',
                    accent: const Color(0xFF30D158),
                  ),
                  _Card(
                    visible: _visible[2],
                    title: 'Made for you',
                    body: '12 playlists · Refreshed daily',
                    accent: const Color(0xFFFF9F0A),
                  ),
                  _Card(
                    visible: _visible[3],
                    title: 'Recently added',
                    body: '4 new albums · This week',
                    accent: const Color(0xFFFF453A),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: GestureDetector(
                onTap: _runStagger,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Replay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── One card ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final bool visible;
  final String title;
  final String body;
  final Color accent;
  const _Card({
    required this.visible,
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      // AnimatedSlide in dartnative takes Offset in logical pixels.
      // Start 40 px below the resting position, slide up to zero.
      offset: visible ? Offset.zero : const Offset(0, 40),
      duration: const Duration(milliseconds: 380),
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kRowBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.4), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
