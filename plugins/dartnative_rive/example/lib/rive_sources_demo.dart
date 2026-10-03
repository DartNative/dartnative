import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import 'rive_examples/perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'rive_examples/theme.dart';

/// The three parts of our API that nothing else in this example exercises:
/// text runs, artboard and animation selection, and loading from a URL.
///
/// Each section is a port of the screen Rive ships for it —
/// `SwiftTestText.swift`, `MultipleAnimations.swift` and
/// `SimpleHttpAnimation.swift` from rive-ios's Example-iOS — using the same
/// files and the same names, so a difference here is ours.
///
/// Names were read out of the files and checked, not guessed: testtext.riv
/// carries a top-level run `MyRun` whose authored value is "Hello there", and
/// artboard_animations.riv has artboards Square, Circle and Star with
/// animations `goaround` and `rollaround` on Square.
class RiveSourcesDemo extends StatefulWidget {
  const RiveSourcesDemo({super.key});

  @override
  State<RiveSourcesDemo> createState() => _RiveSourcesDemoState();
}

enum _Section { textRun, artboards, url }

class _RiveSourcesDemoState extends State<RiveSourcesDemo> {
  @override
  void initState() {
    super.initState();
    // A white screen: dark status-bar icons.
    SystemChrome.setSystemUIOverlayStyle(whiteScreenStatusBar);
  }

  _Section _section = _Section.textRun;

  // ── Text runs ─────────────────────────────────────────────────────────────
  final _textController = RiveController();
  int _textIndex = 0;
  // No emoji: the font embedded in testtext.riv covers U+0020–U+FEFF only,
  // and Rive draws text with the file's own font rather than falling back to
  // a system one, so an emoji (U+1F44B) has no glyph and renders as nothing.
  // The accented phrase stays inside the font's range and is a real test.
  static const _phrases = [
    'Hello there',
    'DartNative',
    'Rive, natively',
    'Accented: àéîõü',
  ];

  // ── Artboard + animation selection ────────────────────────────────────────
  int _choiceIndex = 0;
  // Artboard / animation pairs, read out of artboard_animations.riv.
  static const _choices = <({String label, String artboard, String? animation})>[
    (label: 'Square · goaround', artboard: 'Square', animation: 'goaround'),
    (label: 'Square · rollaround', artboard: 'Square', animation: 'rollaround'),
    (label: 'Circle', artboard: 'Circle', animation: null),
    (label: 'Star', artboard: 'Star', animation: null),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leading: const BackButton(iconColor: Color(0xFF000000)),
        title: const Text(
          'Text, artboards, URL',
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _Section.values)
                    _Chip(
                      label: switch (s) {
                        _Section.textRun => 'Text run',
                        _Section.artboards => 'Artboards',
                        _Section.url => 'URL',
                      },
                      selected: s == _section,
                      onTap: () => setState(() => _section = s),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              switch (_section) {
                _Section.textRun => _textRunSection(),
                _Section.artboards => _artboardSection(),
                _Section.url => _urlSection(),
              },
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text runs ─────────────────────────────────────────────────────────────

  Widget _textRunSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 260,
            child: Rive(
              asset: 'assets/rive/testtext.riv',
              stateMachineName: 'State Machine 1',
              fit: RiveFit.contain,
              controller: _textController,
              legacy: true,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ports SwiftTestText.swift · testtext.riv · run "MyRun"',
            style: TextStyle(color: Color(0xFF999999), fontSize: 11),
          ),
          const SizedBox(height: 16),
          const _Title('setTextRunValue'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _phrases.length; i++)
                _Chip(
                  label: _phrases[i],
                  selected: i == _textIndex,
                  onTap: () {
                    setState(() => _textIndex = i);
                    _textController.setTextRunValue('MyRun', _phrases[i]);
                  },
                ),
            ],
          ),
          const _Expect('the text in the artboard becomes that phrase'),
          const SizedBox(height: 8),
          const Text(
            'The artboard starts on its authored text, "Hello there", so the '
            'first phrase is a no-op you can use as the control.',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      );

  // ── Artboard + animation selection ────────────────────────────────────────

  Widget _artboardSection() {
    final c = _choices[_choiceIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 260,
          child: Rive(
            // One file, different artboards: a new key per choice so the
            // element remounts rather than reconfiguring in place.
            key: ValueKey(c.label),
            asset: 'assets/rive/artboard_animations.riv',
            artboardName: c.artboard,
            animationName: c.animation,
            fit: RiveFit.contain,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'ports MultipleAnimations.swift · artboard_animations.riv',
          style: TextStyle(color: Color(0xFF999999), fontSize: 11),
        ),
        const SizedBox(height: 16),
        const _Title('artboardName / animationName'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _choices.length; i++)
              _Chip(
                label: _choices[i].label,
                selected: i == _choiceIndex,
                onTap: () => setState(() => _choiceIndex = i),
              ),
          ],
        ),
        _Expect(
          c.animation == null
              ? 'the ${c.artboard} artboard, on its default animation'
              : 'the ${c.artboard} artboard playing "${c.animation}"',
        ),
        const SizedBox(height: 8),
        const Text(
          'Square has two animations, so switching between them is the test '
          'that animationName is honoured and not just the artboard.',
          style: TextStyle(color: Color(0xFF888888), fontSize: 12),
        ),
      ],
    );
  }

  // ── URL ───────────────────────────────────────────────────────────────────

  Widget _urlSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 260,
            // `Rive.network` is a factory, so this subtree is not const.
            child: Rive.network(
              // The same URL rive-ios's own SimpleHttpAnimation uses.
              'https://cdn.rive.app/animations/truck.riv',
              fit: RiveFit.contain,
              // truck.riv has no state machine: only the classic runtime
              // plays its animation.
              legacy: true,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ports SimpleHttpAnimation.swift · cdn.rive.app/animations/truck.riv',
            style: TextStyle(color: Color(0xFF999999), fontSize: 11),
          ),
          const SizedBox(height: 16),
          const _Title('Rive.network'),
          const _Expect(
            'the truck downloads and plays; leaving and returning is instant, '
            'served from the disk cache',
          ),
          const SizedBox(height: 8),
          const Text(
            'The same truck.riv is bundled on the Layout screen, so the two '
            'should look identical — one from the network, one from assets.',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      );
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
        padding: const EdgeInsets.only(top: 4),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF111111) : const Color(0xFFEFEFF0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? const Color(0xFFFFFFFF) : const Color(0xFF333333),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
