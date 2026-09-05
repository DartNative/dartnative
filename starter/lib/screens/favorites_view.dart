import 'package:dartnative/dartnative.dart';

import '../repositories/app_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_grid.dart';

/// The Favorites section: the notes marked with the heart.
///
/// It owns no notes of its own. It watches the same NotesState the Notes
/// section watches, so a note saved over there is already here with
/// nothing to keep in sync by hand. That is the reason state lives in a
/// notifier and not inside a screen.
///
/// What it does own is WHICH notes this visit shows, and that is
/// deliberately not the live list. See [_shown].
class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  /// The ids this visit shows, taken when the section opened. Null until
  /// the notes have loaded.
  ///
  /// Unsaving writes to the database straight away but leaves the card on
  /// screen, with its heart now empty. A heart is a small target and an
  /// accidental tap would otherwise make the note vanish before the user
  /// could tell what happened, with no way back from this section. Keeping
  /// the card lets them tap again. The list is taken fresh on every visit,
  /// so leaving the section is what actually clears the unsaved ones.
  Set<int>? _shown;

  @override
  void initState() {
    super.initState();
    final notes = AppRepository.notesState;
    if (notes.isLoaded) {
      // The common path: Home or Notes already loaded them. Take the ids
      // now so the first frame is the real list.
      _shown = _favoriteIds();
    } else {
      _loadThenTake();
    }
  }

  Set<int> _favoriteIds() =>
      {for (final note in AppRepository.notesState.favorites) note.id};

  Future<void> _loadThenTake() async {
    await AppRepository.notesState.loadIfNeeded();
    if (!mounted) return;
    setState(() => _shown = _favoriteIds());
  }

  @override
  Widget build(BuildContext context) {
    final notesState = AppRepository.notesState..watch(context);
    final shown = _shown;

    if (shown == null) {
      // Still reading the database. Render nothing rather than the empty
      // state, which would flash "no favorites" before the list arrives.
      return const SizedBox();
    }

    // Membership comes from the snapshot, the cards themselves from the
    // live list: a note deleted here or edited elsewhere is reflected,
    // while an unsaved one stays put.
    final shownNotes = [
      for (final note in notesState.notes)
        if (shown.contains(note.id)) note,
    ];

    if (shownNotes.isEmpty) {
      return const EmptyState(
        // The same heart the message tells them to tap.
        icon: CupertinoIcons.heart,
        title: 'No favorites yet',
        message: 'Tap the heart on any note to keep it here.',
      );
    }

    // The same grid the Notes section renders, so a note looks and
    // behaves identically wherever it is seen.
    return NoteGrid(notes: shownNotes);
  }
}
