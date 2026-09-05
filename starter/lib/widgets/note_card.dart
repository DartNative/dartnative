import 'dart:async';

import 'package:dartnative/dartnative.dart';

import '../repositories/app_repository.dart';
import '../theme.dart';
import '../state/notes_state.dart';
import 'note_editor.dart';

/// How many lines of a note a card shows before the ellipsis.
///
/// Lives here with the card that honours it, because the grid measures the
/// text against the same number to work out the card's height. Two places
/// reading one constant is what keeps the measurement and the render from
/// drifting apart.
const int kNoteCardMaxLines = 8;

/// How long one card's entrance takes. The grid reads it to know when the
/// cascade is over and later cards should simply appear.
const kNoteCardEntrance = Duration(milliseconds: 260);

/// The height of [note]'s card at [cardWidth].
///
/// A staggered grid needs every height BEFORE it lays anything out, so it
/// can drop each card into the shortest column. The text is the only part
/// that varies, so measure exactly it, at the width the card will really
/// get, and add the fixed chrome around it. It lives beside the card it
/// measures: the two read the same padding and the same line limit, which
/// is what keeps the measured height and the rendered one together.
double noteCardHeight(Note note, double cardWidth) {
  const horizontalPadding = 12 + 8 + 4; // card padding plus the text inset
  const cornerRow = 44; // the heart button's own tap area
  const verticalPadding = 8 + 12;

  final painter = TextPainter(
    text: TextSpan(
      text: note.text.value,
      style: const TextStyle(fontSize: 15, height: 1.35),
    ),
    maxLines: kNoteCardMaxLines,
  )..layout(maxWidth: cardWidth - horizontalPadding);

  return cornerRow + verticalPadding + painter.height;
}

/// The surface colour for [note], keyed by its id so a note keeps its
/// colour for life. Shared by the card and the note sheet, so a note that
/// opens carries the same colour it had in the grid.
Color noteCardColor(Palette p, Note note) =>
    p.cardColors[note.id % p.cardColors.length];

/// One note as a card in the masonry grid: the heart on the top right, the
/// text below, on a squircle surface.
///
/// It subscribes to the note it draws, not to the list, so editing or
/// hearting one note repaints that card only.
///
/// Deleting follows the home screen pattern: a long press puts the grid in
/// [editing] mode, every card wobbles, and the heart's place is taken by a
/// circled X that removes the note. Nothing is destructive by accident, and
/// nothing needs a permanent bin button taking up room in every card.
class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.editing,
    required this.onStartEditing,
    required this.onExitEditing,
    required this.entranceDelay,
    required this.animate,
  });

  final Note note;

  /// True while the grid is in delete mode.
  final bool editing;

  final VoidCallback onStartEditing;
  final VoidCallback onExitEditing;

  /// How long this card waits before fading in, which is what turns a set
  /// of identical fades into a cascade down the grid.
  final Duration entranceDelay;

  /// False once the grid has already played its entrance. A card built
  /// after that belongs to a grid the user is looking at, so it takes its
  /// place rather than fading in.
  final bool animate;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with TickerProviderStateMixin {
  /// One wobble leg. It repeats reversed, so a full cycle is twice this.
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  /// The entrance: the card fades up while growing the last few percent,
  /// so it settles into its slot instead of blinking into place.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: kNoteCardEntrance,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _entrance, curve: Curves.easeOut);

  /// One leg of the heart's pulse. Saving a note swells the glyph and lets
  /// it settle, so the tap has a reply of its own. Unsaving stays quiet:
  /// the heart emptying is the answer there.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _pulse.reverse();
    });
  late final Animation<double> _pulseCurve =
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut);

  Timer? _entranceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.editing) _wobble.repeat(reverse: true);
    // The card holds at zero until its turn comes, which staggers the grid
    // top to bottom. Cards never move: only opacity and scale animate, so
    // the masonry measurement is untouched.
    if (!widget.animate) {
      _entrance.value = 1;
      return;
    }
    _entranceTimer = Timer(widget.entranceDelay, () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing == oldWidget.editing) return;
    if (widget.editing) {
      _wobble.repeat(reverse: true);
    } else {
      _wobble.stop();
      _wobble.reset();
    }
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _entrance.dispose();
    _wobble.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _delete() {
    AppRepository.notesState.delete(widget.note.id);
  }

  void _toggleFavorite() {
    final saving = !widget.note.isFavorite.value;
    AppRepository.notesState.toggleFavorite(widget.note.id);
    if (saving) _pulse.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = (AppRepository.themeState..watch(context)).palette;
    // Watching this note's own values: a change here repaints this card and
    // leaves the rest of the grid alone.
    final text = widget.note.text.watch(context);
    final isFavorite = widget.note.isFavorite.watch(context);

    final cardColor = noteCardColor(p, widget.note);

    final card = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: ShapeDecoration(
        color: cardColor,
        // Squircle: the continuous curve iOS uses for its own cards.
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // The corner holds one control at a time: the heart normally,
              // the delete badge while the grid is in delete mode.
              widget.editing
                  ? _DeleteBadge(onTap: _delete)
                  : IconButton(
                      // Only the glyph scales, so the button's tap target
                      // and the row's height stay put.
                      icon: AnimatedBuilder(
                        animation: _pulseCurve,
                        builder: (_, child) => Transform.scale(
                          scale: 1 + 0.3 * _pulseCurve.value,
                          child: child,
                        ),
                        child: Icon(
                          isFavorite
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: isFavorite ? p.accent : p.text,
                          size: 22,
                        ),
                      ),
                      onPressed: _toggleFavorite,
                    ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              text,
              // A card is a preview. The full note is in the editor.
              maxLines: kNoteCardMaxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.text, fontSize: 15, height: 1.35),
            ),
          ),
        ],
      ),
    );

    final tappable = GestureDetector(
      // In delete mode a tap anywhere on the card leaves that mode, which is
      // the way out for anyone who opened it by accident.
      onTap: widget.editing
          ? widget.onExitEditing
          : () => showNoteEditor(context, note: widget.note),
      onLongPress: widget.editing ? null : widget.onStartEditing,
      behavior: HitTestBehavior.opaque,
      child: widget.editing
          ? AnimatedBuilder(
              animation: _wobble,
              builder: (_, child) => Transform.rotate(
                // Value runs 0 to 1 and back, so this swings both ways.
                // Odd ids start the other way, so cards do not wobble in
                // lockstep.
                angle: (_wobble.value * 2 - 1) *
                    0.018 *
                    (widget.note.id.isEven ? 1 : -1),
                child: child,
              ),
              child: card,
            )
          : card,
    );

    // The entrance rides OUTSIDE the gesture detector: only opacity and a
    // small scale change, so the card's slot never moves and the masonry
    // measurement is untouched.
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(scale: 0.94 + 0.06 * _fade.value, child: child),
      ),
      child: tappable,
    );
  }
}

/// The circled X in the card corner while the grid is in delete mode.
class _DeleteBadge extends StatelessWidget {
  const _DeleteBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = (AppRepository.themeState..watch(context)).palette;
    return IconButton(
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.xmark,
            color: const Color(0xFFFFFFFF),
            size: 13,
          ),
        ),
      ),
      onPressed: onTap,
    );
  }
}
