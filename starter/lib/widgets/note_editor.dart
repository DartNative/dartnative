import 'dart:async';

import 'package:dartnative/dartnative.dart';

import '../repositories/app_repository.dart';
import '../state/notes_state.dart';
import 'note_card.dart';

/// Opens a note in a full height sheet, on the note's own colour.
///
/// One sheet, two states. An existing note opens in READ mode, showing its
/// text plainly, and the pencil in the corner turns the text into a field.
/// The New note button opens the same sheet already in edit mode.
///
/// The header is REAL bar items on the sheet's own navigation bar,
/// declared through a [SheetHeaderController] so it can follow the
/// sheet's state: the pencil becomes a save button, the copy icon ticks.
/// Real items are what give the copy and edit pair one shared glass
/// capsule with the system's press, which no composed header can draw.
Future<void> showNoteEditor(BuildContext context, {Note? note}) async {
  final p = AppRepository.themeState.palette;
  final header = SheetHeaderController();
  final created = await showModalSheet<String>(
    context: context,
    // Full height: a note is the whole subject once it is open.
    detent: SheetDetent.large,
    // A new note has no id yet, so no colour of its own.
    backgroundColor: note == null ? p.surface : noteCardColor(p, note),
    showDragHandle: true,
    headerController: header,
    builder: (_) => _NoteSheet(note: note, header: header),
  );

  // A new note comes back as text rather than being written from inside
  // the sheet. The wait is the sheet's own dismissal: the insert lands
  // once the grid is uncovered, so the new card is seen arriving.
  if (created == null || created.isEmpty) return;
  await Future<void>.delayed(const Duration(milliseconds: 320));
  await AppRepository.notesState.add(created);
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.note, required this.header});

  /// Null for a new note, which opens straight into edit mode.
  final Note? note;

  /// The sheet's system-bar header, re-declared whenever the mode flips.
  final SheetHeaderController header;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _input =
      TextEditingController(text: widget.note?.text.value ?? '');

  /// Every note opens in read mode, a new one showing a prompt. The field
  /// arrives on a tap, which keeps the sheet's entrance smooth (UIKit
  /// builds the keyboard on first focus) and lets the note be read
  /// without a keyboard covering half of it.
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _pushHeader();
  }

  /// The header as of this moment. Copy belongs to reading: while the
  /// field is open the text is the user's own draft and the keyboard
  /// already offers copy.
  SheetHeader _header() => SheetHeader(
        systemBar: true,
        title: widget.note == null
            ? 'New note'
            : (_editing ? 'Edit note' : 'Note'),
        close: BarButtonItem(
          icon: 'xmark',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_editing)
            BarButtonItem(
              // A tick for a moment after copying, the only sign that
              // anything happened.
              icon: _copied ? 'checkmark' : 'doc.on.doc',
              onPressed: _copy,
            ),
          BarButtonItem(
            icon: _editing ? 'checkmark' : 'pencil',
            onPressed: _editing ? _save : _startEditing,
          ),
        ],
      );

  void _pushHeader() => widget.header.update(_header());

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
    _pushHeader();
  }

  /// True for a moment after a copy, which turns the icon into a tick.
  bool _copied = false;
  Timer? _copiedTimer;

  void _copy() {
    final text = widget.note?.text.value ?? '';
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    // A copy changes nothing on screen, so it needs to be both felt and
    // seen or the button reads as broken.
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    _pushHeader();
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _copied = false);
      _pushHeader();
    });
  }

  Future<void> _save() async {
    final text = _input.text.trim();
    // Nothing typed: stay put rather than saving an empty note.
    if (text.isEmpty) return;
    final note = widget.note;
    if (note == null) {
      // Close first and hand the text back, so the card arrives in a grid
      // the user can see. Inserting here instead would rebuild the grid
      // behind the closing sheet, and the card's entrance would be over
      // before the sheet finished getting out of the way.
      Navigator.pop(context, text);
      return;
    }
    // Writes this note's signal, so the card behind the sheet is already
    // current when the sheet closes.
    await AppRepository.notesState.updateText(note.id, text);
    if (!mounted) return;
    setState(() => _editing = false);
    _pushHeader();
  }

  @override
  Widget build(BuildContext context) {
    final p = (AppRepository.themeState..watch(context)).palette;
    // Read mode shows the note as it stands, so it follows the signal.
    final text = widget.note?.text.watch(context) ?? '';

    // No header row here: the title and the buttons are REAL bar items on
    // the sheet's navigation bar, and the framework pads the content below
    // it natively.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _editing
                // No FieldShell here: the sheet already carries the note's
                // colour, so a surface behind the field would only inset
                // the text away from where it sits when reading.
                ? TextField(
                    controller: _input,
                    // Grows with the sheet instead of a fixed line count:
                    // the sheet is full height, so the field should be too.
                    minLines: 12,
                    maxLines: 24,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Write your note',
                      hintStyle: TextStyle(color: p.textFaint),
                      // The same insets the read-mode scroll view uses, so
                      // the text does not shift when the tap swaps the Text
                      // for the field. The default vertical 14 sat the
                      // first line 4pt lower and read as a jump.
                      contentPadding:
                          EdgeInsets.only(top: 10, left: 14, bottom: 14),
                    ),
                    style: TextStyle(color: p.text, fontSize: 17, height: 1.3),
                  )
                : GestureDetector(
                    // The whole page is the way in, not just the pencil.
                    onTap: _startEditing,
                    behavior: HitTestBehavior.opaque,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 10, left: 14),
                      child: Text(
                        text.isEmpty ? 'Write your note...' : text,
                        style: TextStyle(
                          color: text.isEmpty ? p.textFaint : p.text,
                          fontSize: 17,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
