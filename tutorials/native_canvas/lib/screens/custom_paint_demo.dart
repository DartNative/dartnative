/// Native `CustomPaint` demo — the platform 2D-canvas pipeline.
///
/// This screen exercises the path that runs entirely on the platform's
/// 2D renderer (Core Graphics on iOS, `android.graphics.Canvas` on
/// Android). No `dartnative_skia`.
///
/// Eighteen painters, each isolating a different op surface:
///   1. **Star polygon** — `Path` with `moveTo`/`lineTo`/`close` + fill + stroke.
///   2. **Sparkline** — `drawLine` chains + dots via `drawCircle`.
///   3. **Rounded card** — `drawRRect` + `drawRect` shadow + transform.
///   4. **Labelled bar chart** — `drawRect` + `drawText` (single-line text op).
///   5. **Gradient bars + radial swatch** — `ui.Gradient.linear` /
///       `ui.Gradient.radial` set on `Paint.shader`.
///   6. **Multi-line paragraph** — `ui.ParagraphBuilder` + per-span styles +
///       `Canvas.drawParagraph` for wrapped, mixed-style text inside a
///       painter.
///   7. **Paragraph parity** — line-height multiplier, shadows, background
///       color, letter spacing, decoration variants. Visually exercises
///       every per-span / per-paragraph field.
///   8. **Paragraph layout** — `TextDirection.rtl` (Arabic), `TextAlign.justify`,
///       `maxLines` + `ellipsis`, paragraph-level `height` multiplier.
///   9. **Paragraph measured metrics** — `Paragraph.layout()` returns real
///       `width` / `height` / `longestLine` / `lineCount` / `didExceedMaxLines`
///       / intrinsic widths / baselines via a sync FFI roundtrip to
///       CTFramesetter (iOS) / StaticLayout (Android).
///   10. **Paragraph per-line metrics** — `paragraph.getLineMetrics()`
///       returns a `List<LineMetrics>` with ascent / descent / width /
///       left / baseline / hardBreak / lineNumber per line, used to
///       draw a translucent bounding box around every rendered line.
///   11. **Paragraph hit testing** — `paragraph.getBoxesForRange(start, end)`
///       returns `List<TextBox>` for a glyph range (drawn as a yellow
///       highlight); `paragraph.getPositionForOffset(Offset)` maps an
///       (x, y) probe to a `TextPosition` (drawn as a blue caret +
///       offset label). Every tap resolves the real tap coordinate.
///   12. **Paragraph strut** — `StrutStyle`, `forceStrutHeight`.
///   13. **Foreground paint** — `TextStyle.foreground`, including a
///       gradient-filled glyph fill.
///   14. **Images** — `drawImage` / `drawImageRect` from the platform's
///       image cache.
///   15. **Variable fonts** — `TextStyle.fontVariations` + `fontFeatures`.
///   16. **Leading distribution** — `ParagraphStyle.leadingDistribution`.
///   17. **Typewriter** — an animated `drawParagraph` reveal.
///   18. **Per-letter color wave** — per-glyph paints driven by a
///       controller.
///
/// Each painter implements `shouldRepaint` honestly, so a painter that
/// does not depend on the slider value sends nothing to the native side
/// while the slider moves — after first paint it is never re-encoded.
library;

import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
// dart:ui-aligned `Gradient` (Shader subclass with `.linear` / `.radial`
// factory constructors). Imported with the `ui` prefix the way Flutter
// consumer code reaches `dart:ui.Gradient`.
import 'package:dartnative/canvas.dart' as ui;
import 'home/demo_ui.dart';

class CustomPaintDemo extends StatefulWidget {
  const CustomPaintDemo({super.key});

  @override
  State<CustomPaintDemo> createState() => _CustomPaintDemoState();
}

