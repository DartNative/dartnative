/// Material 3 progress indicators — the wavy style.
///
/// The generic CircularProgressIndicator / LinearProgressIndicator widgets
/// with the `android:` group (AndroidProgressIndicatorStyle): Material's
/// wavy indicator, track gap, and stop dot, rendered by the real
/// com.google.android.material.progressindicator views. The same widgets
/// without `android:` keep the plain look on both platforms.
import 'dart:async';

import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class M3ProgressDemo extends StatefulWidget {
  const M3ProgressDemo({super.key});

  @override
  State<M3ProgressDemo> createState() => _M3ProgressDemoState();
}

class _M3ProgressDemoState extends State<M3ProgressDemo>
    with WidgetsBindingObserver {
  static const _wavy = AndroidProgressIndicatorStyle(wavy: true);

  // Drives the determinate demos 0 → 1 on a loop.
  double _progress = 0.35;
  Timer? _ticker;

  // Dart timers keep firing when the app is backgrounded — this ticker was
  // rebuilding the whole screen 12.5x/s off-screen. Pause it with the app.
  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _progress += 0.004;
        if (_progress > 1.0) _progress = 0.0;
      });
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Progress Indicators',
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
          _SectionHeader('Wavy linear'),
          const SizedBox(height: 4),
          _SectionSubtitle('LinearProgressIndicator · android: wavy'),
          const SizedBox(height: 12),
          _card(
            children: [
              SizedBox(
                width: double.infinity,
                height: 16,
                child: LinearProgressIndicator(
                  value: _progress,
                  android: _wavy,
                ),
              ),
              const SizedBox(height: 8),
              _caption('Determinate — with the M3 track gap and stop dot'),
              const SizedBox(height: 20),
              const SizedBox(
                width: double.infinity,
                height: 16,
                child: LinearProgressIndicator(android: _wavy),
              ),
              const SizedBox(height: 8),
              _caption('Indeterminate'),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Wavy circular'),
          const SizedBox(height: 4),
          _SectionSubtitle('CircularProgressIndicator · android: wavy'),
          const SizedBox(height: 12),
          _card(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(android: _wavy),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: _progress,
                      android: _wavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _caption('Spinner · determinate ring'),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Tuned wave'),
          const SizedBox(height: 4),
          _SectionSubtitle('waveAmplitude · wavelength · waveSpeed'),
          const SizedBox(height: 12),
          _card(
            children: [
              SizedBox(
                width: double.infinity,
                height: 24,
                child: LinearProgressIndicator(
                  value: _progress,
                  android: const AndroidProgressIndicatorStyle(
                    wavy: true,
                    waveAmplitude: 6,
                    wavelength: 60,
                    waveSpeed: 120,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _caption('waveAmplitude 6 · wavelength 60 · waveSpeed 120'),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('Page-load bar'),
          const SizedBox(height: 4),
          _SectionSubtitle('A thin full-width bar, the browser case'),
          const SizedBox(height: 12),
          _card(
            children: [
              _caption('Material default — rounded ends, gap, stop dot'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: LinearProgressIndicator(value: _progress),
              ),
              const SizedBox(height: 20),
              _caption('Flattened — trackGap 0, stopIndicatorSize 0'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: _progress,
                  android: const AndroidProgressIndicatorStyle(
                    trackGap: 0,
                    stopIndicatorSize: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _caption(
                'Same widget either way — the group only removes the '
                'Material flourishes',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader('No tuning'),
          const SizedBox(height: 4),
          _SectionSubtitle('Same widget, no android: group'),
          const SizedBox(height: 12),
          _card(
            children: [
              SizedBox(
                width: double.infinity,
                height: 4,
                child: LinearProgressIndicator(value: _progress),
              ),
              const SizedBox(height: 8),
              _caption(
                'Still Material 3 — the android: group only adjusts it',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
