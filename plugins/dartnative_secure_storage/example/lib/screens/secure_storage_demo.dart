/// SecureStorage demo — standalone example for dartnative_secure_storage.
///
/// `flutter_secure_storage`-shaped API backed by the Keychain (iOS) /
/// EncryptedSharedPreferences (Android) over Dart FFI — no platform channel.
library;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_secure_storage/dartnative_secure_storage.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SecureStorageDemo extends StatefulWidget {
  const SecureStorageDemo({super.key});

  @override
  State<SecureStorageDemo> createState() => _SecureStorageDemoState();
}

class _SecureStorageDemoState extends State<SecureStorageDemo> {
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
          'Secure',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: const _SecureStoragePanel(),
    );
  }
}

// ── Secure Storage panel ───────────────────────

class _SecureStoragePanel extends StatefulWidget {
  const _SecureStoragePanel();

  @override
  State<_SecureStoragePanel> createState() => _SecureStoragePanelState();
}

class _SecureStoragePanelState extends State<_SecureStoragePanel> {
  final SecureStorage _secure = const SecureStorage();
  String _log = '';
  int _tokenIndex = 0;

  void _appendLog(String msg) {
    dnLog('[SecureStorageDemo] $msg');
    setState(() => _log = '$msg\n$_log');
  }

  /// JWT-shaped fake token so the demo looks realistic.
  String _makeToken(int n) =>
      'eyJhbGciOiJIUzI1NiJ9.demo${n.toString().padLeft(3, '0')}_user42.SzKbD9mQ';

  Future<void> _writeToken() async {
    try {
      _tokenIndex++;
      final token = _makeToken(_tokenIndex);
      await _secure.write(key: 'auth_token', value: token);
      _appendLog('✓ Saved\n  auth_token = $token');
    } catch (e, st) {
      _appendLog('[write] ERROR: $e\n$st');
    }
  }

  Future<void> _readToken() async {
    try {
      final token = await _secure.read(key: 'auth_token');
      if (token == null) {
        _appendLog('✗ Not found — write a token first.');
      } else {
        _appendLog('✓ Read\n  auth_token = $token');
      }
    } catch (e, st) {
      _appendLog('[read] ERROR: $e\n$st');
    }
  }

  Future<void> _deleteToken() async {
    try {
      await _secure.delete(key: 'auth_token');
      final verify = await _secure.read(key: 'auth_token');
      if (verify == null) {
        _appendLog('✓ Deleted — auth_token removed.');
      } else {
        _appendLog(
            '✗ Delete may have failed — read-back still returned:\n  $verify');
      }
    } catch (e, st) {
      _appendLog('[delete] ERROR: $e\n$st');
    }
  }

  Future<void> _deleteAll() async {
    try {
      await _secure.deleteAll();
      _tokenIndex = 0;
      _appendLog('✓ Cleared — all secure entries removed.');
    } catch (e, st) {
      _appendLog('[deleteAll] ERROR: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScaffold(
      title: 'SecureStorage',
      subtitle: 'Familiar `flutter_secure_storage` API. '
          'Keychain on iOS, EncryptedSharedPreferences on Android. '
          'Direct FFI — no platform channel.',
      log: _log,
      actions: [
        _Action(
          label: 'Save a token',
          hint: 'writes a new auth_token',
          onTap: _writeToken,
        ),
        _Action(
          label: 'Read it back',
          hint: 'reads and shows the saved token',
          onTap: _readToken,
        ),
        _Action(
          label: 'Delete token',
          hint: 'removes auth_token; read will return null',
          onTap: _deleteToken,
        ),
        _Action(
          label: 'Clear all',
          hint: 'removes every key written by this app',
          onTap: _deleteAll,
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