class _CustomPaintDemoState extends State<CustomPaintDemo>
    with TickerProviderStateMixin {
  // 0..1 slider that the sparkline painter listens to (it animates the
  // visible-data range). Star + card painters ignore it — so they should
  // NOT re-encode when this changes.
  double _slider = 0.4;

  /// Drives sections 17 (typewriter) and 18 (per-letter color). One
  /// controller per effect keeps them visually independent — they tick
  /// from different starting phases and at different speeds. Each
  /// listener calls setState so the painters see fresh values; the
  /// painters' `shouldRepaint` discards no-op frames.
  late final AnimationController _typewriterCtrl;
  late final AnimationController _rainbowCtrl;

  static const _typewriterText = 'Native typewriter via CustomPaint.';
  static const _rainbowText = 'DARTNATIVE';

  /// Probe point for section 11's hit-test demo: the view-local
  /// coordinate of the most recent tap on that canvas, in
  /// paragraph-local space (the painter's inset is subtracted off).
  /// `null` until the first tap arrives — the painter shows an
  /// instructional placeholder in that state.
  Offset? _hitTestProbe;

  /// URL the section-14 painter references via [CanvasImage.network].
  /// Pre-loaded once on first build via [_drawImageDemoPrecache] so
  /// the bitmap is already in the native cache before the painter
  /// runs (Canvas paints are synchronous — they can't await a load).
  static const _drawImageDemoUrl = 'https://picsum.photos/seed/dnflag/220/140';

  /// Future tracked across rebuilds so we only kick off one precache.
  Future<bool>? _drawImageDemoFuture;

  Future<bool> _drawImageDemoPrecache() {
    return _drawImageDemoFuture ??= () async {
      try {
        // Kick off the load — fire-and-forget on both platforms; the
        // Future returned by precacheImage resolves before the bitmap
        // is actually in the cache.
        await precacheImage(NetworkImage(_drawImageDemoUrl));
        // Poll the platform's in-memory image cache so the demo's
        // FutureBuilder only marks ready=true when drawImage will
        // actually find the bitmap. Bail after ~5 s so a broken URL
        // or offline device doesn't hang the demo forever.
        for (var i = 0; i < 50; i++) {
          if (ImageCache.isCached(_drawImageDemoUrl)) return true;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        return false;
      } catch (_) {
        return false;
      }
    }();
  }

  @override
  void initState() {
    super.initState();
    // Typewriter — reveals N glyphs over ~3.5s, holds full text for the
    // remainder of the loop, then restarts. Multiplying value by 1.4
    // means count reaches `text.length` at t≈0.71 and the next ~30%
    // of the loop is a dwell at full reveal.
    _typewriterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )
      ..addListener(() => setState(() {}))
      ..repeat();
    // Per-letter color wave — one full hue rotation per loop.
    _rainbowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )
      ..addListener(() => setState(() {}))
      ..repeat();
  }

  @override
  void dispose() {
    _typewriterCtrl.dispose();
    _rainbowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CustomPaint(size:) requires CONCRETE dimensions — the painter
    // writes absolute coordinates, so the size has to be known up front.
    // We derive the canvas width from MediaQuery, subtracting the Stage's
    // horizontal margin (16 each side).
    final canvasWidth = MediaQuery.of(context).size.width - 32;
    final canvasSize = Size(canvasWidth, 220);

    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'CustomPaint (native)',
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

            // ── Star polygon — Path + fill + stroke ────────────────────
            const _SectionTitle('1.  Star polygon (Path + fill + stroke)'),
            const _SectionBody(
              'Exercises moveTo/lineTo/close, fill, stroke with a join.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _StarPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Sparkline — drawLine + drawCircle ──────────────────────
            const _SectionTitle('2.  Sparkline (drawLine + drawCircle)'),
            const _SectionBody(
              'Animates as you drag the slider — the painter re-emits '
              'a new display list each tick. shouldRepaint returns true '
              'only when the visible range actually changes.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _SparklinePainter(progress: _slider),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Range: ${(_slider * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _slider,
                    min: 0,
                    max: 1,
                    activeColor: const Color(0xFF0A84FF),
                    inactiveColor: kChipBg,
                    onChanged: (v) => setState(() => _slider = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Rounded card — drawRRect + drawRect (shadow) ────────────
            const _SectionTitle('3.  Rounded card (drawRRect + shadow)'),
            const _SectionBody(
              'Per-corner radii + a stroke. Static painter — should '
              're-encode once on first frame, never again.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _RoundedCardPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Labelled bar chart — drawRect + drawText ────────────────
            const _SectionTitle('4.  Labelled bar chart (drawRect + drawText)'),
            const _SectionBody(
              'Exercises the single-line drawText op (iOS '
              'NSAttributedString.draw / Android Canvas.drawText). Axis '
              'labels are anchored bottom-left of each bar; the value at '
              'the top of each bar is centre-aligned. Static painter — '
              'no re-encode on slider changes.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _BarChartPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Gradient bars + radial swatch ──────────────────────────
            const _SectionTitle(
                '5.  Gradient shaders (Paint.shader = ui.Gradient.linear / ui.Gradient.radial)'),
            const _SectionBody(
              'Fills painted shapes with a CGGradient (iOS) / '
              'android.graphics.LinearGradient + RadialGradient (Android). '
              'Stops, multi-colour, vertical and radial gradients in one '
              'painter — gradient strokes fall back to a solid colour.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _GradientShowcasePainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Paragraph — drawParagraph (multi-line, mixed styles) ───
            const _SectionTitle(
                '6.  Paragraph (ui.ParagraphBuilder + drawParagraph)'),
            const _SectionBody(
              'Multi-line wrapped text with mixed-style spans inside a '
              'CustomPainter — exercises the Flutter-compat '
              'ParagraphBuilder + ParagraphStyle + drawParagraph path '
              '(iOS NSAttributedString.draw(in:) / Android StaticLayout). '
              'Static painter — no re-encode on slider changes.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _ParagraphShowcasePainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Paragraph parity showcase ──────────────────────────────
            const _SectionTitle(
                '7.  Paragraph parity — height / shadows / background / letterSpacing / overline / decoration colour'),
            const _SectionBody(
              'Visually exercises every TextStyle / ParagraphStyle field. '
              'Each column isolates a feature group, so a field that is '
              'not applied shows up as a column that drifts from its '
              'expected look.',
            ),
            const SizedBox(height: 10),
            _Stage(
              // Column 3 wraps to 8 visual lines at fontSize 16 × height 1.4
              // (header + underline/RED/strike/YELLOW/overline + 2-line
              // "GREEN (iOS only)"). The shared 220-px canvas only leaves
              // ~10px below the last line, putting the closing parenthesis
              // flush against the card border — bump both the Stage and the
              // CustomPaint canvas so the column has natural bottom
              // breathing room.
              height: 260,
              child: CustomPaint(
                size: Size(canvasSize.width, 260),
                painter: _ParagraphParityPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Paragraph layout-level showcase (RTL + justify) ────────
            const _SectionTitle(
                '8.  Paragraph layout — RTL + justify + maxLines/ellipsis + paragraph line-height'),
            const _SectionBody(
              'Three columns demonstrating ParagraphStyle.textDirection '
              '(RTL with Arabic), TextAlign.justify (works on iOS / Android '
              'API 26+), and ParagraphStyle.height (whole-paragraph line-'
              'height multiplier) + maxLines + ellipsis.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _ParagraphLayoutPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Paragraph measured metrics ─────────────────────────────
            const _SectionTitle(
                '9.  Paragraph measured metrics (sync FFI roundtrip)'),
            const _SectionBody(
              'Paragraph.layout(constraints) calls the native text-shaping '
              'engine (CTFramesetter on iOS, StaticLayout on Android) '
              'synchronously and caches the measured width / height / '
              'line count / longestLine / didExceedMaxLines / intrinsic '
              'widths / baselines on the Paragraph instance. The right-'
              'hand column lists the values the painter read back BEFORE '
              'drawing the paragraph on the left.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _ParagraphMetricsPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Per-line metrics (getLineMetrics) ──────────────────────
            const _SectionTitle(
                '10.  Paragraph per-line metrics (getLineMetrics)'),
            const _SectionBody(
              'Paragraph.getLineMetrics() returns a List<LineMetrics> '
              '— one entry per rendered line with ascent / descent / '
              'width / left / baseline / hardBreak / lineNumber. The '
              'painter draws a translucent box around every line using '
              'those bounds; if the per-line metrics agree with the '
              'rendered layout, every box hugs its line exactly.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _ParagraphLineMetricsPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Hit testing (getBoxesForRange + getPositionForOffset) ──
            const _SectionTitle(
                '11.  Paragraph hit testing (getBoxesForRange + getPositionForOffset)'),
            const _SectionBody(
              'Tap inside the paragraph. Blue caret = the character '
              'under your finger (`getPositionForOffset`, accurate '
              'within ~3 px). Yellow rect = the whole word around '
              'that char (`getBoxesForRange`).\n\n'
              'Both run synchronously on a background-free FFI path — '
              'every tap is a fresh measure pass, no stale layout, '
              'no animation lag.',
            ),
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              // `onTapUp` carries view-local logical px on both platforms.
              // Subtract the painter's inset to get paragraph-local
              // coords, then push to state so the painter can resolve
              // them via getPositionForOffset.
              onTapUp: (details) {
                final viewLocal = details.localPosition;
                setState(() {
                  _hitTestProbe = Offset(
                    viewLocal.dx - _ParagraphHitTestPainter.paragraphInsetX,
                    viewLocal.dy - _ParagraphHitTestPainter.paragraphInsetY,
                  );
                });
              },
              child: _Stage(
                // ~4 lines of paragraph (~88 px) + ~32 px for the
                // legend / result row + 20 px gap between them +
                // a little breathing room top and bottom.
                height: 170,
                child: CustomPaint(
                  size: Size(canvasWidth, 170),
                  painter: _ParagraphHitTestPainter(
                    probe: _hitTestProbe,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── StrutStyle — forced per-line height ────────────────
            const _SectionTitle(
                '12.  Paragraph strut (StrutStyle, forceStrutHeight)'),
            const _SectionBody(
              'StrutStyle.forceStrutHeight = uniform row heights, '
              'useful for tabular layout. All text is fontSize 14 '
              'on both sides — the only difference is the right '
              'paragraph has StrutStyle(fontSize: 14, height: 2.5).\n\n'
              'Left: off — rows are ~18 px each (1-px descender '
              'variation only; Android keeps every line at the '
              'base font\'s natural metrics).\n'
              'Right: on — every row is `fontSize × height = 35 px`, '
              'about 2× taller, perfectly uniform.\n\n'
              'Numbers on the right side show each row\'s height.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _StrutDemoPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Foreground Paint — gradient + outline text ────────────
            const _SectionTitle('13.  Foreground Paint (TextStyle.foreground)'),
            const _SectionBody(
              'TextStyle.foreground overrides the glyph fill with a '
              'custom Paint — same shape as Flutter\'s dart:ui API. '
              'Three rows below:\n\n'
              '• Plain solid colour (no foreground).\n'
              '• Outline text — Paint(style: stroke, strokeWidth: 1.5).\n'
              '• Gradient text — Paint with a linear Gradient.shader '
              '(Android only; iOS fills the glyphs with the Paint\'s '
              'colour instead).',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: CustomPaint(
                size: canvasSize,
                painter: _ForegroundPaintDemoPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── drawImage / drawImageRect ─────────────────────────────
            const _SectionTitle('14.  drawImage / drawImageRect'),
            const _SectionBody(
              'Same bitmap drawn two ways:\n\n'
              'LEFT — drawImage at natural size. The full 220×140 '
              'photo.\n\n'
              'RIGHT — drawImageRect picking the BOTTOM-RIGHT '
              'quadrant of the source (a 110×70 region) and scaling '
              'it up to fill the column. A red outline traces which '
              'region of the left image is being shown on the right.\n\n'
              'The right side shows the bottom-right corner of the left '
              'image, just bigger.',
            ),
            const SizedBox(height: 10),
            FutureBuilder<bool>(
              future: _drawImageDemoPrecache(),
              builder: (ctx, snap) {
                return _Stage(
                  child: CustomPaint(
                    size: canvasSize,
                    painter: _DrawImageDemoPainter(
                      ready: snap.data == true,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── fontFeatures + fontVariations ─────────────────────────
            const _SectionTitle(
                '15.  TextStyle.fontVariations (+ fontFeatures)'),
            const _SectionBody(
              'fontVariations: [weight(N)] axis applied across three '
              'weights. Expect progressively heavier glyphs '
              '400 → 700 → 900.',
            ),
            const SizedBox(height: 10),
            _Stage(
              // Three 36-px glyphs + a 28-px header take ~80 px;
              // shrink the stage so the demo doesn't leave a tall
              // empty box below the row.
              height: 110,
              child: CustomPaint(
                size: Size(canvasWidth, 110),
                painter: _FontFeaturesDemoPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── leadingDistribution ───────────────────────────────────
            const _SectionTitle('16.  ParagraphStyle.leadingDistribution'),
            const _SectionBody(
              'Same 2-line text with height: 2.5 on both. Red outlines '
              'mark each row\'s bounds.\n\n'
              'Look at where "Ag" sits inside its row:\n'
              '• LEFT (proportional) — in the LOWER portion of the row. '
              'The extra leading is split proportional to the font\'s '
              'ascent/descent ratio, so ~80% goes above the ascender and '
              '~20% below — glyph pushed down but not all the way.\n'
              '• RIGHT (even) — CENTERED in the row. Extra leading split '
              '50/50.',
            ),
            const SizedBox(height: 10),
            _Stage(
              height: 170,
              child: CustomPaint(
                size: Size(canvasWidth, 170),
                painter: _LeadingDistributionDemoPainter(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Typewriter effect ─────────────────────────────────────
            const _SectionTitle('17.  Typewriter (animated drawParagraph)'),
            const _SectionBody(
              'A single Paragraph rebuilt each tick with `text.substring'
              '(0, n)`. The painter consults the AnimationController '
              'value; shouldRepaint compares the integer reveal count so '
              'no redundant display-list bytes are emitted between glyphs.',
            ),
            const SizedBox(height: 10),
            _Stage(
              height: 110,
              child: CustomPaint(
                size: Size(canvasWidth, 110),
                painter: _TypewriterPainter(
                  text: _typewriterText,
                  // 1.4 × value: reaches full reveal at t≈0.71 then dwells.
                  progress: (_typewriterCtrl.value * 1.4).clamp(0.0, 1.0),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Per-letter color animation ────────────────────────────
            const _SectionTitle('18.  Per-letter color wave'),
            const _SectionBody(
              'One Paragraph, one span PER CHARACTER, each pushed with '
              'its own color derived from `(phase + i / length) % 1`. '
              'Cross-platform via the existing drawParagraph wire — no '
              'RichText, no per-glyph drawText calls.',
            ),
            const SizedBox(height: 10),
            _Stage(
              height: 110,
              child: CustomPaint(
                size: Size(canvasWidth, 110),
                painter: _PerLetterColorPainter(
                  text: _rainbowText,
                  phase: _rainbowCtrl.value,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No Skia involved. Painters emit a compact binary display '
                'list; the native view replays the bytes in draw(_:) '
                '(iOS / Core Graphics) or onDraw (Android / '
                'android.graphics.Canvas).',
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

/// Typewriter — reveals one glyph at a time from a fixed string. [progress]
/// runs 0..1 over the animation loop; the painter floors it into an integer
/// reveal count so `shouldRepaint` only fires when a new glyph appears
/// (or the cursor toggles).
class _TypewriterPainter extends CustomPainter {
  final String text;
  final double progress;
  _TypewriterPainter({required this.text, required this.progress});

  int get _revealedCount =>
      (text.length * progress).floor().clamp(0, text.length);

  @override
  void paint(Canvas canvas, Size size) {
    final n = _revealedCount;
    final visible = text.substring(0, n);
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ))
      ..pushStyle(ui.TextStyle(color: kTextPrimary))
      ..addText(visible);
    final p = pb.build()
      ..layout(ui.ParagraphConstraints(width: size.width - 32));
    final textX = 16.0;
    final textY = size.height / 2 - p.height / 2;
    canvas.drawParagraph(p, Offset(textX, textY));

    // 2-px blue caret rendered immediately after the last glyph while
    // still typing. Positioned via the LAST line's metrics so it tracks
    // the active glyph row even when the text wraps to multiple lines
    // (otherwise the caret height would stretch across all lines).
    // Drops out at full reveal so the dwell phase reads as "done"
    // rather than "stuck".
    if (n < text.length) {
      final lines = p.getLineMetrics();
      if (lines.isNotEmpty) {
        final last = lines.last;
        final lineTop = textY + last.baseline - last.ascent;
        canvas.drawRect(
          Rect.fromLTWH(
            textX + last.left + last.width + 1,
            lineTop + 2,
            2,
            (last.ascent + last.descent) - 4,
          ),
          Paint()..color = const Color(0xFF0A84FF),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TypewriterPainter old) =>
      _revealedCount != old._revealedCount;
}

/// Per-letter color wave. One paragraph, one span per character; each
/// span's color is derived from `(phase + i / length) % 1` mapped through
/// HSL to give a smooth rainbow that drifts sideways across the string.
class _PerLetterColorPainter extends CustomPainter {
  final String text;
  final double phase;
  _PerLetterColorPainter({required this.text, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      textAlign: TextAlign.center,
    ));
    final n = text.length;
    for (var i = 0; i < n; i++) {
      // `phase - i/N` (not `+`) makes the colour band travel LEFT→RIGHT
      // as `phase` grows: the hue seen at index 0 today appears at index k
      // after time k/N — a wave sweeping rightward across the string.
      final hue = (phase - i / n) % 1.0;
      pb.pushStyle(ui.TextStyle(color: _hslToColor(hue, 0.75, 0.6)));
      pb.addText(text[i]);
      pb.popStyle();
    }
    final p = pb.build()..layout(ui.ParagraphConstraints(width: size.width));
    canvas.drawParagraph(p, Offset(0, size.height / 2 - p.height / 2));
  }

  /// HSL → ARGB. h, s, l in [0, 1]. Standard formula, no external deps.
  Color _hslToColor(double h, double s, double l) {
    final c = (1 - (2 * l - 1).abs()) * s;
    final hp = (h * 6) % 6;
    final x = c * (1 - ((hp % 2) - 1).abs());
    final m = l - c / 2;
    double r, g, b;
    if (hp < 1) {
      r = c;
      g = x;
      b = 0;
    } else if (hp < 2) {
      r = x;
      g = c;
      b = 0;
    } else if (hp < 3) {
      r = 0;
      g = c;
      b = x;
    } else if (hp < 4) {
      r = 0;
      g = x;
      b = c;
    } else if (hp < 5) {
      r = x;
      g = 0;
      b = c;
    } else {
      r = c;
      g = 0;
      b = x;
    }
    return Color.fromARGB(
      255,
      ((r + m) * 255).round().clamp(0, 255),
      ((g + m) * 255).round().clamp(0, 255),
      ((b + m) * 255).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(_PerLetterColorPainter old) => phase != old.phase;
}

/// Star polygon, centred in the available size.
class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = math.min(size.width, size.height) / 2 - 14;
    final inner = outer * 0.5;
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      // Start at -π/2 so the top point faces up.
      final theta = -math.pi / 2 + i * math.pi / points;
      final x = cx + math.cos(theta) * r;
      final y = cy + math.sin(theta) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill first, then stroke on top.
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD60A); // iOS systemYellow
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFF9F0A); // iOS systemOrange
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}

/// Sparkline driven by [progress] (0..1). Shows the first
/// `progress * count` data points; the rest are dimmed.
class _SparklinePainter extends CustomPainter {
  final double progress;
  const _SparklinePainter({required this.progress});

  // Static, deterministic data so the visuals are stable across rebuilds.
  static const _data = <double>[
    0.4,
    0.55,
    0.5,
    0.6,
    0.72,
    0.65,
    0.78,
    0.82,
    0.76,
    0.88,
    0.92,
    0.84,
    0.78,
    0.85,
    0.92,
    0.97,
    0.9,
    0.86,
    0.78,
    0.7,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 16.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    final n = _data.length;
    final visibleCount = (progress * n).round().clamp(2, n);

    // Baseline.
    final baseline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = kChipBg;
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      baseline,
    );

    // Visible line — bright cyan, rounded joints.
    final visibleLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF64D2FF); // iOS systemTeal
    for (var i = 0; i < visibleCount - 1; i++) {
      final x1 = padding + (i / (n - 1)) * w;
      final y1 = padding + (1 - _data[i]) * h;
      final x2 = padding + ((i + 1) / (n - 1)) * w;
      final y2 = padding + (1 - _data[i + 1]) * h;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), visibleLine);
    }
    // Dim continuation.
    final dimLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x553A3A3C);
    for (var i = visibleCount - 1; i < n - 1; i++) {
      final x1 = padding + (i / (n - 1)) * w;
      final y1 = padding + (1 - _data[i]) * h;
      final x2 = padding + ((i + 1) / (n - 1)) * w;
      final y2 = padding + (1 - _data[i + 1]) * h;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dimLine);
    }

    // Dots on visible points.
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF64D2FF);
    for (var i = 0; i < visibleCount; i++) {
      final x = padding + (i / (n - 1)) * w;
      final y = padding + (1 - _data[i]) * h;
      canvas.drawCircle(Offset(x, y), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Rounded card with per-corner radii (asymmetric) + stroke.
class _RoundedCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inset = 16.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rrect = RRect.fromLTRBAndCornerRadii(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
      tlRadius: 28,
      trRadius: 28,
      brRadius: 8,
      blRadius: 8,
    );

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = kTileBg;
    canvas.drawRRect(rrect, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF0A84FF);
    canvas.drawRRect(rrect, stroke);

    // Small dot in the bottom-right corner.
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF453A); // iOS systemRed
    canvas.drawCircle(Offset(rect.right - 16, rect.bottom - 16), 6, dot);
  }

  @override
  bool shouldRepaint(_RoundedCardPainter oldDelegate) => false;
}

/// Labelled bar chart — exercises `drawRect` + the `drawText` op.
/// Static data so the painter validates the "no re-encode while static"
/// guarantee. Bottom-aligned bars with bottom-left axis labels and
/// centre-aligned values above each bar.
class _BarChartPainter extends CustomPainter {
  static const _data = <(String, double)>[
    ('Mon', 0.32),
    ('Tue', 0.58),
    ('Wed', 0.41),
    ('Thu', 0.73),
    ('Fri', 0.91),
    ('Sat', 0.66),
    ('Sun', 0.48),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const labelBand = 28.0; // space at the bottom for axis labels
    const valueBand = 22.0; // space at the top for value labels
    const barGap = 10.0;

    final n = _data.length;
    final chartArea = Rect.fromLTRB(
      insetH,
      valueBand,
      size.width - insetH,
      size.height - labelBand,
    );
    final barWidth = (chartArea.width - barGap * (n - 1)) / n;

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF0A84FF); // iOS systemBlue

    for (var i = 0; i < n; i++) {
      final (label, ratio) = _data[i];
      final left = chartArea.left + i * (barWidth + barGap);
      final height = chartArea.height * ratio;
      final top = chartArea.bottom - height;
      canvas.drawRect(
        Rect.fromLTWH(left, top, barWidth, height),
        barPaint,
      );

      // Value above the bar — center-aligned at the bar's mid-x.
      final pct = (ratio * 100).round();
      canvas.drawText(
        '$pct%',
        Offset(left + barWidth / 2, top - 16),
        fontSize: 11,
        color: kTextPrimary,
        fontWeight: 600,
        textAlign: 1, // center
      );

      // Axis label — center-aligned under the bar.
      canvas.drawText(
        label,
        Offset(left + barWidth / 2, chartArea.bottom + 8),
        fontSize: 11,
        color: kTextSecondary,
        textAlign: 1, // center
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) => false;
}

/// Showcase for gradient shaders. Three gradient-filled bars
/// (vertical linear gradient with stops) plus a radial-gradient swatch.
/// Static painter; the gradient stop list is fixed so this also
/// validates the "no re-encode while static" guarantee with shaders
/// present in the wire.
class _GradientShowcasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const topPad = 18.0;
    const bottomPad = 18.0;
    const barGap = 16.0;
    const swatchSize = 140.0;

    // ── Left two-thirds: three gradient bars stacked vertically ──
    final barsArea = Rect.fromLTRB(
      insetH,
      topPad,
      size.width - swatchSize - insetH - barGap,
      size.height - bottomPad,
    );
    final barHeight = (barsArea.height - barGap * 2) / 3;
    final gradients = <List<Color>>[
      [const Color(0xFF0A84FF), const Color(0xFF64D2FF)],
      [const Color(0xFFFF453A), const Color(0xFFFFD60A)],
      [
        const Color(0xFF30D158),
        const Color(0xFF0A84FF),
        const Color(0xFFBF5AF2)
      ],
    ];
    for (var i = 0; i < gradients.length; i++) {
      final top = barsArea.top + i * (barHeight + barGap);
      final barRect = Rect.fromLTWH(
        barsArea.left,
        top,
        barsArea.width,
        barHeight,
      );
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          Offset(barRect.left, barRect.top),
          Offset(barRect.right, barRect.top),
          gradients[i],
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, 10),
        paint,
      );
    }

    // ── Right swatch: radial gradient inside a rounded square ──
    final swatchRect = Rect.fromLTWH(
      size.width - swatchSize - insetH,
      (size.height - swatchSize) / 2,
      swatchSize,
      swatchSize,
    );
    final radialPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.radial(
        swatchRect.center,
        swatchSize / 2,
        const [
          Color(0xFFFFFFFF),
          Color(0xFFFF9F0A),
          Color(0xFFFF453A),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(swatchRect, 16),
      radialPaint,
    );

    // Hairline stroke over the swatch — stays SOLID (gradient strokes
    // are not supported).
    final swatchStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x55FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(swatchRect, 16),
      swatchStroke,
    );
  }

  @override
  bool shouldRepaint(_GradientShowcasePainter oldDelegate) => false;
}

/// Showcase for the `drawParagraph` op — multi-line, wrapped,
/// mixed-style text inside a painter. Three paragraphs side-by-side
/// (left-aligned bold heading + body, centred chart caption with an
/// italic emphasis, right-aligned attribution). Static painter; the
/// paragraph data is fixed so the "no re-encode while static"
/// guarantee is validated here too with paragraph bytes on the wire.
class _ParagraphShowcasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const gap = 12.0;
    final colWidth = (size.width - insetH * 2 - gap * 2) / 3;

    // ── Column 1: left-aligned heading + body ─────────────────────
    final col1 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontFamily: null,
        fontSize: 14,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ))
          ..addText('Native paragraphs.\n')
          ..popStyle()
          // Spacer span — a small zero-content line that creates a
          // visible gap between the heading and the body. Using a
          // separate span (rather than '\n\n') keeps the heading line's
          // natural height predictable across iOS / Android line-metric
          // differences.
          ..pushStyle(const TextStyle(fontSize: 6))
          ..addText('\n')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            height: 1.35,
          ))
          ..addText(
              'Wrapped at a width inside a CustomPainter — no Skia involved. '
              'Each span carries its own color, size, and weight.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col1, const Offset(insetH, 16));

    // ── Column 2: centred caption with italic emphasis ────────────
    final col2 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontFamily: null,
        fontSize: 13,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            height: 1.3,
          ))
          ..addText('Mixed runs — ')
          ..popStyle()
          ..pushStyle(const TextStyle(
            color: Color(0xFFFFD60A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ))
          ..addText('italic + bold')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            height: 1.3,
          ))
          ..addText(' — render in the same paragraph.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col2, Offset(insetH + colWidth + gap, 16));

    // ── Column 3: right-aligned attribution, underlined link ──────
    final col3 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.right,
        fontFamily: null,
        fontSize: 12,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 12,
          ))
          ..addText('Implemented for\n')
          ..popStyle()
          ..pushStyle(const TextStyle(
            color: Color(0xFF0A84FF),
            fontSize: 12,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF0A84FF),
          ))
          ..addText('dartnative\n')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            decoration: TextDecoration.lineThrough,
            decorationColor: kTextSecondary,
          ))
          ..addText('\nStrikethrough Text'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col3, Offset(insetH + (colWidth + gap) * 2, 16));
  }

  @override
  bool shouldRepaint(_ParagraphShowcasePainter oldDelegate) => false;
}

/// Section 7 — visually proves the per-span / per-paragraph parity
/// fields. Three columns:
///   1. Line-height multiplier (paragraph-level `height`).
///   2. Per-span shadows + backgroundColor + letterSpacing.
///   3. Decoration variants (coloured underline / overline / strikethrough).
class _ParagraphParityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const gap = 12.0;
    final colWidth = (size.width - insetH * 2 - gap * 2) / 3;

    // ── Column 1: height multiplier ──────────────────────────────
    // Renders the same body text at three line-height multipliers so the
    // vertical spacing visibly grows top-to-bottom. If `height` isn't
    // honoured, all three blocks would look identical.
    final col1 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 11,
        height: 1.0,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ))
          ..addText('Line-height\n')
          ..popStyle()
          ..pushStyle(const TextStyle(
            color: Color(0xFF30D158),
            fontSize: 11,
            height: 1.0,
          ))
          ..addText('1.0  text with tight line height\n')
          ..popStyle()
          ..pushStyle(const TextStyle(
            color: Color(0xFFFFD60A),
            fontSize: 11,
            height: 1.4,
          ))
          ..addText('1.4  text with airy line height\n')
          ..popStyle()
          ..pushStyle(const TextStyle(
            color: Color(0xFFFF453A),
            fontSize: 11,
            height: 1.8,
          ))
          ..addText('1.8  text with big line height'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col1, const Offset(insetH, 12));

    // ── Column 2: shadows + backgroundColor + letterSpacing ──────
    final col2 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 12,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ))
          ..addText('Shadows + bg + kern\n')
          ..popStyle()
          // Shadow: bright magenta drop shadow with a big offset and
          // large blur — chosen to be visually unmistakable. If the
          // shadow doesn't render, "SHADOW" looks like a plain white
          // word with no glow.
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Color(0xFFFF2DA0),
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ))
          ..addText('SHADOW\n')
          ..popStyle()
          // Background colour swatch behind one word — yellow under
          // black text. Hard to miss.
          ..pushStyle(const TextStyle(
            color: Color(0xFF000000),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            backgroundColor: Color(0xFFFFD60A),
          ))
          ..addText('  highlighted  ')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 11,
          ))
          ..addText('\n')
          ..popStyle()
          // Letter spacing — exaggerated tracking so it can't be
          // confused with normal spacing.
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 14,
            letterSpacing: 5.0,
          ))
          ..addText('S P A C E D'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col2, Offset(insetH + colWidth + gap, 12));

    // ── Column 3: decoration variants ────────────────────────────
    // Larger fonts so the decoration lines + their colours are
    // unambiguous at any screenshot resolution. Note: TextDecoration.
    // overline is not supported on Android (renders as plain text);
    // iOS approximates it via baseline offset. The third
    // row below toggles between the two platforms — on Android it
    // looks like plain text, on iOS it shows a green line above.
    final col3 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 14,
        height: 1.4,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ))
          ..addText('Decorations\n')
          ..popStyle()
          // Underline — line is bright red, text is white.
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFFFF453A),
          ))
          ..addText('underline RED\n')
          ..popStyle()
          // Strikethrough — line is bright yellow, text is white.
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.lineThrough,
            decorationColor: Color(0xFFFFD60A),
          ))
          ..addText('strike YELLOW\n')
          ..popStyle()
          // Overline — iOS shows a green line above; Android currently falls
          // back to plain text (documented limitation).
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.overline,
            decorationColor: Color(0xFF30D158),
          ))
          ..addText('overline GREEN (iOS only)'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col3, Offset(insetH + (colWidth + gap) * 2, 12));
  }

  @override
  bool shouldRepaint(_ParagraphParityPainter oldDelegate) => false;
}

