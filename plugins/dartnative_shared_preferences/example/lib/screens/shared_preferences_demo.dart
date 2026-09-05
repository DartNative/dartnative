/// SharedPreferences demo — standalone example for dartnative_shared_preferences.
///
/// Drop-in `package:shared_preferences` API backed by NSUserDefaults (iOS) /
/// SharedPreferences (Android), wired through Dart FFI — no MethodChannel, so
/// it's safe to call from any isolate.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SharedPreferencesDemo extends StatefulWidget {
  const SharedPreferencesDemo({super.key});

  @override
  State<SharedPreferencesDemo> createState() => _SharedPreferencesDemoState();
}

class _SharedPreferencesDemoState extends State<SharedPreferencesDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'Prefs',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: const _PreferencesPanel(),
    );
  }
}

// ── Preferences panel ──────────────────────────

class _PreferencesPanel extends StatefulWidget {
  const _PreferencesPanel();

  @override
  State<_PreferencesPanel> createState() => _PreferencesPanelState();
}

class _PreferencesPanelState extends State<_PreferencesPanel> {
  SharedPreferences? _prefs;
  String _log = '';

  void _appendLog(String msg) {
    dnLog('[SharedPreferencesDemo] $msg');
    setState(() => _log = '$msg\n$_log');
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _appendLog('Ready — drop-in shared_preferences over FFI.');
    } catch (e, st) {
      _appendLog('[init] ERROR: $e\n$st');
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) {
      _appendLog('Not ready — getInstance() failed (see above).');
      return;
    }
    try {
      final count = (prefs.getInt('tap_count') ?? 0) + 1;
      await prefs.setInt('tap_count', count);
      await prefs.setBool('seen_demo', true);
      await prefs.setString('last_name', 'Alice');
      _appendLog('Saved → tap_count=$count, seen_demo=true, last_name=Alice');
    } catch (e, st) {
      _appendLog('[save] ERROR: $e\n$st');
    }
  }

  Future<void> _read() async {
    final prefs = _prefs;
    if (prefs == null) {
      _appendLog('Not ready — getInstance() failed (see above).');
      return;
    }
    try {
      // Show the raw nullable values: a missing key reads back as `(unset)`,
      // not a defaulted 0/false/empty — so `Clear all` is visibly effective.
      final count = prefs.getInt('tap_count');
      final seen = prefs.getBool('seen_demo');
      final name = prefs.getString('last_name');
      _appendLog(
          'Read back → tap_count=${count ?? '(unset)'}, '
          'seen_demo=${seen ?? '(unset)'}, last_name=${name ?? '(unset)'}');
    } catch (e, st) {
      _appendLog('[read] ERROR: $e\n$st');
    }
  }

  Future<void> _clear() async {
    try {
      await _prefs?.clear();
      _appendLog('Cleared — all values removed from the platform store.');
    } catch (e, st) {
      _appendLog('[clear] ERROR: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScaffold(
      title: 'SharedPreferences',
      subtitle:
          'Drop-in `package:shared_preferences` API backed by NSUserDefaults '
          '(iOS) / SharedPreferences (Android), wired through Dart FFI. '
          'No MethodChannel — safe to call from any isolate.',
      log: _log,
      actions: [
        _Action(
          label: 'Save values',
          hint: 'writes tap_count+1, a bool, a string',
          onTap: _save,
        ),
        _Action(
          label: 'Read back',
          hint: 'sync reads — shows current stored values',
          onTap: _read,
        ),
        _Action(
          label: 'Clear all',
          hint: 'removes everything saved by this demo',
          onTap: _clear,
        ),
      ],
    );
  }
}

// ── Shared panel UI helpers ────────────────────

class _Action {
  const _Action({required this.label, required this.hint, required this.onTap});
  final String label;
  final String hint;
  final Future<void> Function() onTap;
}

class _PanelScaffold extends StatelessWidget {
  const _PanelScaffold({
    required this.title,
    required this.subtitle,
    required this.log,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final String log;
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        // ── Action buttons with hints ────────────────────────────────────
        ...actions.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActionButton(action: a),
          ),
        ),
        const SizedBox(height: 8),
        // ── Output log ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: log.isEmpty
              ? const Text(
                  'Output appears here.',
                  style: TextStyle(color: Color(0xFF636366), fontSize: 13),
                )
              : Text(
                  log,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontFamily: 'Courier',
                    height: 1.5,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.hint,
                    style: const TextStyle(
                      color: Color(0xFF636366),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '›',
              style: TextStyle(color: Color(0xFF636366), fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
