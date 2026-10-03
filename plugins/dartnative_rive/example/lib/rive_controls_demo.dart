import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import 'rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'rive_examples/theme.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class RiveControlsDemo extends StatefulWidget {
  const RiveControlsDemo({super.key});

  @override
  State<RiveControlsDemo> createState() => _RiveControlsDemoState();
}

class _RiveControlsDemoState extends State<RiveControlsDemo> {
  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Clear glass AppBar over a white Scaffold (dn create template pattern).
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Controls',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [PerfAction(color: Color(0xFF000000))],
      ),
      body: const PerfOverlayHost(child: _DemoBody()),
    );
  }
}

// ── Catalogue ─────────────────────────────────────────────────────────────────

// The three sample files, with the artboard, state machine and input names
// they were authored with. All three come from rive-ios's Example-iOS/Assets;
// the names below were read out of the files themselves, and the bridge logs
// the real roster (`inputs=[…]`) on load when verbose logging is on.
/// One demo file, and what each of its controls should do.
///
/// The `expect` strings are the point of this screen: a control with no stated
/// outcome cannot be judged working or broken. Keep them to one short line.
const _files = [
  (
    label: 'Rating',
    asset: 'assets/rive/rating_animation.riv',
    stateMachine: 'State Machine 1',
    summary: 'Five-star rating. Tapping a star also sets it.',
    number: 'rating',
    numberMin: 1.0,
    numberMax: 5.0,
    numberExpect: 'fills that many stars',
    boolean: null,
    booleanExpect: '',
    eventExpect: 'a rating1..rating5 event, plus state lines, on every change',
  ),
  (
    label: 'Light switch',
    asset: 'assets/rive/light_switch.riv',
    stateMachine: 'Switch',
    summary: 'A wall switch: grey plate, lamp above. Drag the plate to flip '
        'it.',
    number: null,
    numberMin: 0.0,
    numberMax: 1.0,
    numberExpect: '',
    boolean: 'On',
    booleanExpect: 'lamp on / off',
    eventExpect: 'no events, but state lines when the switch flips',
  ),
  (
    label: 'Leg day',
    asset: 'assets/rive/leg_day_events_example.riv',
    // "Main" is a LAYER inside this machine; the machine itself is named
    // after the artboard's headline. The device log settled it.
    stateMachine: "Don't Skip Leg Day",
    summary: 'A power bar and a lifter. Tap the red button on the artboard '
        'to charge it; at full power he lifts.',
    number: null,
    numberMin: 0.0,
    numberMax: 1.0,
    numberExpect: '',
    // `Charged` is in the roster but the graph owns it: the state machine
    // raises the lifter itself once the bar tops out. Setting it from here
    // did nothing on device, so it is not exposed as a control.
    boolean: null,
    booleanExpect: '',
    // No ClickButton control here. Firing that trigger from Dart reaches the
    // right state machine on a live, playing view — measured on device:
    //   sm=Don't Skip Leg Day hasView=true isPlaying=true inWindow=true
    // — and still moves nothing. The lifter is driven by the artboard's own
    // listeners, which need a touch at a LOCATION, not just the input. So
    // this file is a tap-the-artboard demo; a button that fires a real input
    // into a healthy machine and does nothing is worse than no button.
    eventExpect: 'no events from this file, but state lines as it charges',
  ),
];


// ── Demo body ─────────────────────────────────────────────────────────────────

class _DemoBody extends StatefulWidget {
  const _DemoBody();

  @override
  State<_DemoBody> createState() => _DemoBodyState();
}

class _DemoBodyState extends State<_DemoBody> {
  final _controller = RiveController();
  int _selected = 0;
  double _number = 3;
  bool _switchOn = false;
  final List<String> _log = [];

  /// One log for everything the demo does or is told, newest first. It doubles
  /// as the events panel and as the trace to read when something looks inert —
  /// the native bridge's own `[DNRive]` lines land in `dn logs` alongside it.
  void _note(String line) {
    print('[RiveDemo] $line'); // ignore: avoid_print
    if (!mounted) return;
    setState(() {
      _log.insert(0, line);
      if (_log.length > 8) _log.removeLast();
    });
  }