/// Section 8 — paragraph-layout-level features: RTL, justify, maxLines,
/// ellipsis, paragraph-level `height` multiplier.
class _ParagraphLayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const gap = 12.0;
    final colWidth = (size.width - insetH * 2 - gap * 2) / 3;

    // ── Column 1: RTL (Arabic) ───────────────────────────────────
    // RTL paragraphs flip start/end alignment and reverse glyph order.
    final col1 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.start,
        textDirection: TextDirection.rtl,
        fontSize: 14,
        height: 1.3,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ))
          ..addText('RTL\n')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 13,
          ))
          ..addText(
              'مرحبا بالعالم. هذه فقرة قصيرة باللغة العربية لاختبار اتجاه النص.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col1, const Offset(insetH, 12));

    // ── Column 2: Justified ──────────────────────────────────────
    final col2 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.justify,
        fontSize: 12,
        height: 1.2,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ))
          ..addText('Justify\n')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 11,
          ))
          ..addText('Words spread to both edges. iOS honours this everywhere; '
              'Android needs API 26+ for inter-word justification.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col2, Offset(insetH + colWidth + gap, 12));

    // ── Column 3: maxLines + ellipsis ────────────────────────────
    final col3 = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 12,
        maxLines: 3,
        ellipsis: '…',
        height: 1.25,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ))
          ..addText('maxLines: 3 + ellipsis\n')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 11,
          ))
          ..addText('This is a long paragraph that should overflow past three '
              'lines so the truncation kicks in. The fourth and following '
              'lines must NOT render — instead a trailing ellipsis ("…") '
              'appears at the cut-off point on the third line.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: colWidth));

    canvas.drawParagraph(col3, Offset(insetH + (colWidth + gap) * 2, 12));
  }

  @override
  bool shouldRepaint(_ParagraphLayoutPainter oldDelegate) => false;
}

