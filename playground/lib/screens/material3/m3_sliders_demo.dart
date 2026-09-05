/// Material 3 sliders — the updated M3 anatomy.
///
/// The generic Slider widget IS Material's on Android — the real
/// com.google.android.material.slider.Slider, with the slim upright handle,
/// the gap either side of it, the stop dot and the value label on drag.
/// Nothing to turn on. `android: AndroidSliderStyle(...)` only adjusts it.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3SlidersDemo extends StatefulWidget {
  const M3SlidersDemo({super.key});

  @override
  State<M3SlidersDemo> createState() => _M3SlidersDemoState();
}

class _M3SlidersDemoState extends State<M3SlidersDemo> {
  double _continuous = 0.6;
  double _stepped = 40;
  double _thick = 0.3;
  double _plain = 0.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Sliders',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16,
          bottom: 16,
        ),
        children: [
          _SectionHeader('Continuous'),
          const SizedBox(height: 4),
          _SectionSubtitle('Slider — no android: group needed'),
          const SizedBox(height: 12),
          _card(
            children: [
              Slider(
                value: _continuous,
                onChanged: (v) => setState(() => _continuous = v),
              ),
              const SizedBox(height: 4),
              _caption(
                'Stock Material 3 — slim handle, gap, stop dot '
                '(${_continuous.toStringAsFixed(2)})',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Discrete'),
          const SizedBox(height: 4),
          _SectionSubtitle('divisions: 5 — snaps with native tick marks'),
          const SizedBox(height: 12),
          _card(
            children: [
              Slider(
                value: _stepped,
                min: 0,
                max: 100,
                divisions: 5,
                onChanged: (v) => setState(() => _stepped = v),
              ),
              const SizedBox(height: 4),
              _caption('Value: ${_stepped.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Tuned'),
          const SizedBox(height: 4),
          _SectionSubtitle(
            'trackHeight · thumbHeight · thumbTrackGap · custom color',
          ),
          const SizedBox(height: 12),
          _card(
            children: [
              Slider(
                value: _thick,
                onChanged: (v) => setState(() => _thick = v),
                activeColor: const Color(0xFFFF9500),
                android: const AndroidSliderStyle(
                  trackHeight: 24,
                  thumbHeight: 52,
                  thumbTrackGap: 8,
                ),
              ),
              const SizedBox(height: 4),
              _caption(
                'trackHeight 24 · thumbHeight 52 · thumbTrackGap 8 — '
                'Material defaults are 16 / 44 / 6',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Flattened'),
          const SizedBox(height: 4),
          _SectionSubtitle('The M3 flourishes turned off'),
          const SizedBox(height: 12),
          _card(
            children: [
              Slider(
                value: _plain,
                onChanged: (v) => setState(() => _plain = v),
                android: const AndroidSliderStyle(
                  trackHeight: 4,
                  thumbTrackGap: 0,
                  stopIndicatorSize: 0,
                  trackCornerSize: 0,
                ),
              ),
              const SizedBox(height: 4),
              _caption(
                'A plain bar: square ends, no gap, no stop dot — what a '
                'scrubber over video wants',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: kRowBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: children),
  );

  Widget _caption(String text) =>
      Text(text, style: TextStyle(color: kTextSecondary, fontSize: 12));
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionSubtitle extends StatelessWidget {
  const _SectionSubtitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: kTextSecondary, fontSize: 12),
    );
  }
}
