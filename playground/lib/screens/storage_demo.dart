/// Storage Demo — four panels exercising the dartnative storage plugins.
///
/// Tab-based screen with one panel per storage layer:
///   1. Preferences  — `dartnative_shared_preferences` (NSUserDefaults / SharedPreferences via FFI)
///   2. SecureStorage — `dartnative_secure_storage` (Keychain / EncryptedSharedPreferences via FFI)
///   3. Hive          — `dartnative_hive` (file-backed key-value box)
///   4. SQLite        — `dartnative_sqlite` direct usage
///
/// All four are separate dartnative plugin packages, consuming the C symbols
/// shipped with `dartnative_ios` / `dartnative_android` via Dart FFI —
/// no MethodChannel, works under Flutter Zero from any isolate.
///
/// Navigate here from [StorageMenuScreen] with an [initialTab] value.
library;

import 'dart:io' show Directory, Platform;
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';
import 'package:dartnative_shared_preferences/dartnative_shared_preferences.dart';
import 'package:dartnative_secure_storage/dartnative_secure_storage.dart';
import 'package:dartnative_hive/dartnative_hive.dart';
import 'package:dartnative_sqlite/dartnative_sqlite.dart';
import 'home/demo_ui.dart';

// ── Tab enum ─────────────────────────────────────────────────────────────────

enum StorageTab { preferences, secureStorage, hive, sqlite }

// Documents/cache/etc. paths come from dartnative_path_provider
// (getApplicationDocumentsDirectory() and friends).

// ── Screen ────────────────────────────────────────────────────────────────────

class StorageDemo extends StatefulWidget {
  const StorageDemo({super.key, this.initialTab = StorageTab.preferences});

  final StorageTab initialTab;

  @override
  State<StorageDemo> createState() => _StorageDemoState();
}