/// Section 9 — paragraph + the metrics returned by the sync-FFI
/// measurement roundtrip. Left half renders a real wrapped paragraph;
/// right half renders the values the painter pulled off
/// `paragraph.height` / `.width` / `.longestLine` / `.lineCount` /
/// `.didExceedMaxLines` / `.minIntrinsicWidth` / `.maxIntrinsicWidth`
/// / `.alphabeticBaseline` / `.ideographicBaseline` AFTER calling
/// `paragraph.layout(...)`.
class _ParagraphMetricsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const gap = 16.0;
    final leftWidth = (size.width - insetH * 2 - gap) * 0.55;
    final rightWidth = size.width - insetH * 2 - gap - leftWidth;
    final rightX = insetH + leftWidth + gap;

    // ── Left: a real wrapped paragraph with mixed styles + maxLines ──
    // Body sized so the heading + 4 wrapped body lines fit, with a
    // deliberate overflow on what would be a 6th line that the
    // `maxLines: 5` + ellipsis truncates — this is what makes
    // `didExceedMaxLines` read `true` in the metrics list at right.
    final body = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 13,
        maxLines: 5,
        ellipsis: '…',
        height: 1.3,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ))
          ..addText('A paragraph that wraps.\n')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 12,
            height: 1.0,
          ))
          ..addText('Native shaping measures it. Values show at right. '
              'Truncated by maxLines: 5, '
              'so didExceedMaxLines reads true. '
              'but text still wraps and ellipsizes as expected.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: leftWidth));

    canvas.drawParagraph(body, const Offset(insetH, 12));

    // ── Right: the measured metrics as a label grid ────────────────
    String f(num v) => v.toStringAsFixed(1);
    final lines = <(String, String)>[
      ('width', f(body.width)),
      ('height', f(body.height)),
      ('lineCount', '${body.lineCount}'),
      ('longestLine', f(body.longestLine)),
      ('didExceedMaxLines', body.didExceedMaxLines ? 'true' : 'false'),
      ('minIntrinsicWidth', f(body.minIntrinsicWidth)),
      ('maxIntrinsicWidth', f(body.maxIntrinsicWidth)),
      ('alphabeticBaseline', f(body.alphabeticBaseline)),
      ('ideographicBaseline', f(body.ideographicBaseline)),
    ];

    // Heading on the right column.
    final heading = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: 12),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ))
          ..addText('measured metrics'))
        .build()
      ..layout(ui.ParagraphConstraints(width: rightWidth));
    canvas.drawParagraph(heading, Offset(rightX, 12));

    // Each metric on its own row. Use drawText (single-line op) for the
    // label + value so we can right-align numerics cleanly without
    // building 9 separate paragraphs.
    var y = 30.0;
    const rowHeight = 16.0;
    for (final (label, value) in lines) {
      canvas.drawText(
        label,
        Offset(rightX, y),
        fontSize: 10,
        color: kTextSecondary,
      );
      canvas.drawText(
        value,
        Offset(rightX + rightWidth, y),
        fontSize: 10,
        color: const Color(0xFF30D158),
        fontWeight: 600,
        textAlign: 2, // right
      );
      y += rowHeight;
    }
  }

  @override
  bool shouldRepaint(_ParagraphMetricsPainter oldDelegate) => false;
}

