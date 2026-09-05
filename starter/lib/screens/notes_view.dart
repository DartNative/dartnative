import 'package:dartnative/dartnative.dart';

import '../repositories/app_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_editor.dart';
import '../widgets/note_grid.dart';

/// The Notes section: a masonry grid of note cards, and a button that opens
/// the editor sheet.
///
/// This is a drawer SECTION, not a screen: the home screen hosts it in
/// place when Notes is selected in the drawer (see home_screen.dart for
/// the two drawer patterns). It still demonstrates the state plus storage
/// pattern: the view watches NotesState and calls its methods, all SQL
/// stays behind the notifier.
class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

/// The floating button's height. The grid reserves it so the last row of
/// notes can scroll clear of the button instead of ending underneath it.
const double _kNewNoteHeight = 56;

class _NotesViewState extends State<NotesView> {
  @override
  void initState() {
    super.initState();
    AppRepository.notesState.loadIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final notesState = AppRepository.notesState..watch(context);
    final notes = notesState.notes;
    final p = (AppRepository.themeState..watch(context)).palette;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    // Loading and empty are different answers: while the database is
    // still opening, render nothing instead of a wrong "no notes yet".
    // With the boot warmup this branch is normally never seen.
    if (!notesState.isLoaded) {
      return const SizedBox();
    }

    // The button floats over the notes rather than sitting in a bar of its
    // own, so the grid keeps the full height and scrolls behind it.
    return Stack(
      // The grid takes the stack's full size. A stack sized by its content
      // hands a scroll view no height of its own, and the notes vanish.
      fit: StackFit.expand,
      children: [
        notes.isEmpty
            ? const EmptyState(
                icon: MaterialSymbolsRounded.description,
                title: 'No notes yet',
                message: 'Notes you add are stored in SQLite on this device.',
              )
            // The grid is shared with the Favorites section, so it
            // lives in widgets/ (see NoteGrid).
            : NoteGrid(
                notes: notes,
                // Clears the button: its height, the gap under it, and the
                // home indicator.
                bottomPadding: bottomInset + _kNewNoteHeight + 32,
              ),
        Positioned(
          left: 20,
          right: 20,
          bottom: bottomInset + 6,
          // The button keeps its label width and sits in the middle, the
          // size it had in the bar. Pinning both edges of the Positioned
          // would stretch it across the screen instead.
          child: Center(
            child: Button(
              title: 'New note',
              // iOS 26 hosts the control on its own glass. Prominent,
              // because that is the tinted member of the family: the plain
              // glass material stays neutral and would drop the app's own
              // colour. The tint is slightly transparent so the notes
              // travel under it rather than behind a solid slab.
              variant: isIOS26 ? ButtonVariant.prominentClearGlass : null,
              color: p.text.withOpacity(0.80),
              // The capsule takes p.text, so the label is its opposite:
              // white on the dark one, almost black on the light one. Not
              // the palette's own pair, which sits far enough off to read
              // as grey through the glass, and not pure black either.
              foregroundColor: p.brightness == Brightness.light
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF0A0A0C),
              elevation: 10,
              height: _kNewNoteHeight,
              // Widens the capsule around its label. An explicit padding
              // also replaces Apple's automatic glass insets, which is the
              // documented way to size a glass button yourself.
              padding: const EdgeInsets.symmetric(horizontal: 30),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              onPressed: () => showNoteEditor(context),
            ),
          ),
        ),
      ],
    );
  }
}
