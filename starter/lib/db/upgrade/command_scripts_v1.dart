import 'package:dartnative/dartnative.dart' show dnLog;
import 'package:dartnative_sqlite/dartnative_sqlite.dart';

import '../tables.dart';
import 'sqlite_schema.dart';

/// Initial database schema, version 1.
///
/// This is the Note table as the starter first shipped it, and it stays
/// that way. For every schema change create a new file
/// (command_scripts_v2.dart, v3 and so on), extend [CommandScript], and
/// register it in LocalDatabase.
class CommandScriptV1 extends CommandScript {
  final String _debugPrefix = 'CommandScriptV1:';
  final int version = 1;

  @override
  Future<void> execute(SqliteBatch batch) async {
    dnLog('$_debugPrefix creating database schema V$version');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $noteTableName (
        $noteIdCol        INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        $noteTextCol      TEXT NOT NULL,
        $noteCreatedAtCol INTEGER NOT NULL
      )
    ''');
  }
}