/// Section 10 — per-line bounds visualisation.
/// Renders a wrapped paragraph + a translucent box around every line
/// using the metrics returned by `paragraph.getLineMetrics()`. If the
/// per-line FFI returns numbers that agree with what the renderer
/// actually drew, each box should hug its line exactly (top edge at
/// `baseline - ascent`, bottom edge at `baseline + descent`, left at
/// `left`, width at `width`).
class _ParagraphLineMetricsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    final paragraphWidth =
        size.width - insetH * 2 - 120; // leave room for the legend
    const originY = 14.0;

    final paragraph = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 13,
        height: 1.35,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ))
          ..addText('Per-line bounds.\n')
          ..popStyle()
          ..pushStyle(TextStyle(
            color: kTextSecondary,
            fontSize: 12,
          ))
          ..addText('Boxes drawn straight from getLineMetrics(): top edge at '
              'baseline−ascent, height = ascent + descent. '
              'They should hug each rendered line.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: paragraphWidth));

    // Draw the line bounds BEFORE drawing the paragraph itself so the
    // text renders on top of the boxes.
    final lineMetrics = paragraph.getLineMetrics();
    final boxPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x330A84FF); // translucent iOS blue
    final boxStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF0A84FF);
    for (final lm in lineMetrics) {
      final top = originY + lm.baseline - lm.ascent;
      final bottom = originY + lm.baseline + lm.descent;
      final rect = Rect.fromLTRB(
        insetH + lm.left,
        top,
        insetH + lm.left + lm.width,
        bottom,
      );
      canvas.drawRect(rect, boxPaint);
      canvas.drawRect(rect, boxStroke);
    }
    canvas.drawParagraph(paragraph, const Offset(insetH, originY));

    // ── Right-side legend: per-line summary table ─────────────────
    final legendX = insetH + paragraphWidth + 8;
    canvas.drawText(
      'line metrics',
      Offset(legendX, originY),
      fontSize: 10,
      color: kTextPrimary,
      fontWeight: 700,
    );
    var y = originY + 14;
    for (final lm in lineMetrics) {
      // Compact per-line row: "L0 w=NNN h=NN"
      canvas.drawText(
        'L${lm.lineNumber}',
        Offset(legendX, y),
        fontSize: 9,
        color: kTextSecondary,
      );
      canvas.drawText(
        'w=${lm.width.toStringAsFixed(0)} h=${(lm.ascent + lm.descent).toStringAsFixed(0)}'
        '${lm.hardBreak ? "  ⏎" : ""}',
        Offset(legendX + 20, y),
        fontSize: 9,
        color: const Color(0xFF30D158),
      );
      y += 12;
    }
  }

  @override
  bool shouldRepaint(_ParagraphLineMetricsPainter oldDelegate) => false;
}

