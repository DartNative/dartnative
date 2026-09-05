/// State Management — Basics Demo
///
/// Demonstrates the state primitives:
///   1. Signal<T>   — counter, toggle; watched in a StatelessWidget
///   2. Computed<T> — derived label from the counter
///   3. effect()    — non-widget side-effect (logged to console)
///   4. Listenable.watch(context) — bridge for an existing ChangeNotifier
///
/// Key point: every widget below is a plain [StatelessWidget].  No setState,
/// no StatefulWidget, no Provider, no Consumer.  The signal drives the rebuild.
import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

// ── App-level signals (would live in lib/state/ in a real app) ───────────────

/// Counter — incremented by a button, displayed by two separate widgets.
final _counter = signal<int>(0);

/// Derived value — recomputes automatically when [_counter] changes.
final _counterLabel = computed<String>(() {
  final n = _counter.value;
  if (n == 0) return 'Press + to start';
  if (n == 1) return 'Tapped once';
  return 'Tapped $n times';
});

/// Dark-mode toggle — watched by the themed panel.
final _darkMode = signal<bool>(false);

// ── ChangeNotifier bridge demo ────────────────────────────────────────────────

/// An existing ChangeNotifier — no changes required to make it reactive.
class _ClickHistory extends ChangeNotifier {
  final List<String> _entries = [];

  List<String> get entries => List.unmodifiable(_entries);

  void record(int value) {
    _entries.insert(0, '#$value at ${DateTime.now().second}s');
    if (_entries.length > 5) _entries.removeLast();
    notifyListeners();
  }
}

final _history = _ClickHistory();

// ── Effect: console log ───────────────────────────────────────────────────────
// Runs immediately and re-runs every time _counter changes.
// In a real app this would be in initState or an app initialiser.
VoidCallback? _stopLogging;

void _startLogging() {
  _stopLogging?.call();
  _stopLogging = effect(() {
    // Reads _counter.value → registers as a dependency.
    dnLog('[StateDemo] counter changed → ${_counter.value}');
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StateBasicsDemo extends StatelessWidget {
  const StateBasicsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    _startLogging();
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'State — Basics',
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
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16,
            bottom: 16,
          ),
          children: const [
            _Section1Counter(),
            SizedBox(height: 24),
            _Section2DarkMode(),
            SizedBox(height: 24),
            _Section3Listenable(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Section 1 — Signal + Computed ────────────────────────────────────────────

/// Watches [_counter] (a Signal) and [_counterLabel] (a Computed).
/// This is a plain StatelessWidget — no setState involved.
class _Section1Counter extends StatelessWidget {
  const _Section1Counter();

  @override
  Widget build(BuildContext context) {
    // .watch() subscribes and returns the current value.
    // When _counter changes, only this widget rebuilds.
    final count = _counter.watch(context);
    final label = _counterLabel.watch(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          '1. Signal<T> + Computed<T>',
          subtitle: 'StatelessWidget rebuilt by a signal — no setState',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kRowBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // ── Large counter display ───────────────────────────────
              Text(
                '$count',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // ── Computed label ──────────────────────────────────────
              Text(
                label,
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              // ── Buttons ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Button(
                      variant: ButtonVariant.bordered,
                      title: '−',
                      onPressed: () {
                        _counter.update((c) => c - 1);
                        _history.record(_counter.value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Button(
                      variant: ButtonVariant.bordered,
                      title: '+',
                      onPressed: () {
                        _counter.value++;
                        _history.record(_counter.value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Button(
                      variant: ButtonVariant.bordered,
                      title: 'Reset',
                      onPressed: () {
                        _counter.value = 0;
                        _history.record(0);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CodeSnippet(
                'final count = _counter.watch(context);\n'
                'final label = _counterLabel.watch(context);\n'
                '// → both update when _counter changes',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section 2 — toggle Signal + themed panel ──────────────────────────────────

class _Section2DarkMode extends StatelessWidget {
  const _Section2DarkMode();

  @override
  Widget build(BuildContext context) {
    final dark = _darkMode.watch(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          '2. Signal<bool> toggle',
          subtitle: 'Panel reacts to a boolean signal',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dark mode',
                      style: TextStyle(
                        color: dark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF000000),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(value: dark, onChanged: (v) => _darkMode.value = v),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dark ? 'Theme: dark' : 'Theme: light',
                style: TextStyle(
                  color:
                      dark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _CodeSnippet(
                'final dark = _darkMode.watch(context);\n'
                '// update from Switch:\n'
                'Switch(onChanged: (v) => _darkMode.value = v)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section 3 — Listenable.watch bridge ──────────────────────────────────────

class _Section3Listenable extends StatelessWidget {
  const _Section3Listenable();

  @override
  Widget build(BuildContext context) {
    // Watch an existing ChangeNotifier — no class changes required.
    final hist = _history.watch<_ClickHistory>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          '3. Listenable.watch(context)',
          subtitle: 'Bridge for existing ChangeNotifier objects',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kRowBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 5 taps (from ChangeNotifier):',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (hist.entries.isEmpty)
                Text(
                  'No taps yet — use the counter above.',
                  style: TextStyle(color: kTextTertiary, fontSize: 13),
                )
              else
                ...hist.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '  $e',
                      style: TextStyle(
                        color: kCodeGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _CodeSnippet(
                '// Existing ChangeNotifier — unchanged.\n'
                'final hist = _history.watch<_ClickHistory>(context);\n'
                '// Reads hist.entries → rebuilt on notifyListeners()',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared UI helpers ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  const _CodeSnippet(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kTileBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: kCodeGreen,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