  @override
  void initState() {
    super.initState();
    // Native reports events only while this stream has a listener.
    // Layer-state changes: a machine that reports no events still reports
    // these, so this is what shows whether it is doing anything at all.
    _controller.stateChanges.listen((change) {
      _note('state ${change.stateMachine} → ${change.state}');
    });
    _controller.events.listen((event) {
      _note(
        event is OpenUrlEvent
            ? 'event ${event.name} → ${event.url}'
            : 'event ${event.name} ${event.properties}',
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() {
      _selected = index;
      _number = _files[index].numberMin;
      _switchOn = false;
      _log.clear();
    });
    _note('loaded ${_files[index].label} (${_files[index].asset})');
  }

  @override
  Widget build(BuildContext context) {
    final file = _files[_selected];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── The artboard ─────────────────────────────────────────────────
          // Rive has no size of its own, so the demo gives it one. These
          // artboards draw their content small inside a square, so a taller
          // box buys real pixels for the tap targets.
          SizedBox(
            height: 340,
            child: Rive(
              // A new key per file so switching rebuilds the element rather
              // than reconfiguring one that is mid-animation.
              key: ValueKey(file.asset),
              asset: file.asset,
              stateMachineName: file.stateMachine,
              fit: RiveFit.contain,
              alignment: RiveAlignment.center,
              controller: _controller,
              legacy: true,
            ),
          ),
          const SizedBox(height: 12),

          // ── What this artboard is ────────────────────────────────────────
          Text(
            file.summary,
            style: const TextStyle(color: Color(0xFF444444), fontSize: 13),
          ),
          const SizedBox(height: 16),

          // ── File picker ──────────────────────────────────────────────────
          Row(
            children: [
              for (var i = 0; i < _files.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Chip(
                      label: _files[i].label,
                      selected: i == _selected,
                      onTap: () => _select(i),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── State machine inputs ─────────────────────────────────────────
          // These are what actually drive a state machine. Playback below is
          // the animation-level control, and mostly does nothing here.
          const _SectionTitle('State machine inputs'),
          if (file.number != null) ...[
            _InputLabel(
              '${file.number} = ${_number.toStringAsFixed(0)}',
              file.numberExpect,
            ),
            // Inset from the screen edge. The slider is a real UISlider, and
            // iOS gives the leading ~20pt to the navigation controller's
            // interactive-pop recogniser: grabbing the thumb at a low value
            // inside that strip starts a back-swipe instead of a drag. The
            // page's own 20pt of padding is not enough on its own, so this
            // adds a margin that keeps the whole track clear of it.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: _number,
                min: file.numberMin,
                max: file.numberMax,
                divisions: (file.numberMax - file.numberMin).round(),
                onChanged: (v) {
                  setState(() => _number = v);
                  _controller.number(file.number!)?.value = v;
                  _note('set number ${file.number}=${v.toStringAsFixed(0)}');
                },
              ),
            ),
          ],
          if (file.boolean != null)
            _BooleanRow(
              name: file.boolean!,
              expect: file.booleanExpect,
              value: _switchOn,
              onChanged: (v) {
                setState(() => _switchOn = v);
                _controller.boolean(file.boolean!)?.value = v;
                _note('set boolean ${file.boolean}=$v');
              },
            ),
          const SizedBox(height: 20),

          // ── Playback ─────────────────────────────────────────────────────
          const _SectionTitle('Playback'),
          Row(
            children: [
              _Button('Play', () {
                _controller.play();
                _note('play()');
              }),
              _Button('Pause', () {
                _controller.pause();
                _note('pause()');
              }),
              _Button('Stop', () {
                _controller.stop();
                _note('stop()');
              }),
              _Button('Reset', () {
                _controller.reset();
                _note('reset()');
              }),
            ],
          ),
          const SizedBox(height: 8),
          const _Expect(
            'stop and reset rewind the artboard; play and pause drive the '
            'render loop, not the state machine, so they look inert here',
          ),
          const SizedBox(height: 20),

          // ── Log ──────────────────────────────────────────────────────────
          const _SectionTitle('Log — events and calls'),
          _Expect(file.eventExpect),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _log.isEmpty
                ? const Text(
                    'Nothing yet — interact with the artboard or the controls.',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in _log)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Small pieces ──────────────────────────────────────────────────────────────

/// One labelled switch for a boolean state machine input.
class _BooleanRow extends StatelessWidget {
  const _BooleanRow({
    required this.name,
    required this.expect,
    required this.value,
    required this.onChanged,
  });

  final String name;
  final String expect;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // The label used to end in ': ', which was the only thing
              // separating it from the switch; an explicit gap replaces it.
              const SizedBox(width: 7),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          _Expect(expect),
          const SizedBox(height: 6),
        ],
      );
}

/// A control's name with its current value, above what it should do.
class _InputLabel extends StatelessWidget {
  const _InputLabel(this.title, this.expect);

  final String title;
  final String expect;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          _Expect(expect),
        ],
      );
}

/// What a control should make happen. This is what makes the screen
/// judgeable: if the artboard does something else, that is a bug.
class _Expect extends StatelessWidget {
  const _Expect(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        '→ $text',
        style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
            ),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF111111) : const Color(0xFFEFEFF0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF333333),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