/// Section 11 — paragraph hit testing.
///
/// Renders a paragraph + a yellow highlight underlying a fixed text
/// range (using `getBoxesForRange`), and on every tap calls
/// `getPositionForOffset(probe)` on the *real* tap coordinate —
/// then renders both the probe (red dot) and the resolved text
/// position (blue caret + label).
///
/// Real tap coords work because both platforms report view-local
/// logical pixels, which the GestureDetector forwards via
/// `onTapUp.localPosition`; the painter subtracts its inset to land in
/// paragraph-local space.
class _ParagraphHitTestPainter extends CustomPainter {
  /// Most-recent tap point in *paragraph-local* coords (already with
  /// the painter inset subtracted off). `null` until the user has
  /// tapped, in which case the painter renders an instructional
  /// "tap anywhere" hint instead of dot+caret.
  final Offset? probe;

  /// Distance from the canvas's left edge to the paragraph's left
  /// edge (matches the `insetH` used in `paint`). Exposed so the
  /// state widget can convert a view-local tap into paragraph-local
  /// coords before handing them to the painter.
  static const double paragraphInsetX = 16.0;

  /// Distance from the canvas's top edge to the paragraph's first
  /// baseline-origin (matches the `originY` used in `paint`).
  static const double paragraphInsetY = 14.0;

  _ParagraphHitTestPainter({this.probe});

  // The text we paint. Indices into this string are what
  // `getBoxesForRange` / `getPositionForOffset` return / accept.
  // Highlight covers 'Paragraph' (0..9) for an instant visual landmark.
  static const _bodyText =
      'Paragraph hit testing. Tap anywhere inside this canvas — the '
      'red dot lands where your finger went down and the blue caret '
      'shows where the engine resolves that pixel to inside the text.';

  @override
  void paint(Canvas canvas, Size size) {
    const insetH = paragraphInsetX;
    const originY = paragraphInsetY;
    final paragraphWidth = size.width - insetH * 2;

    final paragraph = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 14,
        height: 1.25,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 14,
          ))
          ..addText(_bodyText))
        .build()
      ..layout(ui.ParagraphConstraints(width: paragraphWidth));

    // Highlight the word containing the resolved char on each tap.
    // Painted BEFORE drawParagraph so the glyphs sit on top of the
    // highlight rather than behind it. Computed only when a tap has
    // already landed (probe != null); the empty-state branch lower
    // down skips the highlight entirely.
    if (probe != null) {
      final tapPosition = paragraph.getPositionForOffset(probe!);
      final wordRange = _wordRangeAt(_bodyText, tapPosition.offset);
      if (wordRange != null) {
        final wordBoxes =
            paragraph.getBoxesForRange(wordRange.$1, wordRange.$2);
        if (wordBoxes.isNotEmpty) {
          final highlightPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = const Color(0x66FFD60A); // translucent iOS yellow
          for (final box in wordBoxes) {
            canvas.drawRect(
              Rect.fromLTRB(
                insetH + box.left,
                originY + box.top,
                insetH + box.right,
                originY + box.bottom,
              ),
              highlightPaint,
            );
          }
        }
      }
    }

    canvas.drawParagraph(paragraph, const Offset(insetH, originY));

    // ── Bottom-of-canvas labels (legend + result/hint) ───────────
    // Pulled forward so they always render even before the user
    // taps for the first time. A 10-px bottom margin keeps the
    // result row from kissing the container's bottom edge.
    final legendY = size.height - 46;
    final resultY = size.height - 24;

    // No tap yet → render only the placeholder hint and the legend
    // chrome. Returning here keeps the paint pure (no stale state to
    // print, no caret to draw).
    final probeLocal = probe;
    if (probeLocal == null) {
      _drawHitTestLegend(canvas, size, legendY);
      canvas.drawText(
        'tap anywhere inside this box',
        Offset(insetH, resultY),
        fontSize: 11,
        color: kTextSecondary,
      );
      return;
    }

    final probePoint = probeLocal;
    final position = paragraph.getPositionForOffset(probePoint);

    // Probe point as a red dot — translate from paragraph-local to
    // stage-local for drawing.
    final probeStage = Offset(insetH + probePoint.dx, originY + probePoint.dy);
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF453A);
    canvas.drawCircle(probeStage, 4, dot);

    // Caret at the resolved text position. Use getBoxesForRange to
    // find the exact glyph box of the resolved offset; fall back to
    // the last char's right edge when the offset is past the text
    // (e.g. tapping into the blank space after the final ".").
    var caretX = 0.0;
    var caretTop = 0.0;
    var caretBottom = 0.0;
    final caretBoxes =
        paragraph.getBoxesForRange(position.offset, position.offset + 1);
    if (caretBoxes.isNotEmpty) {
      final cb = caretBoxes.first;
      final pastEnd = position.offset >= _bodyText.length;
      caretX = pastEnd ? cb.right : cb.left;
      caretTop = cb.top;
      caretBottom = cb.bottom;
    } else if (position.offset >= _bodyText.length) {
      final lastBoxes =
          paragraph.getBoxesForRange(_bodyText.length - 1, _bodyText.length);
      if (lastBoxes.isNotEmpty) {
        final cb = lastBoxes.first;
        caretX = cb.right;
        caretTop = cb.top;
        caretBottom = cb.bottom;
      }
    }
    if (caretBottom > caretTop) {
      final caretPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFF0A84FF);
      canvas.drawLine(
        Offset(insetH + caretX, originY + caretTop),
        Offset(insetH + caretX, originY + caretBottom),
        caretPaint,
      );
    }

    // ── Bottom-of-canvas label area ──────────────────────────────
    // Two stacked rows so the legend and result don't collide. The
    // legend row above carries miniature versions of the two markers
    // next to their meaning labels, the result row below carries the
    // numeric outcome of the current probe.
    _drawHitTestLegend(canvas, size, legendY);

    // Result row — probe (x, y) + offset + affinity, right-aligned.
    canvas.drawText(
      'tap (${probePoint.dx.toStringAsFixed(0)}, '
      '${probePoint.dy.toStringAsFixed(0)})  '
      'offset: ${position.offset}  '
      'affinity: ${position.affinity.name}',
      Offset(size.width - insetH, resultY),
      fontSize: 11,
      color: const Color(0xFF0A84FF),
      fontWeight: 600,
      textAlign: 2, // right
    );

    // "tap again" hint anchored bottom-left of the result row.
    canvas.drawText(
      'tap to re-probe',
      Offset(insetH, resultY),
      fontSize: 11,
      color: kTextSecondary,
    );
  }

  /// Renders the legend row (red-dot + "probe (input)", blue-caret +
  /// "caret (resolved)") at the given `y`. Shared by the pre-tap
  /// placeholder branch and the normal post-tap branch.
  void _drawHitTestLegend(Canvas canvas, Size size, double legendY) {
    const insetH = paragraphInsetX;
    final legendDot = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF453A);
    canvas.drawCircle(Offset(insetH + 4, legendY + 4), 3.5, legendDot);
    canvas.drawText(
      'probe (input)',
      Offset(insetH + 14, legendY),
      fontSize: 11,
      color: kTextSecondary,
      fontWeight: 500,
    );

    const legendBlueX = 130.0;
    final legendCaret = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF0A84FF);
    canvas.drawLine(
      Offset(insetH + legendBlueX, legendY - 1),
      Offset(insetH + legendBlueX, legendY + 11),
      legendCaret,
    );
    canvas.drawText(
      'caret (resolved)',
      Offset(insetH + legendBlueX + 6, legendY),
      fontSize: 11,
      color: kTextSecondary,
      fontWeight: 500,
    );
  }

  /// Returns the half-open `(start, end)` character range of the word
  /// that contains [offset] in [text]. A "word" is a contiguous run
  /// of non-whitespace characters; punctuation stays with the word
  /// (so a tap on the `.` of "right." highlights `right.`). Returns
  /// `null` when [offset] lands on a whitespace character or sits
  /// past the end of the text — in those cases there's no word to
  /// highlight and the painter skips the yellow rect entirely.
  static (int, int)? _wordRangeAt(String text, int offset) {
    if (text.isEmpty) return null;
    // Clamp past-end taps onto the last char so the past-end fallback
    // still produces a highlight at the trailing word.
    final clamped = offset.clamp(0, text.length - 1);
    if (_isWhitespace(text.codeUnitAt(clamped))) return null;
    var start = clamped;
    while (start > 0 && !_isWhitespace(text.codeUnitAt(start - 1))) {
      start--;
    }
    var end = clamped + 1;
    while (end < text.length && !_isWhitespace(text.codeUnitAt(end))) {
      end++;
    }
    return (start, end);
  }

  /// ASCII whitespace check used by [_wordRangeAt]. The demo text is
  /// English-only so we don't bother with Unicode whitespace classes.
  static bool _isWhitespace(int codeUnit) =>
      codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D;

  @override
  bool shouldRepaint(_ParagraphHitTestPainter oldDelegate) =>
      oldDelegate.probe != probe;
}

