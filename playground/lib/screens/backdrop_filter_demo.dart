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

class BackdropFilterDemo extends StatelessWidget {
  const BackdropFilterDemo({super.key});

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
              height: isIOS26 ? 8 : 12,
            ),

            // Each example owns its own State so dragging one slider never
            // rebuilds or re-snapshots the other filter on the main thread.
            const _ImageFilteredSection(),
            const SizedBox(height: 32),
            const _BackdropFilterSection(),
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

const String _kBackdropPhotoAsset = 'assets/backdrop_filter_sample.jpg';

class _ImageFilteredSection extends StatefulWidget {
  const _ImageFilteredSection();

  @override
  State<_ImageFilteredSection> createState() => _ImageFilteredSectionState();
}

class _ImageFilteredSectionState extends State<_ImageFilteredSection> {
  double _slider = 0.0;
  // Cache the photo widget so dragging the slider doesn't recreate Image.asset.
  late final Widget _photo = Image.asset(
    _kBackdropPhotoAsset,
    fit: BoxFit.cover,
  );

  double get _sigma => _slider * _maxSigma;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              Positioned.fill(child: _photo),
              Positioned.fill(
                child: Center(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _sigma,
                      sigmaY: _sigma,
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
          value: _slider,
          sigma: _sigma,
          onChanged: (v) {
            // Quantize to 0.5-sigma increments (60 steps across 0..30) so
            // sub-pixel drag jitter doesn't flood CIGaussianBlur snapshots.
            final q = (v * 60).round() / 60;
            if (q != _slider) setState(() => _slider = q);
          },
        ),
      ],
    );
  }
}

class _BackdropFilterSection extends StatefulWidget {
  const _BackdropFilterSection();

  @override
  State<_BackdropFilterSection> createState() => _BackdropFilterSectionState();
}

class _BackdropFilterSectionState extends State<_BackdropFilterSection> {
  double _slider = 0.0;
  late final Widget _photo = Image.asset(
    _kBackdropPhotoAsset,
    fit: BoxFit.cover,
  );

  double get _sigma => _slider * _maxSigma;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              Positioned.fill(child: _photo),
              Positioned.fill(
                child: Center(
                  child: ClipOval(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _sigma,
                          sigmaY: _sigma,
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
          value: _slider,
          sigma: _sigma,
          onChanged: (v) {
            final q = (v * 60).round() / 60;
            if (q != _slider) setState(() => _slider = q);
          },
        ),
      ],
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
