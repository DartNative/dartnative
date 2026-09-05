import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';
import '../home/demo_ui.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class LottieControlsDemo extends StatefulWidget {
  const LottieControlsDemo({super.key});

  @override
  State<LottieControlsDemo> createState() => _LottieControlsDemoState();
}

class _LottieControlsDemoState extends State<LottieControlsDemo> {
  @override
  void initState() {
    super.initState();
    // Transparent statusBarColor: an opaque overlay paints over the iOS 26
    // glass bar frost and clips capsule press-scale.
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Lottie Controls',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: const _DemoBody(),
    );
  }
}

// ── Animation catalogue ───────────────────────────────────────────────────────

const _animations = [
  (label: 'Lottie Logo', asset: 'assets/animations/LottieLogo2.json'),
  (label: 'Boat Loader', asset: 'assets/animations/Boat_Loader.json'),
  (label: 'Twitter Heart', asset: 'assets/animations/TwitterHeart.json'),
];

// ── Demo body ─────────────────────────────────────────────────────────────────

class _DemoBody extends StatefulWidget {
  const _DemoBody();

  @override
  State<_DemoBody> createState() => _DemoBodyState();
}

class _DemoBodyState extends State<_DemoBody> {
  final _controller = LottieController();
  int _selected = 0;
  double _speed = 1.0;
  double _scrub = 0.0;
  bool _loop = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSpeedChanged(double v) {
    setState(() => _speed = v);
    _controller.setSpeed(v);
  }

  void _onScrubChanged(double v) {
    setState(() => _scrub = v);
    _controller.setProgress(v);
  }

  void _onLoopToggled(bool v) {
    setState(() => _loop = v);
    _controller.setLoopMode(v ? LottieLoopMode.loop : LottieLoopMode.playOnce);
  }

  void _selectAnimation(int index) {
    setState(() {
      _selected = index;
      _scrub = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final anim = _animations[_selected];

    return Container(
      color: kHomeBg,
      child: Column(
        children: [
          // ── Animation picker ────────────────────────────────────────────
          _AnimationPicker(
            items: [for (final a in _animations) a.label],
            selected: _selected,
            onSelect: _selectAnimation,
          ),

          // ── Player ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            height: 240,
            color: kTileBg,
            child: Lottie(
              asset: anim.asset,
              loop: _loop,
              autoplay: true,
              speed: _speed,
              controller: _controller,
            ),
          ),

          // ── Playback controls ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  title: 'Play',
                  variant: ButtonVariant.filled,
                  onPressed: _controller.play,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  title: 'Pause',
                  variant: ButtonVariant.filled,
                  onPressed: _controller.pause,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Button(
                  title: 'Stop',
                  variant: ButtonVariant.filled,
                  onPressed: _controller.stop,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ],
            ),
          ),

          // ── Loop toggle ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Loop',
                  style: TextStyle(
                    fontSize: 16,
                    color: kTextPrimary,
                  ),
                ),
                const Spacer(),
                Switch(value: _loop, onChanged: _onLoopToggled),
              ],
            ),
          ),

          // ── Speed slider ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Text(
              'Speed: ${_speed.toStringAsFixed(1)}×',
              style: TextStyle(fontSize: 16, color: kTextPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _speed,
              min: 0.25,
              max: 3.0,
              onChanged: _onSpeedChanged,
            ),
          ),

          // ── Scrub slider ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Text(
              'Scrub: ${(_scrub * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 16, color: kTextPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _scrub,
              min: 0.0,
              max: 1.0,
              onChanged: _onScrubChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animation picker ──────────────────────────────────────────────────────────

class _AnimationPicker extends StatelessWidget {
  const _AnimationPicker({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<String> items;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Button(
              title: items[i],
              variant:
                  i == selected ? ButtonVariant.filled : ButtonVariant.tinted,
              onPressed: () => onSelect(i),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ],
        ],
      ),
    );
  }
}
