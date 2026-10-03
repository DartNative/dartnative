// Our example app, built to look and behave like rive-flutter's own.
//
// Upstream's `example/lib/main.dart` groups its screens into sections of
// pill buttons under blue underlined headers, on a dark JetBrainsMono theme.
// We keep their sections, their order, their screen names, their palette and
// their layout, so the two apps can be walked side by side on a phone and any
// difference on screen is the plugin's doing.
//
// What we cannot keep is their code. Their examples are written against the
// Flutter runtime's API — `File.asset` + `RiveWidgetController` +
// `ViewModelInstance` + `RiveWidgetBuilder` — and we are built on the native
// iOS and Android runtimes instead. So each screen is re-expressed against
// our API while keeping their file, artboard, state machine and input names.
//
// Screens we cannot show yet are listed anyway, dimmed, naming the plugin
// feature they wait on. The menu is therefore also the port's progress report.

import 'package:dartnative/dartnative.dart';

import 'catalogue.dart';
import 'perf_overlay.dart' show PerfAction, PerfOverlayHost;
import 'screens/semantics_omni.dart' show harnessIndex;
import 'sections.dart';
import 'stall_probe.dart';
import 'theme.dart';

class RiveExamplesApp extends StatefulWidget {
  const RiveExamplesApp({super.key, this.autoPush});

  /// Only for the walk harness (`push:<name>` in the screen switch): a
  /// screen to open from the menu, twice, without a tap.
  final String? autoPush;

  @override
  State<RiveExamplesApp> createState() => _RiveExamplesAppState();
}

class _RiveExamplesAppState extends State<RiveExamplesApp> {
  @override
  void initState() {
    super.initState();
    final name = widget.autoPush;
    if (name != null) _autoPush(name);
  }

  /// Opens [names] from the menu as a tap does: one name twice, going back
  /// in between, so the logs hold a first open and a second one; `A>B`
  /// opens A, goes back, then opens B, as a user moving between screens.
  Future<void> _autoPush(String names) async {
    final order = names.split('>');
    final rounds = order.length == 1 ? [order[0], order[0]] : order;
    for (var round = 1; round <= rounds.length; round++) {
      final name = rounds[round - 1];
      Entry? entry;
      for (final e in buildSections().expand((s) => s.entries)) {
        if (e.name == name && e.builder != null) entry = e;
      }
      if (entry == null) {
        dnLog('[DN-Harness] no live screen named "$name"');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      dnLog('[DN-Harness] @${stallStamp()} push #$round "$name"');
      _openPage(context, entry);
      await Future<void>.delayed(const Duration(seconds: 8));
      if (!mounted) return;
      dnLog('[DN-Harness] @${stallStamp()} pop #$round');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = buildSections();

    return Scaffold(
      brightness: Brightness.dark,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        // DN's native bar is a trait to keep: on iOS 26 a null background is
        // the system's clear Liquid Glass bar (the scroll-edge effect keeps
        // the title legible); elsewhere, upstream's grey.
        backgroundColor: isIOS26 ? null : appBarColor,
        title: const Text(
          'Rive Examples',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 22,
            fontFamily: monoFont,
          ),
        ),
        actions: const [PerfAction()],
      ),
      body: PerfOverlayHost(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final section in sections) ...[
              _SectionHeader(section.title),
              for (final entry in section.entries) _NavButton(entry: entry),
            ],
            const SizedBox(height: 24),
            const _RendererNote(),
          ],
        ),
      ),
    );
  }
}

/// Their header: primary-coloured label over a thin primary divider.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontFamily: monoFont,
              ),
            ),
          ),
          const Divider(color: primaryColor, thickness: 0.5, height: 1),
          const SizedBox(height: 16),
        ],
      );
}

/// Their nav button: a wide grey pill with a centred label.
///
/// Upstream shows the description in a hover overlay, which a phone has no
/// way to trigger, so we put it under the label in a dimmer colour. A blocked
/// entry says what it waits on in place of the description.
class _NavButton extends StatelessWidget {
  const _NavButton({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final live = entry.status == PortStatus.done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 16),
      child: GestureDetector(
        onTap: live ? () => _openPage(context, entry) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: live ? buttonColor : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            children: [
              Text(
                entry.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: live
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF6E6E6E),
                  fontSize: 15,
                  fontFamily: monoFont,
                ),
              ),
              if (!live) ...[
                const SizedBox(height: 5),
                Text(
                  _note(entry),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8A7340),
                    fontSize: 11,
                    fontFamily: monoFont,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _note(Entry entry) => switch (entry.status) {
        PortStatus.blocked => 'needs ${entry.blockedOn}',
        PortStatus.upstreamTodo => 'upstream ships this unimplemented',
        PortStatus.done => '',
      };
}

/// Upstream's menu ends in a "Factory to use:" panel switching between the
/// Rive and Flutter renderers. We have neither and need no switch, so the
/// same spot says what we render with instead — it is the first thing a
/// Flutter developer comparing the two apps will look for.
class _RendererNote extends StatelessWidget {
  const _RendererNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          const Text(
            'Renderer:',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 15,
              fontFamily: monoFont,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Rive native',
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontFamily: monoFont,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We draw in a native view.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 11,
              fontFamily: monoFont,
            ),
          ),
        ],
      ),
    );
  }
}

/// Upstream wraps each page in a Scaffold + AppBar titled with the page name.
/// Pushes [entry]'s screen, watching the main thread while it is new.
void _openPage(BuildContext context, Entry entry) {
  StallProbe.watch(entry.name);
  Navigator.of(context).push(
    PageRoute<void>(builder: (context) => _WrappedPage(entry: entry)),
  );
}

class _WrappedPage extends StatelessWidget {
  const _WrappedPage({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.selfManaged) return entry.builder!(context);
    return Scaffold(
        brightness: Brightness.dark,
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: isIOS26 ? null : appBarColor,
          leading: const BackButton(iconColor: Color(0xFFFFFFFF)),
          title: Text(
            entry.name,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 17,
              fontFamily: monoFont,
            ),
          ),
          actions: const [PerfAction()],
        ),
        body: PerfOverlayHost(child: entry.builder!(context)),
      );
  }
}

/// One catalogue screen on its own, looked up by upstream's name.
///
/// Only for `dn run --dart-define=DN_SCREEN="Responsive Layouts"`: the
/// simulator cannot be tapped from a script, so this is how a screen is
/// launched directly to be screenshotted. A name that matches nothing, or a
/// screen not yet ported, is said on screen rather than left blank.
class RiveExampleScreen extends StatelessWidget {
  const RiveExampleScreen(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final entries = buildSections().expand((s) => s.entries).toList();
    // `Semantics [Omni]#3`: that screen, on its fourth artboard.
    final parts = name.split('#');
    if (parts.length > 1) harnessIndex = int.tryParse(parts[1]) ?? 0;
    for (final entry in entries) {
      if (entry.name == parts[0]) {
        if (entry.builder != null) return _WrappedPage(entry: entry);
        return _Message('"$name" is not ported yet: ${entry.blockedOn}');
      }
    }
    return _Message(
      'No screen named "$name". Names:\n'
      '${entries.map((e) => e.name).join('\n')}',
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Scaffold(
        brightness: Brightness.dark,
        backgroundColor: backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 13,
              fontFamily: monoFont,
            ),
          ),
        ),
      );
}
