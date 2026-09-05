import 'package:dartnative/dartnative.dart' show dnLog;
import 'package:dartnative_sqlite/dartnative_sqlite.dart';

import '../tables.dart';
import 'sqlite_schema.dart';

/// Schema version 2, the worked example of a migration: adds the favorite
/// flag behind the heart on a note row.
///
/// is_favorite : 1 when the user saved this note to Favorites.
class CommandScriptV2 extends CommandScript {
  final String _debugPrefix = 'CommandScriptV2:';
  final int version = 2;

  @override
  Future<void> execute(SqliteBatch batch) async {
    dnLog('$_debugPrefix migrating to schema V$version');

    // DEFAULT 0 answers the new column for every note already on the
    // device, so an upgrade adds the feature without touching the notes.
    batch.execute(
      'ALTER TABLE $noteTableName '
      'ADD COLUMN $noteIsFavoriteCol INTEGER NOT NULL DEFAULT 0',
    );

    // Favorites reads this column on every rebuild of the section.
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_note_is_favorite '
      'ON $noteTableName($noteIsFavoriteCol)',
    );
  }
}
