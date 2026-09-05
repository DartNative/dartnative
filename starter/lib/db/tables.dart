/// Table and column names for the local SQLite database.
///
/// Always define names here, never as inline strings in queries. Renaming a
/// column then means one change, and a typo fails to compile instead of
/// failing at runtime.
library;

// ── Note ─────────────────────────────────────────────────────────────────
const String noteTableName = 'Note';
const String noteIdCol = 'n_id';
const String noteTextCol = 'n_text';
const String noteCreatedAtCol = 'n_created_at';
// Added in database version 2. Stored as 0 or 1: SQLite has no boolean.
const String noteIsFavoriteCol = 'n_is_favorite';
