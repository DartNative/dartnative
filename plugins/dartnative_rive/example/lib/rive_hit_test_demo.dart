import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import 'rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'rive_examples/theme.dart';

/// Verifies who owns an artboard's inputs.
///
/// The artboard here (light_switch) drives its own `On` input when you drag
/// its plate, and the app can write the same input from the toggle below. That
/// is the one overlap worth understanding, so this screen makes it visible:
///
///  * with hit testing ON (the default), both work, and the artboard wins
///    whenever you touch it;
///  * with `RiveHitTestBehavior.none`, the artboard stops taking touches and
///    the input is exclusively the app's.
///
/// The counter records how often each side wrote the input, so the claim in
/// the README is a thing you can check rather than take on trust.
class RiveHitTestDemo extends StatefulWidget {
  const RiveHitTestDemo({super.key});

  @override
  State<RiveHitTestDemo> createState() => _RiveHitTestDemoState();
}

class _RiveHitTestDemoState extends State<RiveHitTestDemo> {
  final _controller = RiveController();

  RiveHitTestBehavior _behavior = RiveDefaults.hitTestBehavior;
  bool _on = false;

  int _appWrites = 0;
  int _artboardChanges = 0;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
    // A state change with no preceding app write means the artboard drove the
    // input itself — which is exactly what this screen is here to show.
    _controller.stateChanges.listen((change) {
      if (!mounted) return;
      setState(() {
        _artboardChanges++;
        _log.insert(0, 'artboard → ${change.state}');
        if (_log.length > 6) _log.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _write(bool value) {
    setState(() {
      _on = value;
      _appWrites++;
      _log.insert(0, 'app → On=$value');
      if (_log.length > 6) _log.removeLast();
    });
    _controller.boolean('On')?.value = value;
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _behavior == RiveHitTestBehavior.none;

    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Who owns the input',
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
              // A tappable layer BEHIND the artboard: with `transparent` or
              // `translucent` a touch that misses a listener should reach it,
              // which is the part of the enum a single artboard cannot show.
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _log.insert(0, 'BEHIND the artboard was tapped');
                        if (_log.length > 6) _log.removeLast();
                      }),
                      child: Container(color: const Color(0xFFEFEFF0)),
                    ),
                    Rive(
                      // The key includes the behaviour so a change remounts the
                      // view; hit testing is applied when the file loads.
                      key: ValueKey(_behavior),
                      asset: 'assets/rive/light_switch.riv',
                      stateMachineName: 'Switch',
                      fit: RiveFit.contain,
                      alignment: RiveAlignment.center,
                      hitTestBehavior: _behavior,
                      controller: _controller,
                      legacy: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const _Title('hitTestBehavior'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in RiveHitTestBehavior.values)
                    _Chip(
                      label: b.name,
                      selected: b == _behavior,
                      onTap: () => setState(() {
                        _behavior = b;
                        _log.clear();
                        _appWrites = 0;
                        _artboardChanges = 0;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _Expect(
                blocked
                    ? 'dragging the switch does nothing; only the toggle moves it'
                    : 'dragging the switch flips it, and so does the toggle',
              ),
              _Expect(
                switch (_behavior) {
                  RiveHitTestBehavior.none =>
                    'taps pass through — the grey area behind should log',
                  RiveHitTestBehavior.opaque =>
                    'the artboard swallows every tap; behind never logs',
                  RiveHitTestBehavior.translucent ||
                  RiveHitTestBehavior.transparent =>
                    'taps that miss a listener may reach the grey area behind',
                },
              ),
              const SizedBox(height: 20),

              const _Title('The app writing the same input'),
              Row(
                children: [
                  const Text('On', style: TextStyle(color: Color(0xFF222222))),
                  const SizedBox(width: 7),
                  Switch(value: _on, onChanged: _write),
                ],
              ),
              _Expect('the lamp follows this toggle in every mode'),
              const SizedBox(height: 20),

              const _Title('Who wrote it'),
              Text(
                'app writes: $_appWrites     artboard state changes: '
                '$_artboardChanges',
                style: const TextStyle(color: Color(0xFF222222), fontSize: 14),
              ),
              _Expect(
                blocked
                    ? 'with none, artboard changes should only follow an app write'
                    : 'with hit testing on, the artboard changes on its own too',
              ),
              const SizedBox(height: 12),

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
                        'Nothing yet — drag the switch, or use the toggle.',
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
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Text(
          '→ $text',
          style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
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
