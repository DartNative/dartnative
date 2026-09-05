import 'package:dartnative/dartnative.dart'
    show ChangeNotifier, Signal, dnLog, signal;

import '../db/local_database.dart';
import '../db/tables.dart';
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';

/// One saved note.
///
/// Text and saved flag are [Signal]s, not plain fields, so a row can
/// subscribe to the one note it draws: changing a note repaints its row
/// alone, however long the list is. Adding and deleting change which rows
/// exist instead, and that stays the notifier's job.
class Note {
  Note({
    required this.id,
    required this.createdAt,
    required String text,
    required bool isFavorite,
  })  : text = signal(text),
        isFavorite = signal(isFavorite);

  final int id;
  final DateTime createdAt;
  final Signal<String> text;
  final Signal<bool> isFavorite;
}

/// Notes backed by the local SQLite database.
///
/// The demo for the state plus storage pattern: screens watch this
/// notifier and call its methods, the notifier talks to the database and
/// notifies when the list changes. The screen never touches SQL, the
/// database layer never touches widgets.
///
/// Two levels of update, on purpose: [add] and [delete] notify every
/// watcher because rows appear and disappear, while [updateText] and
/// [toggleFavorite] write one note's signals so one row repaints.
class NotesState extends ChangeNotifier {
  List<Note> _notes = const [];
  bool _loaded = false;

  List<Note> get notes => _notes;
  bool get isLoaded => _loaded;

  /// The notes marked with the heart, newest first.
  ///
  /// Filtered from the list already in memory instead of running a second
  /// query: the answer is right here, and a database round trip to get it
  /// would also mean two lists that can disagree.
  List<Note> get favorites => [
        for (final note in _notes)
          if (note.isFavorite.value) note,
      ];

  /// Loads the notes once. Safe to call from every screen visit.
  Future<void> loadIfNeeded() async {
    if (_loaded) return;
    await _seedOnce();
    await _reload();
    _loaded = true;
  }

  /// Sample notes for a fresh install, so the app opens with something to
  /// look at instead of an empty grid.
  ///
  /// Written once and remembered by a preference rather than by counting
  /// rows: someone who reads them and deletes them means it, and should
  /// not find them back after the next launch. Delete this method and its
  /// call above when you make the starter yours.
  Future<void> _seedOnce() async {
    if (SharedPrefs.instance.getBool(kPrefNotesSeeded) ?? false) return;
    try {
      final db = await LocalDatabase.instance.db;
      // Spread over the past few days, newest last in this list so the
      // grid shows them in a natural order.
      final now = DateTime.now();
      for (var i = 0; i < _sampleNotes.length; i++) {
        final (text, favorite) = _sampleNotes[i];
        await db.insert(noteTableName, {
          noteTextCol: text,
          noteCreatedAtCol: now
              .subtract(Duration(hours: (_sampleNotes.length - i) * 7))
              .millisecondsSinceEpoch,
          noteIsFavoriteCol: favorite ? 1 : 0,
        });
      }
      await SharedPrefs.instance.setBool(kPrefNotesSeeded, true);
    } catch (e) {
      dnLog('NotesState: seeding failed: $e');
    }
  }

  Future<void> add(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      final db = await LocalDatabase.instance.db;
      await db.insert(noteTableName, {
        noteTextCol: trimmed,
        noteCreatedAtCol: DateTime.now().millisecondsSinceEpoch,
      });
      // A row appeared: reload and notify, the whole list is different.
      await _reload();
    } catch (e) {
      dnLog('NotesState: add failed: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await LocalDatabase.instance.db;
      await db.delete(noteTableName, where: '$noteIdCol = ?', whereArgs: [id]);
      await _reload();
    } catch (e) {
      dnLog('NotesState: delete failed: $e');
    }
  }

  /// Rewrites one note's text, from the editor sheet.
  ///
  /// The database write and the signal write are the whole update: no
  /// reload and no notifyListeners, so only this note's row repaints.
  Future<void> updateText(int id, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final note = _byId(id);
    if (note == null) return;
    try {
      final db = await LocalDatabase.instance.db;
      await db.update(
        noteTableName,
        {noteTextCol: trimmed},
        where: '$noteIdCol = ?',
        whereArgs: [id],
      );
      note.text.value = trimmed;
    } catch (e) {
      dnLog('NotesState: updateText failed: $e');
    }
  }

  /// Saves or unsaves a note.
  ///
  /// The UPDATE of the demo: [add] inserts a row, [delete] removes one,
  /// this changes one in place. Touching only the signal is also why
  /// unsaving in Favorites repaints the heart without dropping the row.
  Future<void> toggleFavorite(int id) async {
    final note = _byId(id);
    if (note == null) return;
    final next = !note.isFavorite.value;
    try {
      final db = await LocalDatabase.instance.db;
      await db.update(
        noteTableName,
        {noteIsFavoriteCol: next ? 1 : 0},
        where: '$noteIdCol = ?',
        whereArgs: [id],
      );
      note.isFavorite.value = next;
    } catch (e) {
      dnLog('NotesState: toggleFavorite failed: $e');
    }
  }

