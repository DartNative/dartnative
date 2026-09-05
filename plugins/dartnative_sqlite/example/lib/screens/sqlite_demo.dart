/// SQLite demo — standalone example for dartnative_sqlite.
///

/// A SQL database on device: insert rows, query them, run transactions
/// atomically — direct FFI to libsqlite3 via sqflite_common_ffi, no
/// MethodChannel and no Flutter engine. The documents path comes from
/// `dartnative_path_provider`.
library;

import 'dart:io' show Directory, Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_sqlite/dartnative_sqlite.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SqliteDemo extends StatefulWidget {
  const SqliteDemo({super.key});

  @override
  State<SqliteDemo> createState() => _SqliteDemoState();
}

class _SqliteDemoState extends State<SqliteDemo> {
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
          'SQLite',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: const _SqlitePanel(),
    );
  }
}

// ── SQLite panel ───────────────────────────────

class _SqlitePanel extends StatefulWidget {
  const _SqlitePanel();

  @override
  State<_SqlitePanel> createState() => _SqlitePanelState();
}

class _SqlitePanelState extends State<_SqlitePanel> {
  SqliteDatabase? _db;
  String _log = '';

  void _appendLog(String msg) {
    dnLog('[SqliteDemo] $msg');
    setState(() => _log = '$msg\n$_log');
  }

  @override
  void initState() {
    super.initState();
    _openDb();
  }

  Future<void> _openDb() async {
    try {
      // A production-tested open pattern:
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