/// Section 12 — `StrutStyle.forceStrutHeight` demo.
///
/// What this proves: when `forceStrutHeight: true`, every rendered
/// line uses the same height regardless of which glyphs it contains
/// — which is the property a tabular layout needs. We render the
/// same 4-row "table" twice, side by side, with each row's actual
/// height printed in the right margin. A header at the top of each
/// column reports `rows match: YES/NO` based on whether all four
/// line heights are equal (a 2-px tolerance absorbs Android's
/// trailing-line-spacing trim on the last line).
///
/// Pass = "rows match: YES" on the right side and "rows match: NO"
/// on the left. Fail = anything else.
class _StrutDemoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 12.0;
    const originY = 16.0;
    final halfWidth = (size.width - insetH * 3) / 2;

    _drawSample(
      canvas,
      origin: const Offset(insetH, originY),
      width: halfWidth,
      strutStyle: null,
      headerLabel: 'no strut',
    );

    _drawSample(
      canvas,
      origin: Offset(insetH * 2 + halfWidth, originY),
      width: halfWidth,
      strutStyle: const StrutStyle(
        fontSize: 14,
        height: 2.5,
        forceStrutHeight: true,
      ),
      headerLabel: 'forceStrutHeight: true',
    );
  }

  void _drawSample(
    Canvas canvas, {
    required Offset origin,
    required double width,
    required StrutStyle? strutStyle,
    required String headerLabel,
  }) {
    final paragraph = (ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 14,
        strutStyle: strutStyle,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 14,
          ))
          ..addText('HELLO\n'
              'normal text\n'
              '🚀 with emoji\n'
              'check strut.'))
        .build()
      ..layout(ui.ParagraphConstraints(width: width));

    final metrics = paragraph.getLineMetrics();

    // Pass criterion: line heights all equal within a 2-px tolerance
    // (Android's setLineSpacing(2f, …) trims 2 px from the final
    // line — known artifact, not a strut failure).
    final allMatch = metrics.length >= 2 &&
        metrics.skip(1).every(
              (m) => (m.height - metrics.first.height).abs() <= 2.0,
            );

    // Header — sits on top of the table, summarises the result.
    final headerColor = allMatch
        ? const Color(0xFF34C759) // iOS green
        : const Color(0xFFFF9500); // iOS orange — not strictly "fail" on the
    // left column (it's expected to vary),
    // but a colour distinct from green so the
    // contrast is obvious.
    canvas.drawText(
      'rows match: ${allMatch ? 'YES' : 'NO'}',
      Offset(origin.dx, origin.dy),
      fontSize: 11,
      color: headerColor,
      fontWeight: 700,
    );
    canvas.drawText(
      headerLabel,
      Offset(origin.dx, origin.dy + 14),
      fontSize: 10,
      color: kTextSecondary,
    );

    // Offset the table down so it sits below the header.
    final tableTop = origin.dy + 32;

    // Per-line translucent background + glyphs + height annotation.
    final lineRect = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x33FFD60A);
    for (final m in metrics) {
      final lineTop = m.baseline - (m.height - m.descent);
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx,
          tableTop + lineTop,
          m.width.clamp(0.0, width * 0.7),
          m.height,
        ),
        lineRect,
      );
    }

    canvas.drawParagraph(paragraph, Offset(origin.dx, tableTop));

    // Per-line height annotation in the right margin.
    for (final m in metrics) {
      final yMid = tableTop + m.baseline - m.ascent + m.height * 0.5 - 6;
      canvas.drawText(
        '${m.height.toStringAsFixed(0)} px',
        Offset(origin.dx + width, yMid),
        fontSize: 10,
        color: kTextSecondary,
        textAlign: 2, // right-aligned
      );
    }
  }

  @override
  bool shouldRepaint(_StrutDemoPainter oldDelegate) => false;
}

/// Section 13 — `TextStyle.foreground` demo (full Paint override
/// for glyph fill). Three rows show three modes:
///
///   1. Plain   — no foreground, glyphs fill with `TextStyle.color`.
///   2. Outline — `Paint(style: stroke, strokeWidth: 1.5)` produces
///                hollow-letter outlines on both platforms.
///   3. Gradient — `Paint..shader = Gradient.linear(...)` fills the
///                glyphs with a rainbow sweep on Android (TextPaint
///                honours the shader); on iOS the Paint's colour is
///                used instead.
class _ForegroundPaintDemoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    final paragraph = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 32,
        height: 1.4,
      ),
    )
          // Row 1: plain solid colour.
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ))
          ..addText('Plain text\n')
          ..popStyle()
          // Row 2: stroked outline via foreground Paint.
          ..pushStyle(TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = const Color(0xFFFF453A),
          ))
          ..addText('Outline\n')
          ..popStyle()
          // Row 3: gradient fill via foreground Paint + shader.
          ..pushStyle(TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = ui.Gradient.linear(
                const Offset(0, 0),
                const Offset(260, 0),
                const [
                  Color(0xFFFF453A), // red
                  Color(0xFFFF9F0A), // orange
                  Color(0xFFFFD60A), // yellow
                  Color(0xFF30D158), // green
                  Color(0xFF0A84FF), // blue
                  Color(0xFFBF5AF2), // purple
                ],
              ),
          ))
          ..addText('Gradient'))
        .build()
      ..layout(ui.ParagraphConstraints(width: size.width - insetH * 2));

    canvas.drawParagraph(paragraph, const Offset(insetH, 14));
  }

  @override
  bool shouldRepaint(_ForegroundPaintDemoPainter oldDelegate) => false;
}

/// Section 14 — `drawImage` / `drawImageRect` demo. Renders the same
/// bitmap (pre-cached by [_CustomPaintDemoState._drawImageDemoPrecache])
/// twice:
///
///   • LEFT  — `canvas.drawImage(...)` at natural pixel size.
///   • RIGHT — `canvas.drawImageRect(src, dst, ...)` blowing up the
///             bottom-right quadrant of the same bitmap by narrowing
///             the source rect.
///
/// While the bitmap is still loading, [ready] is false and the
/// painter renders a placeholder rectangle so callers can see the
/// canvas wasn't lost on first frame.
class _DrawImageDemoPainter extends CustomPainter {
  final bool ready;
  _DrawImageDemoPainter({required this.ready});