  Note? _byId(int id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  Future<void> _reload() async {
    final db = await LocalDatabase.instance.db;
    final rows = await db.query(
      noteTableName,
      orderBy: '$noteCreatedAtCol DESC',
    );
    _notes = [
      for (final row in rows)
        Note(
          id: row[noteIdCol] as int,
          text: row[noteTextCol] as String,
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(row[noteCreatedAtCol] as int),
          // Read as a nullable int: a database created before version 2
          // and upgraded mid session can still hand back rows without it.
          isFavorite: (row[noteIsFavoriteCol] as int? ?? 0) != 0,
        ),
    ];
    notifyListeners();
  }
}

/// The notes a fresh install starts with, as (text, favourite) pairs.
/// Written to look like someone's actual notes: a few words here, a
/// paragraph there, work mixed with the rest of life.
const _sampleNotes = <(String, bool)>[
  ('Ring Dad on Sunday, he hates the evenings ☎️', false),
  ('Tom and Ellie moved, ask for the new address 📮', false),
  (
    'Sophie is thirty on the 14th and wants nothing, which means she '
        'wants everyone in one room. Book the back table at the Italian '
        'before someone else does. 🎂',
    true,
  ),
  (
    'Nan keeps asking for the garden photos from the summer. Print the '
        'six good ones, big enough for her to see without the glasses. ❤️',
    false,
  ),
  ('Batteries on charge tonight, all four', false),
  ('Call the framer back about the wide mount', false),
  ('Dentist moved me to the 9th, 8:20am 🦷', false),
  ('Gaffer tape, lens wipes, a spare cold shoe', false),
  (
    'The Kensington flat shoot got pushed to the 22nd. Ask if the '
        'blinds can stay open, the north room was the whole reason they '
        'called. 📐',
    false,
  ),
  (
    'Tax return: receipts are in the shoebox and the drive, the '
        'mileage is nowhere. Reconstruct it from the calendar before it '
        'gets any further away.',
    false,
  ),
  (
    'Print two of the Highgate frames for the hallway, the one with '
        'the dog looking away and the one nobody chose. ❤️',
    true,
  ),
  ('Sunday: nothing. Keep it that way ☕️', false),
  ('Renew the studio insurance before the 30th', false),
  ('Passport photos for Nan, Tuesday morning', false),
  ('Back tyre before the weekend 🚲', false),
  (
    'Framing quote for the cafe in Hoxton: 12 prints, A3, natural oak. '
        'They want them up before the reopening.',
    false,
  ),
  (
    'Second shooter for the Hartley wedding in June. Ask Priya first, '
        'she was steady with the family groups at Highgate. 🚀',
    false,
  ),
  (
    'Rebuild the portfolio: fewer sets, twelve at most, and the '
        'interiors first because that is the work I want more of. New '
        'about page too, the one up there is three years old and still '
        'says weddings only. ❤️',
    true,
  ),
  ('Prints from Whitfield, they shut at 6', false),
  ('Anna asked about family sessions, send her the two hour one 💌', false),
  ('That new place on Bermondsey Street, the green door ☕️', false),
  (
    'The October cards are still not on the second drive. Do it before '
        'Thursday, the Ferrari set alone is 180GB. 💾',
    false,
  ),
  (
    'Studio day Thursday: seamless white, two softboxes, the beauty dish '
        'if Ana wants the tighter look. Charge both bodies and the '
        'triggers on Wednesday night, and put the spare card in the bag '
        'this time. 📷❤️',
    true,
  ),
  ('Book the dentist', false),
  (
    'Editing backlog: the Ferrari wedding (480 keepers), Ana headshots, '
        'Casa Blu interiors. Headshots first, she needs them this week.',
    false,
  ),
  (
    'Marth and Luke, engagement shoot Saturday 4pm at the botanical '
        'garden. Golden hour starts 18:40 so we have time. Bring the 85mm '
        'and the small reflector. ❤️',
    true,
  ),
  (
    "Mum's birthday on the 14th. 🎁❤️ She kept talking about "
        'that ceramics workshop in London.',
    false,
  ),
  ('Milk, coffee, olive oil, something for Sunday 🥛🫒☕️', false),
  ('Lens rental, 24-70 back Thursday 🚀', false),
  ('Invoice 142 still unpaid. Chase on Monday. 💵', false),
  (
    'Darkroom corner: shelf above the sink for the chemicals, blackout '
        'curtain (measure first, I think 140x210), red LED instead of that '
        'old bulb. Maybe \$200 all in. ❤️🚀',
    true,
  ),
];
