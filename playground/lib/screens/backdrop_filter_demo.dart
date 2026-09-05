/// BackdropFilter / ImageFiltered demo — two clearly-distinct effects, each
/// in its own example with its own slider so it's immediately obvious which
/// thing each filter blurs.
///
///   Example 1 — ImageFiltered (the "blur the text" case)
///     A text label overlaid on the photo. As sigma rises, ONLY THE TEXT
///     becomes blurry. The photo behind stays sharp. Use this when you
///     want a frosted / soft-focus appearance on the foreground itself.
///
///   Example 2 — BackdropFilter (the "blur what's behind a shape" case)
///     A circular shape placed on the photo. As sigma rises, the PHOTO
///     PORTION INSIDE THE CIRCLE blurs; the circle's own outline stays
///     sharp, and the photo OUTSIDE the circle stays sharp. Use this
///     when you want frosted-glass overlays revealing blurred backdrop.
///
/// Per platform (current status):
///   - iOS BackdropFilter — works (UIVisualEffectView).
///   - iOS ImageFiltered  — works (DNImageFilteredView: snapshot via
///     UIGraphicsImageRenderer + layer.render(in:), CIGaussianBlur on
///     the snapshot, presented on a UIImageView overlay).
///   - Android API 31+ — both work (BackdropFilter via DNBackdropFilterView
///     two-pass RenderNode pipeline; ImageFiltered via setRenderEffect
///     on the view).
///   - Android < 31 — both degrade to passthrough (no RenderEffect).
library;

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

// Sigma values shown in the demo. dartnative's Slider on Android ignores
// custom min/max and returns 0..1; we scale slider value × _maxSigma at the
// usage site. Keeping the slider at its default 0..1 range avoids the
// "thumb stuck at 0 even when value isn't" rendering glitch in the
// underlying SeekBar binding — slider value defaults to 0, so thumb starts
// at the left visually and matches the displayed sigma (= 0).
const double _maxSigma = 30.0;

class BackdropFilterDemo extends StatefulWidget {
  const BackdropFilterDemo({super.key});

  @override
  State<BackdropFilterDemo> createState() => _BackdropFilterDemoState();
}

class _BackdropFilterDemoState extends State<BackdropFilterDemo> {
  double _imageFilteredSlider = 0.0; // 0..1 → scaled to 0..30 sigma
  double _backdropFilterSlider = 0.0;

  double get _imageSigma => _imageFilteredSlider * _maxSigma;
  double get _backdropSigma => _backdropFilterSlider * _maxSigma;

  static const String _photoAsset = 'assets/backdrop_filter_sample.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Backdrop / Image filter',
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

            // ── Section 1: ImageFiltered (blur the text, not the photo) ─────
            const _SectionTitle('1.  ImageFiltered — blurs the TEXT'),
            const _SectionBody(
              'The photo stays sharp. Only the text on top of it gets '
              'blurred as you drag the slider. Use this for frosted text '
              'or soft icons.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(_photoAsset, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: _imageSigma,
                          sigmaY: _imageSigma,
                        ),
                        child: const Text(
                          'Frosted text',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SigmaSlider(
              label: 'Blur sigma',
              value: _imageFilteredSlider,
              sigma: _imageSigma,
              onChanged: (v) => setState(() => _imageFilteredSlider = v),
            ),

            const SizedBox(height: 32),

            // ── Section 2: BackdropFilter (blur the photo inside a circle) ──
            const _SectionTitle('2.  BackdropFilter — blurs the PHOTO'),
            const _SectionBody(
              'A circular region in the middle of the photo. The photo '
              'INSIDE the circle blurs as sigma rises; the photo outside '
              'stays sharp. Use this for frosted-glass overlays.',
            ),
            const SizedBox(height: 10),
            _Stage(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(_photoAsset, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: ClipOval(
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: _backdropSigma,
                              sigmaY: _backdropSigma,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0x33FFFFFF),
                                border: Border.all(
                                  color: const Color(0xFFFFFFFF),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SigmaSlider(
              label: 'Blur sigma',
              value: _backdropFilterSlider,
              sigma: _backdropSigma,
              onChanged: (v) => setState(() => _backdropFilterSlider = v),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No Skia involved. iOS BackdropFilter uses UIVisualEffectView; '
                'iOS ImageFiltered uses CIGaussianBlur on a cached snapshot. '
                'Android (API 31+) uses a two-pass RenderNode pipeline for '
                'BackdropFilter and direct setRenderEffect for ImageFiltered.',
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

/// Sigma slider + label, packaged so each example can have its own
/// independent control without duplicating layout boilerplate.
class _SigmaSlider extends StatelessWidget {
  final String label;
  final double value; // raw slider 0..1
  final double sigma; // display sigma (already scaled)
  final ValueChanged<double> onChanged;

  const _SigmaSlider({
    required this.label,
    required this.value,
    required this.sigma,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${sigma.toStringAsFixed(1)}',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Extra breathing room between the numeric label and the slider
          // track so the value is comfortably readable.
          const SizedBox(height: 14),
          Slider(
            value: value,
            min: 0,
            max: 1,
            activeColor: const Color(0xFF0A84FF),
            inactiveColor: kChipBg,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

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
  const _Stage({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: kRowBg,
      ),
      child: child,
    );
  }
}