  static const _url = _CustomPaintDemoState._drawImageDemoUrl;

  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const insetV = 14.0;
    final colWidth = (size.width - insetH * 3) / 2;

    if (!ready) {
      // Placeholder while precacheImage(...) is in flight.
      final phPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = kRowBg;
      canvas.drawRect(
        Rect.fromLTWH(
            insetH, insetV, size.width - insetH * 2, size.height - insetV * 2),
        phPaint,
      );
      canvas.drawText(
        'loading image…',
        Offset(insetH + 12, insetV + 16),
        fontSize: 13,
        color: kTextSecondary,
      );
      return;
    }

    final image = CanvasImage.network(_url, width: 220, height: 140);

    // ── LEFT: drawImage at natural size ──────────────────────────
    canvas.drawImage(
      image,
      const Offset(insetH, insetV),
      Paint(),
    );
    canvas.drawText(
      'drawImage',
      Offset(insetH, insetV + 148),
      fontSize: 11,
      color: kTextSecondary,
    );

    // Red rectangle on top of the left image showing which region
    // of the source bitmap is being passed to drawImageRect on the
    // right — gives the dev a direct visual cross-reference.
    const srcW = 110.0;
    const srcH = 70.0;
    const srcLeft = 110.0; // right-half of 220-wide source
    const srcTop = 70.0; // bottom-half of 140-tall source
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFFF453A);
    canvas.drawRect(
      Rect.fromLTWH(insetH + srcLeft, insetV + srcTop, srcW, srcH),
      highlightPaint,
    );

    // ── RIGHT: drawImageRect zoomed crop of the same bitmap ──────
    // Same red outline traces the dst rect on the right so the dev
    // can match up "this red region on the left" with "this red
    // outlined block on the right".
    final rightLeft = insetH * 2 + colWidth;
    final dstW = colWidth;
    final dstH = colWidth * srcH / srcW; // preserve aspect (110:70)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(srcLeft, srcTop, srcW, srcH),
      Rect.fromLTWH(rightLeft, insetV, dstW, dstH),
      Paint(),
    );
    canvas.drawRect(
      Rect.fromLTWH(rightLeft, insetV, dstW, dstH),
      highlightPaint,
    );
    canvas.drawText(
      'drawImageRect (zoomed crop)',
      Offset(rightLeft, insetV + 148),
      fontSize: 11,
      color: kTextSecondary,
    );
  }

  @override
  bool shouldRepaint(_DrawImageDemoPainter oldDelegate) =>
      oldDelegate.ready != ready;
}

/// Section 15 — `TextStyle.fontVariations` (variable-font axis) +
/// `TextStyle.fontFeatures` demo. Three side-by-side columns
/// rendering the same word at three weights so the progressive
/// thickness is visually unambiguous.
///
/// Each column applies BOTH `fontWeight: FontWeight.wN` and
/// `fontVariations: [FontVariation.weight(N)]`. The variable axis
/// gives smooth interpolation on variable fonts (SF Pro on iOS, Roboto
/// Flex on Android 13+ with the variable font installed); the
/// discrete `fontWeight` is the fallback for fixed-weight families
/// — so the user always sees a heavier glyph between columns.
class _FontFeaturesDemoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const insetV = 14.0;
    final colWidth = (size.width - insetH * 4) / 3;

    _drawColumn(
      canvas,
      origin: const Offset(insetH, insetV),
      width: colWidth,
      label: 'wght 400',
      sub: '(regular)',
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        fontVariations: [FontVariation.weight(400)],
      ),
    );
    _drawColumn(
      canvas,
      origin: Offset(insetH * 2 + colWidth, insetV),
      width: colWidth,
      label: 'wght 700',
      sub: '(bold)',
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        fontVariations: [FontVariation.weight(700)],
      ),
    );
    _drawColumn(
      canvas,
      origin: Offset(insetH * 3 + colWidth * 2, insetV),
      width: colWidth,
      label: 'wght 900',
      sub: '(black)',
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        fontVariations: [FontVariation.weight(900)],
      ),
    );
  }

  void _drawColumn(
    Canvas canvas, {
    required Offset origin,
    required double width,
    required String label,
    required String sub,
    required TextStyle style,
  }) {
    canvas.drawText(
      label,
      Offset(origin.dx, origin.dy),
      fontSize: 12,
      color: const Color(0xFF0A84FF),
      fontWeight: 700,
    );
    canvas.drawText(
      sub,
      Offset(origin.dx, origin.dy + 14),
      fontSize: 10,
      color: kTextSecondary,
    );

    // Word with a mix of round + straight glyphs so weight changes
    // read clearly. "Aa" shows uppercase stem + lowercase counter
    // diff well across weights.
    final paragraph = (ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 36,
        height: 1.1,
      ),
    )
          ..pushStyle(style)
          ..addText('Aa'))
        .build()
      ..layout(ui.ParagraphConstraints(width: width));

    canvas.drawParagraph(paragraph, Offset(origin.dx, origin.dy + 32));
  }

  @override
  bool shouldRepaint(_FontFeaturesDemoPainter oldDelegate) => false;
}

/// Demo for `ParagraphStyle.leadingDistribution`. Same
/// text, same `height: 2.5` on both sides; only the leading
/// distribution differs. Yellow rectangles trace each line's box
/// (returned by `getLineMetrics`) so the reader can see WHERE in
/// the box the glyphs sit:
///
///   • LEFT (proportional) — glyphs sit toward the top/bottom of
///     the row by the font's natural ratio (Android pushes them
///     down; iOS slightly upward).
///   • RIGHT (even) — glyphs sit visibly centered inside the row.
class _LeadingDistributionDemoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const insetH = 16.0;
    const insetV = 14.0;
    final colWidth = (size.width - insetH * 3) / 2;

    _drawColumn(
      canvas,
      origin: const Offset(insetH, insetV),
      width: colWidth,
      label: 'proportional',
      distribution: TextLeadingDistribution.proportional,
    );
    _drawColumn(
      canvas,
      origin: Offset(insetH * 2 + colWidth, insetV),
      width: colWidth,
      label: 'even',
      distribution: TextLeadingDistribution.even,
    );
  }

  void _drawColumn(
    Canvas canvas, {
    required Offset origin,
    required double width,
    required String label,
    required TextLeadingDistribution distribution,
  }) {
    canvas.drawText(
      label,
      Offset(origin.dx, origin.dy),
      fontSize: 11,
      color: const Color(0xFF0A84FF),
      fontWeight: 700,
    );

    // Multi-line so the height multiplier reliably inflates rows
    // on Android too (setLineSpacing affects inter-line gaps, not
    // single-line height). `Ag` has both an ascender and a
    // descender so the "centered" claim has full glyph bounds to
    // align against.
    final paragraph = (ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 22,
        height: 2.5,
        leadingDistribution: distribution,
      ),
    )
          ..pushStyle(TextStyle(
            color: kTextPrimary,
            fontSize: 22,
          ))
          ..addText('Ag\nBd'))
        .build()
      ..layout(ui.ParagraphConstraints(width: width));

    final paragraphTop = origin.dy + 18;
    final metrics = paragraph.getLineMetrics();

    // Two distinctly-coloured row backgrounds + red outlines so
    // the reader can count individual lines. A purple line marks
    // each baseline (where glyphs anchor) so the diff between
    // proportional and even is unambiguous.
    final rowTint = [
      const Color(0x33FFD60A), // yellow (line 0)
      const Color(0x3334C759), // green  (line 1)
    ];
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFF453A); // red — line bounds
    final baselinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFBF5AF2); // purple — baseline
    for (var i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final lineTop = m.baseline - (m.height - m.descent);
      final rect =
          Rect.fromLTWH(origin.dx, paragraphTop + lineTop, width, m.height);
      canvas.drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.fill
            ..color = rowTint[i % 2]);
      canvas.drawRect(rect, outline);
      canvas.drawLine(
        Offset(rect.left, paragraphTop + m.baseline),
        Offset(rect.right, paragraphTop + m.baseline),
        baselinePaint,
      );
    }

    canvas.drawParagraph(paragraph, Offset(origin.dx, paragraphTop));
  }

  @override
  bool shouldRepaint(_LeadingDistributionDemoPainter oldDelegate) => false;
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

  /// Optional fixed height — defaults to the 220-px canvas every
  /// other section uses. Override when the section's painter
  /// needs less vertical room.
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
