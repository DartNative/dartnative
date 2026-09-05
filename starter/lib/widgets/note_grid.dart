import 'package:dartnative/dartnative.dart';

import '../state/notes_state.dart';
import 'note_card.dart';

/// The staggered grid of note cards, shared by the Notes and Favorites
/// sections. Give it the notes to show; it owns the rest.
///
/// Delete mode lives here rather than in either section: it is how the
/// grid is being looked at, not something the app knows about, and both
/// sections get the same behaviour for free.
class NoteGrid extends StatefulWidget {
  const NoteGrid({super.key, required this.notes, this.bottomPadding = 8});

  final List<Note> notes;

  /// Room left below the last card. Notes sits a floating button over the
  /// grid and reserves its height here, so the last row scrolls clear of it
  /// instead of stopping underneath.
  final double bottomPadding;

  @override
  State<NoteGrid> createState() => _NoteGridState();
}

class _NoteGridState extends State<NoteGrid> {
  /// Grid geometry. The card width derived from these is the width the
  /// text is measured against, so a card can never be measured against a
  /// width it is not given.
  static const double _padding = 16;
  static const double _gap = 10;
  static const int _columns = 2;

  /// Entrance cascade: each card waits this much longer than the one
  /// before it, so the grid lays itself down top to bottom instead of
  /// appearing all at once. Capped so a long list never leaves the last
  /// cards waiting: past the cap they all arrive together, which is off
  /// screen anyway.
  static const _stagger = Duration(milliseconds: 55);
  static const _maxStaggered = 12;

  /// Every card waits at least this long, the first row included. Without
  /// it the first card starts fading during mount and is already part way
  /// in when the grid's first frame paints, so the top row looks like it
  /// skipped the animation while the rest cascade.
  static const _leadIn = Duration(milliseconds: 60);

  bool _editing = false;

  /// True only for the build that opens the screen. Cards laid out in
  /// that build cascade in; anything built afterwards, a saved note or a
  /// card the grid rebuilt around a deletion, simply takes its place.
  /// Tied to the opening BUILD rather than to a stretch of time, so a
  /// note saved a second after opening cannot slip into the entrance.
  bool _opening = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _opening = false);
  }

  void _startEditing() {
    if (_editing) return;
    // Felt before it is seen, the way the home screen does it.
    HapticFeedback.mediumImpact();
    setState(() => _editing = true);
  }

  void _exitEditing() {
    if (!_editing) return;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth =
        (screenWidth - _padding * 2 - _gap * (_columns - 1)) / _columns;

    return MasonryGridView.builder(
      crossAxisCount: _columns,
      mainAxisSpacing: _gap,
      crossAxisSpacing: _gap,
      padding: EdgeInsets.fromLTRB(
          _padding, 8, _padding, widget.bottomPadding),
      itemCount: widget.notes.length,
      // Heights come up front so each card drops into the shortest column.
      itemHeightBuilder: (i) => noteCardHeight(widget.notes[i], cardWidth),
      itemBuilder: (_, i) => NoteCard(
        // A key per note, so a card keeps its own state (and its finished
        // entrance) when the list around it changes.
        key: ValueKey(widget.notes[i].id),
        note: widget.notes[i],
        editing: _editing,
        onStartEditing: _startEditing,
        onExitEditing: _exitEditing,
        entranceDelay:
            _leadIn + _stagger * (i < _maxStaggered ? i : _maxStaggered),
        animate: _opening,
      ),
    );
  }
}
