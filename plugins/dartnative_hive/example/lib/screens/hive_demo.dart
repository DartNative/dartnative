/// Hive demo — standalone example for dartnative_hive.
///

/// Pure-Dart Hive (community edition): `Hive.initDartNative(path)` replaces
/// `Hive.initFlutter()`; in-memory after open, persists to disk on every write.
/// The documents path comes from `dartnative_path_provider`.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_hive/dartnative_hive.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class HiveDemo extends StatefulWidget {
  const HiveDemo({super.key});

  @override
  State<HiveDemo> createState() => _HiveDemoState();
}

class _HiveDemoState extends State<HiveDemo> {
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
          'Hive',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: const _HivePanel(),
    );
  }
}

// ── Hive panel ─────────────────────────────────

class _HivePanel extends StatefulWidget {
  const _HivePanel();

  @override
  State<_HivePanel> createState() => _HivePanelState();
}

class _HivePanelState extends State<_HivePanel> {
  Box<dynamic>? _box;
  String _log = '';
  bool _initStarted = false;

  void _appendLog(String msg) {
    dnLog('[HiveDemo] $msg');
    setState(() => _log = '$msg\n$_log');
  }

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    if (_initStarted) return;
    _initStarted = true;
    try {
      Hive.initDartNative(getApplicationDocumentsDirectory(), subDir: 'hive');
      _box = await Hive.openBox<dynamic>('demo');
      final counter = _box?.get('tap_count') ?? 0;
      _appendLog(
        'Box opened from disk.\n'
        'Tap count from previous session: $counter\n'
        'Reads are now instant (Hive keeps everything in memory after open).',
      );
    } catch (e, st) {
      _appendLog('[open] ERROR: $e\n$st');
    }
  }

  Future<void> _increment() async {
    final box = _box;
    if (box == null) {
      _appendLog('Still opening…');
      return;
    }
    final n = ((box.get('tap_count') as int?) ?? 0) + 1;
    await box.put('tap_count', n);
    _appendLog(
      'tap_count → $n\n  read: instant (in-memory)\n  write: persisted to disk',
    );
  }

  Future<void> _writeJson() async {
    final box = _box;
    if (box == null) return;
    final profile = <String, Object>{
      'name': 'Alice',
      'score': 99,
      'active': true,
    };
    await box.put('profile', profile);
    final back = box.get('profile');
    _appendLog('Saved Map:\n  $profile\nRead back:\n  $back');
  }

  Future<void> _clear() async {
    final box = _box;
    if (box == null) return;
    await box.clear();
    _appendLog('Box cleared — all entries removed.');
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScaffold(
      title: 'Hive',
      subtitle: 'Pure-Dart Hive (community edition) for dartnative — '
          '`Hive.initDartNative(path)` replaces `Hive.initFlutter()`. '
          'In-memory after open; persists to disk on every write.',
      log: _log,
      actions: [
        _Action(
          label: 'Tap to count',
          hint: 'sync read + write; persisted to disk',
          onTap: _increment,
        ),
        _Action(
          label: 'Save a Map',
          hint: 'put a struct, read it back immediately',
          onTap: _writeJson,
        ),
        _Action(
          label: 'Clear box',
          hint: 'deletes all entries from memory and disk',
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
        ...actions.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActionButton(action: a),
          ),
        ),
        const SizedBox(height: 8),
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
