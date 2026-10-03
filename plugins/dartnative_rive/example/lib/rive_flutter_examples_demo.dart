import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import 'rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'rive_examples/theme.dart';

/// Ports of the examples that ship with Flutter's `rive` package, so the two
/// can be run side by side and compared.
///
/// Each entry names the upstream screen it came from
/// (`rive-flutter/example/lib/examples/…`) and uses the same `.riv` file and
/// the same input names, so a difference on screen is a difference in the
/// plugin rather than in the content. Every control states what it should do.
///
/// These are the files upstream drives through its own API; anything that only
/// works by tapping the artboard is noted as such.
class RiveFlutterExamplesDemo extends StatefulWidget {
  const RiveFlutterExamplesDemo({super.key});

  @override
  State<RiveFlutterExamplesDemo> createState() =>
      _RiveFlutterExamplesDemoState();
}

/// One ported example.
typedef _Case = ({
  String label,
  String upstream,
  String asset,
  String? stateMachine,
  String summary,
  // A number input driven by discrete buttons, as upstream's inputs.dart does.
  String? number,
  List<({String label, double value})> numberChoices,
  String? trigger,
  String expect,
});

const _cases = <_Case>[
  (
    label: 'Inputs',
    upstream: 'examples/inputs.dart',
    asset: 'assets/rive/skills.riv',
    // skills.riv declares TWO state machines and only this one owns the
    // `Level` input; "State Machine 1" also exists but ignores it. Found by
    // comparing against the native app, where the character never moved.
    stateMachine: "Designer's Test",
    summary: 'A skills dial driven by one number input, exactly as upstream '
        'drives it.',
    number: 'Level',
    numberChoices: [
      (label: 'Beginner', value: 0),
      (label: 'Intermediate', value: 1),
      (label: 'Expert', value: 2),
    ],
    trigger: null,
    expect: 'the dial moves to that level',
  ),
  (
    label: 'Trigger',
    upstream: 'examples/pause_play.dart (little_machine)',
    asset: 'assets/rive/little_machine.riv',
    stateMachine: 'State Machine 1',
    summary: 'A machine with a single trigger input.',
    number: null,
    numberChoices: [],
    trigger: 'Trigger 1',
    expect: 'the machine runs its cycle once',
  ),
  (
    label: 'Multi-touch',
    upstream: 'examples/multi_touch.dart',
    asset: 'assets/rive/multitouch.riv',
    stateMachine: 'State Machine 1',
    summary: 'Two rectangles with their own listeners. Drag both at once — '
        'this is a hit-testing test, so it has no app-side controls.',
    number: null,
    numberChoices: [],
    trigger: null,
    expect: 'each rectangle responds to its own finger, independently',
  ),
  (
    label: 'Car',
    upstream: 'examples/rive_widget.dart (off_road_car)',
    asset: 'assets/rive/off_road_car.riv',
    stateMachine: 'State Machine 1',
    summary: 'The plain "just show an artboard" case: autoplay, no inputs.',
    number: null,
    numberChoices: [],
    trigger: null,
    expect: 'the car animates on its own, forever',
  ),
];

class _RiveFlutterExamplesDemoState extends State<RiveFlutterExamplesDemo> {
  final _controller = RiveController();
  int _selected = 0;
  double? _number;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
    _controller.stateChanges.listen((c) => _note('state → ${c.state}'));
    _controller.events.listen((e) => _note('event ${e.name} ${e.properties}'));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _note(String line) {
    print('[RiveFlutterExamples] $line'); // ignore: avoid_print
    if (!mounted) return;
    setState(() {
      _log.insert(0, line);
      if (_log.length > 6) _log.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _cases[_selected];

    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Flutter examples',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [PerfAction(color: Color(0xFF000000))],
      ),
      body: PerfOverlayHost(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 320,
                child: Rive(
                  key: ValueKey(c.asset),
                  asset: c.asset,
                  stateMachineName: c.stateMachine,
                  fit: RiveFit.contain,
                  alignment: RiveAlignment.center,
                  controller: _controller,
                  legacy: true,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                c.summary,
                style: const TextStyle(color: Color(0xFF444444), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'upstream: ${c.upstream}',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _cases.length; i++)
                    _Chip(
                      label: _cases[i].label,
                      selected: i == _selected,
                      onTap: () => setState(() {
                        _selected = i;
                        _number = null;
                        _log.clear();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              if (c.number != null) ...[
                _Title('${c.number} — number input'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in c.numberChoices)
                      _Chip(
                        label: choice.label,
                        selected: _number == choice.value,
                        onTap: () {
                          setState(() => _number = choice.value);
                          _controller.number(c.number!)?.value = choice.value;
                          _note('set ${c.number}=${choice.value.toInt()}');
                        },
                      ),
                  ],
                ),
                _Expect(c.expect),
                const SizedBox(height: 20),
              ],

              if (c.trigger != null) ...[
                _Title('${c.trigger} — trigger input'),
                Row(
                  children: [
                    _Button('Fire', () {
                      _controller.trigger(c.trigger!)?.fire();
                      _note('fired ${c.trigger}');
                    }),
                  ],
                ),
                _Expect(c.expect),
                const SizedBox(height: 20),
              ],

              if (c.number == null && c.trigger == null) ...[
                _Expect(c.expect),
                const SizedBox(height: 20),
              ],

              const _Title('Log'),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _log.isEmpty
                    ? const Text(
                        'Nothing yet.',
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
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
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

class _Expect extends StatelessWidget {
  const _Expect(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '→ $text',
          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        ),
      );
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF111111) : const Color(0xFFEFEFF0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? const Color(0xFFFFFFFF) : const Color(0xFF333333),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
