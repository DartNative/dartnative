/// Native Text Rendering demo — three-block comparison.
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';
import 'home/demo_ui.dart';

const _kSampleText = 'She said hello 🎉🎉🎉 and waved goodbye 🌙 '
    'The concert was wild 🎸🔥 totally loved it 😍 '
    'We should do this again sometime soon';

String get _nativeLabel => Platform.isIOS
    ? 'Native: UITextView / UILabel (CoreText)'
    : 'TextView / Span';

class TextRenderingDemo extends StatelessWidget {
  const TextRenderingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    dev.log('[TextRenderingDemo] build() called');
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Native Text Rendering',
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
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 32,
            bottom: 32,
          ),
          children: [
            // ── Block 1: Native text (reference) ───────────────────────────
            _TextBlock(
              child: Text(
                _kSampleText,
                selectable: true,
                style: TextStyle(color: kTextPrimary, fontSize: 17),
              ),
            ),
            _Caption('$_nativeLabel — used as reference.'),

            const SizedBox(height: 28),

            // ── Block 2: dartnative Text ──────────────────────────────────
            _TextBlock(
              child: Text(
                _kSampleText,
                selectable: true,
                style: TextStyle(color: kTextPrimary, fontSize: 17),
              ),
            ),
            _Caption(
              'DartNative: text is pixel-perfect native — '
              'identical look and feel to the platform text stack. '
              'Text renders as UILabel (iOS) / TextView (Android); '
              'selectable: true swaps in a read-only UITextView / '
              'EditText (read-only) so long-press select & copy works on '
              'BOTH platforms. Keep plain Text when selection is not needed.',
            ),

            const SizedBox(height: 28),

            // ── Block 3: Skia bare-tier text (dn_canvas_draw_text) ────────
            // Both iOS and Android now draw via CanvasSurface + Skia bridge
            // (Graphite/Metal on iOS, Graphite/Vulkan on Android).
            CanvasSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kTileBg,
                borderRadius: BorderRadius.circular(14),
              ),
              painter: SkiaTextPainter(_kSampleText, 17),
            ),
            _Caption(
              'Flutter Impeller/Skia-rendered text engine: it fails to '
              "match the platform's native output: weights, "
              'metrics and spacing drift away from the OS text stack. '
              'Emoji are also bundled: '
              'Flutter can only resolve to Apple Color Emoji on iOS '
              'and Noto Color Emoji on Android, '
              'while DartNative uses whatever emoji pack the '
              'user has set on the device — Apple Color Emoji, '
              'OEM emoji set on Android (Samsung One UI, MIUI, Pixel), '
              'or custom emoji packs from the Play Store. '
              'Selection is alien too: Flutter draws its own selection '
              'handles, toolbar and magnifier lens instead of the '
              "platform's — close, but never the real look and feel — "
              'while DartNative text selects with the actual '
              'system UI.',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    dev.log('[_TextBlock] build() called');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kTileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: TextStyle(
          color: kTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}

// ── SkiaTextPainter ───────────────────────────────────────────────────────────

/// Renders [text] on a white CanvasSurface using Skia's bare-tier
/// dn_canvas_draw_text (SkFont default, no CoreText shaping).
///
/// Intentionally compared against blocks 1 & 2 to demonstrate the font
/// and metric differences between Skia and the platform text stack.
class SkiaTextPainter extends CustomPainter {
  final String text;
  final double fontSize;
  final Color color;

  SkiaTextPainter(this.text, this.fontSize) : color = kTextPrimary;

  @override
  double? preferredHeight(double availableWidth) {
    // Ask Skia to shape the text with the same pipeline that paint() uses
    // and report the actual rendered height. This is pixel-accurate — no
    // need to guess line-height multipliers or emoji width factors.
    return SimpleParagraph(text, fontSize, color, availableWidth)
        .measure()
        .height;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas is pre-translated by CanvasSurface padding; size is the content area.
    // Background and clip are handled by CanvasSurface decoration — draw only text.
    canvas.drawParagraph(
      SimpleParagraph(text, fontSize, color, size.width),
      Offset.zero,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
