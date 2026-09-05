import 'dart:collection';

import 'package:dartnative/dartnative.dart' show dnLog;
import 'package:dartnative_sqlite/dartnative_sqlite.dart';

/// Orchestrates SQLite schema creation and version based migrations.
///
/// The reason for the indirection: [create] and [upgrade] end at the SAME
/// code path. A fresh install runs every script from 1 up, an install a few
/// versions behind runs only the ones it has not seen, and both arrive at
/// an identical schema. Writing the schema twice instead, once as a CREATE
/// for new installs and once as an ALTER for old ones, is what stops
/// scaling: every change has to be made in two places, and the day they
/// disagree only users who upgraded will see the bug.
///
/// Usage inside [LocalDatabase]:
///   final schema = SQLiteSchema();
///   schema.setCommand(1, CommandScriptV1());
///   schema.setCommand(2, CommandScriptV2()); // add when bumping version
class SQLiteSchema {
  factory SQLiteSchema() => _singleton;
  SQLiteSchema._internal();
  static final SQLiteSchema _singleton = SQLiteSchema._internal();

  /// Maps each schema version number to the command that migrates INTO it.
  final Map<int, CommandScript> versionCommands = HashMap();

  /// Registers a [CommandScript] to run when migrating to [version].
  void setCommand(int version, CommandScript command) {
    versionCommands[version] = command;
  }

  /// Called by [Sqlite.open]'s onCreate. Runs all scripts from 1 to
  /// [version], so a new install is just an upgrade that starts at zero.
  Future<void> create(SqliteDatabase db, int version) async {
    dnLog('SQLiteSchema: creating database ${db.path} at version $version');
    await upgrade(db, 0, version);
  }

  /// Called by [Sqlite.open]'s onUpgrade. Runs the scripts for each new
  /// version only, in order.
  Future<void> upgrade(
    SqliteDatabase db,
    int oldVersion,
    int newVersion,
  ) async {
    dnLog('SQLiteSchema: upgrading ${db.path} from v$oldVersion to v$newVersion');
    // One batch for the whole run: it commits in a single transaction, so a
    // migration that fails halfway leaves the old schema untouched instead
    // of a half migrated one no version number describes.
    final batch = db.batch();
    for (int v = oldVersion + 1; v <= newVersion; v++) {
      final command = versionCommands[v];
      await command?.execute(batch);
    }
    await batch.commit();
  }
}

/// Base class for the SQL statements belonging to one schema version.
///
/// Create one subclass per version bump (command_scripts_v1.dart, v2, v3
/// and so on) and register it via [SQLiteSchema.setCommand]. Never edit a
/// script that has already shipped: devices that ran it will not run it
/// again, so the change would reach new installs only.
abstract class CommandScript {
  Future<void> execute(SqliteBatch batch);
}