class _StorageDemoState extends State<StorageDemo> {
  late StorageTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  static const _labels = ['Prefs', 'Secure', 'Hive', 'SQLite'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      appBar: AppBar(
        title: Text(
          'Storage Demo',
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
        child: Column(
          children: [
            // ── Tab bar ───────────────────────────────────────────────────
            // kBarBg: white in light (continuous with the AppBar above),
            // dark surface in dark.
            Container(
              color: kBarBg,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: StorageTab.values.map((t) {
                  final active = t == _tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? kTileBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _labels[t.index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? kTextPrimary : kTextSecondary,
                            fontSize: 12,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // ── Panel ──────────────────────────────────────────────────────
            Expanded(
              child: switch (_tab) {
                StorageTab.preferences => const _PreferencesPanel(),
                StorageTab.secureStorage => const _SecureStoragePanel(),
                StorageTab.hive => const _HivePanel(),
                StorageTab.sqlite => const _SqlitePanel(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── 1. Preferences panel ─────────────────────────────────────────────────────

class _PreferencesPanel extends StatefulWidget {
  const _PreferencesPanel();

  @override
  State<_PreferencesPanel> createState() => _PreferencesPanelState();
}

class _PreferencesPanelState extends State<_PreferencesPanel> {
  SharedPreferences? _prefs;
  String _log = '';

  void _appendLog(String msg) {
    dnLog('[StorageDemo/Prefs] $msg');
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
      _appendLog('Read back → tap_count=${count ?? '(unset)'}, '
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

// ── 2. Secure Storage panel ───────────────────────────────────────────────────

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
    dnLog('[StorageDemo/Secure] $msg');
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
      subtitle: 'Drop-in `flutter_secure_storage` API. '
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

// ── 3. Hive panel ────────────────────────────────────────────────────────────

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
    dnLog('[StorageDemo/Hive] $msg');
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

// ── 4. SQLite panel ───────────────────────────────────────────────────────────

class _SqlitePanel extends StatefulWidget {
  const _SqlitePanel();

  @override
  State<_SqlitePanel> createState() => _SqlitePanelState();
}

class _SqlitePanelState extends State<_SqlitePanel> {
  SqliteDatabase? _db;
  String _log = '';

  void _appendLog(String msg) {
    dnLog('[StorageDemo/SQLite] $msg');
    setState(() => _log = '$msg\n$_log');
  }

  @override
  void initState() {
    super.initState();
    _openDb();
  }

  Future<void> _openDb() async {
    try {
      // A production-ready pattern:
      //   1. Put the db in a `database/` subdir of documents (keeps WAL + SHM
      //      side files grouped, easy to back up / wipe).
      //   2. On iOS, create that subdir with `NSFileProtectionNone` so the
      //      DB can be opened from a background isolate while the device is
      //      locked (push-notification handler, background fetch).
      //      Mirrors `SqfliteDarwin.createUnprotectedFolder()` from the
      //      Flutter `sqflite_darwin` plugin — see
      //      https://github.com/tekartik/sqflite/issues/924.
      //   3. On Android, plain recursive mkdir.
      //   4. PRAGMA foreign_keys = ON in onConfigure (cascade deletes work).
      //   5. singleInstance: true (default in `Sqlite.open`) so re-opening
      //      from the same isolate returns the cached connection.
      final docsDir = getApplicationDocumentsDirectory();
      final dbDir = '$docsDir/database';
      if (Platform.isIOS) {
        final ok = await createUnprotectedFolder(
          parent: docsDir,
          name: 'database',
        );
        if (!ok) {
          _appendLog(
            '[open] WARN createUnprotectedFolder failed; '
            'DB will use default protection class — opening from a locked '
            'background isolate may fail.',
          );
        }
      } else {
        final dir = Directory(dbDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
      final dbPath = '$dbDir/storage_demo.db';

      _db = await Sqlite.open(
        dbPath,
        version: 1,
        onConfigure: (db) async {
          // Enable cascade deletes — must run before onCreate / onUpgrade.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, v) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS scores (
              id    INTEGER PRIMARY KEY AUTOINCREMENT,
              name  TEXT    NOT NULL,
              value INTEGER NOT NULL,
              ts    INTEGER NOT NULL
            )
          ''');
        },
        // singleInstance: true is the default — repeat opens from the same
        // isolate return the cached connection rather than re-opening.
      );
      _appendLog(
        'Database open: $dbPath\n'
        'Table: scores (id, name, value, ts)\n'
        'PRAGMA foreign_keys = ON · singleInstance: true\n'
        '${Platform.isIOS ? "Folder: NSFileProtectionNone (locked-device safe)\n" : ""}'
        'No MethodChannel — direct FFI to libsqlite3 via sqflite_common_ffi.',
      );
    } catch (e, st) {
      _appendLog('[open] ERROR: $e\n$st');
    }
  }

  Future<void> _insertRow() async {
    final db = _db;
    if (db == null) {
      _appendLog('Still opening…');
      return;
    }
    final names = ['Alice', 'Bob', 'Carol', 'Dave'];
    final name = names[DateTime.now().second % names.length];
    final value = DateTime.now().millisecondsSinceEpoch % 100;
    final id = await db.insert('scores', {
      'name': name,
      'value': value,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    _appendLog('INSERT → id=$id  name=$name  score=$value');
  }

  Future<void> _queryAll() async {
    final db = _db;
    if (db == null) return;
    final rows = await db.query('scores', orderBy: 'ts DESC', limit: 5);
    if (rows.isEmpty) {
      _appendLog('No rows yet — insert some first.');
      return;
    }
    final lines =
        rows.map((r) => '  ${r['name']}  score=${r['value']}').join('\n');
    _appendLog('SELECT last 5 rows:\n$lines');
  }

  Future<void> _runTransaction() async {
    final db = _db;
    if (db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert('scores', {'name': 'TxA', 'value': 10, 'ts': now});
      await txn.insert('scores', {'name': 'TxB', 'value': 20, 'ts': now + 1});
    });
    _appendLog(
        'Transaction committed — TxA and TxB inserted atomically.\nIf one fails, both roll back.');
  }

  Future<void> _dropAll() async {
    final db = _db;
    if (db == null) return;
    final count = await db.delete('scores');
    _appendLog('DELETE all → $count rows removed.');
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScaffold(
      title: 'SQLite',
      subtitle: 'A SQL database on device. Insert rows, query them, '
          'run transactions atomically — no MethodChannel, no Flutter engine.',
      log: _log,
      actions: [
        _Action(
          label: 'Insert a row',
          hint: 'adds one row with a random name and score',
          onTap: _insertRow,
        ),
        _Action(
          label: 'Show last 5 rows',
          hint: 'SELECT … ORDER BY ts DESC LIMIT 5',
          onTap: _queryAll,
        ),
        _Action(
          label: 'Insert 2 in a transaction',
          hint: 'both rows commit atomically or not at all',
          onTap: _runTransaction,
        ),
        _Action(
          label: 'Delete all rows',
          hint: 'DELETE FROM scores',
          onTap: _dropAll,
        ),
      ],
    );
  }
}

// ── Shared UI helpers ─────────────────────────────────────────────────────────

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
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: kTextSecondary,
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
            color: kRowBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: log.isEmpty
              ? Text(
                  'Output appears here.',
                  style: TextStyle(color: kTextTertiary, fontSize: 13),
                )
              : Text(
                  log,
                  style: TextStyle(
                    color: kTextSecondary,
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
          color: kRowBg,
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
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.hint,
                    style: TextStyle(
                      color: kTextTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: TextStyle(color: kTextTertiary, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
