import 'dart:io';

import 'package:dartnative/dartnative.dart' show dnLog;
import 'package:dartnative_path_provider/dartnative_path_provider.dart';
import 'package:dartnative_sqlite/dartnative_sqlite.dart';

import 'upgrade/command_scripts_v1.dart';
import 'upgrade/command_scripts_v2.dart';
import 'upgrade/sqlite_schema.dart';

/// SQLite singleton, the one and only local database engine.
///
/// Access it through [LocalDatabase.instance]. Never open the database
/// anywhere else: one connection, opened lazily on first use.
///
/// The schema itself lives in db/upgrade/ as one script per version, run
/// by [SQLiteSchema]. To grow it after the app has shipped:
///   1. Add the new table or column names to tables.dart.
///   2. Add db/upgrade/command_scripts_vN.dart with a [CommandScript].
///   3. Register it below and bump [_version] to match.
/// Fresh installs run every script in order and existing ones run only
/// what they are missing, so both end at the same schema with the
/// statements written once. See sqlite_schema.dart for why that matters.
class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static const int _version = 2;

  SqliteDatabase? _db;

  /// In flight or completed open, memoized so concurrent callers share one
  /// open. Memoizing the future (not the result) matters: two callers
  /// arriving together would otherwise both see null and open twice.
  Future<SqliteDatabase>? _openFuture;

  Future<SqliteDatabase> get db => _openFuture ??= _open();

  Future<SqliteDatabase> _open() async {
    try {
      final appDocDir = getApplicationDocumentsDirectory();
      final dbDir = Directory('$appDocDir/database');
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      // One script per schema version. Add a setCommand line for every new
      // version and bump _version above to match.
      final schema = SQLiteSchema()
        ..setCommand(1, CommandScriptV1())
        ..setCommand(2, CommandScriptV2());

      _db = await Sqlite.open(
        '${dbDir.path}/app.db',
        version: _version,
        onConfigure: (db) async {
          // Enforce referential integrity for FOREIGN KEY constraints.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: schema.create,
        onUpgrade: schema.upgrade,
        singleInstance: true,
      );
      dnLog('LocalDatabase: open, version $_version');
      return _db!;
    } catch (e) {
      // Do not cache a failed open. The next access retries from scratch.
      _openFuture = null;
      rethrow;
    }
  }

  /// Closes the connection. The next [db] access reopens it.
  Future<void> dispose() async {
    final current = _db;
    _db = null;
    _openFuture = null;
    await current?.close();
  }
}
