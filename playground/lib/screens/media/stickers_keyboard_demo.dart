/// Sticker keyboard composer: the sticker flow of a messaging app.
///
/// The flow, in the order it happens on screen: the same pill composer the
/// picker demo uses, a sticker button on its right side, that button
/// opening a sheet over the keyboard, a tap on a sticker putting it in the
/// composer's strip, and send moving it into a message. The thread answers
/// back: the other side types for a moment, three dots in a bubble, then
/// replies to the first message with a question and to the second with
/// thanks, and says nothing more, enough to see a sticker land among
/// received bubbles as it would in a live chat. The thread grows from the
/// bottom, newest message lowest, as the chat screen demo keeps its own.
///
/// Why it is worth a demo: the sheet is a second native surface taking the
/// keyboard's place over the same screen, and everything inside it is a
/// live animation. Every sticker in the sheet plays at once, again in the
/// composer, and again in every bubble near the screen. What is not on
/// screen is not running: the sheet's grid and the thread are recycling
/// lists, so a cell or a bubble scrolled out of the window is released
/// and its sticker stops. The pack thumbnails in the row are the packs'
/// own first stickers, held on their first frame.
///
/// How the stickers are drawn, and why: every `Lottie` here asks for
/// `RenderCache.raster`, the plugin's frames renderer. A sticker keyboard
/// shows thirty animations at once and cycles through hundreds; the
/// platform's animation engine, the default, builds a layer tree per view
/// on the main thread, tens of milliseconds and several MB each, which a
/// grid of this size cannot afford on every pack. The frames renderer
/// draws each sticker once, off the main thread, at the size it is shown,
/// keeps the frames compressed in memory and on disk, and plays them as
/// bitmaps: a cell costs nothing to build, a pack seen before decodes
/// instead of drawing, and the main thread's share of playback is one
/// bitmap per sticker per frame. The first visit to a pack draws its
/// frames as it plays; the second is instant.
///
/// Where the rest of the cost is put: the sheet's entrance is kept clear
/// of everything else, the surface sliding in as a native transform on a
/// subtree built once, so no frame of the slide rebuilds or lays out the
/// grid. The screen warms the row's thumbnails and the first rows of the
/// opening pack while the chat is idle, through the plugin's pre-warm,
/// which renders their frames ahead of the sheet.
///
/// What the log says, one line per event under `stickers:`: what the warm
/// rendered and how long it took, the sheet's first frame timed from the
/// tap with the entry it opened on and whether the warm had finished by
/// then, and each pack as it is selected with its sticker count. In a
/// debug build the plugin adds its own `frames:` lines: each animation as
/// its frames complete, with their size and the time they took, and once a
/// second while anything plays, how many players tick and what a tick
/// costs.
///
/// What it shares with the picker demo: the composer's bar, its spring,
/// its strip and its send button all come from that screen's constants, so
/// the two read as one app. What differs is the surface over the keyboard,
/// a plain sheet with a header rather than a circle morphing out of the +.
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';

import '../home/demo_ui.dart' show playgroundPalette;
import 'gpt_attachment_panel.dart';

// ── The composer, shared with the picker demo ────────────────────────────

/// The pill's corner, its right padding and the gaps between its controls.
/// Same numbers as the picker demo's composer: the two screens show the
/// same bar with a different button on it.
const double _kRadius = 24;
const double _kRowPaddingRight = 9;
const double _kRowGap = 10;

const double _kFieldSize = 17;
const double _kActionSize = 30;
const double _kStickerSize = 24;

/// The ✕ badge on a picked sticker, and how far in from the corner it sits.
const double _kRemoveBadge = 20;
const double _kRemoveBadgeInset = 2;

/// How much further in the bar sits while its field is unfocused, and how
/// long it takes to widen. See the picker demo for where the numbers come
/// from; they are shared so the bars behave alike.
const double _kRestInset = 26;
const Duration _kWidthMove = Duration(milliseconds: 400);

// ── The sheet ────────────────────────────────────────────────────────────

/// How tall the sheet is, as a share of the screen. Sized to the keyboard
/// it replaces rather than to its contents: a sheet shorter than the
/// keyboard would show the page moving underneath it as it opens.
const double _kSheetScreenShare = 0.46;

/// The sheet's top corners. The bottom two are square: it sits on the
/// screen's edge, under the home indicator.
const double _kSheetRadius = 12;

/// The sheet's side inset, shared by the header's close control, the pack
/// row and the grid, so the three line up on one edge.
const double _kSheetInset = 16;

/// The header above the grid: the title's row, and the close control that
/// dismisses it. Same layout as the framework composes for a modal
/// sheet's declared header: the row inset 20 from the sides and 14 from
/// the top, a 17pt title centred over it, and on iOS 26 the close control
/// is the standalone system glass button the framework uses there.
/// Below iOS 26 and on Android it is the flat close control: a 30pt circle
/// in the tertiary fill with a secondary-label ✕.
const double _kHeaderInset = 20;
const double _kHeaderTop = 14;
const double _kHeaderTitleSize = 17;
const double _kCloseWell = 30;
const double _kCloseIcon = 20;

/// The pack row under the header: Recents first, then one thumbnail per
/// pack. Thumbnails sit bare on the row; only the selected one gets a
/// round well behind it.
const double _kStripHeight = 48;
const double _kChipSize = 28;
const double _kChipWell = 36;
const double _kChipGap = 20;
const double _kRecentGlyph = 22;

/// The grid: four across, as the reference sheet has it, on a square cell.
const int _kGridColumns = 4;
const double _kGridGap = 8;

/// How many stickers stay alive each side of the window, counted in items:
/// one row. Each live cell holds a decoded frame and a place in the
/// playback tick, so this is what bounds the sheet's memory and the work
/// per tick.
const int _kKeepAlive = 4;

/// How many stickers Recents remembers.
const int _kRecentLimit = 24;

/// How many messages the thread keeps built each side of its window,
/// counted in items. A bubble past that is released and its sticker
/// stops, so a long thread plays only what is near the screen.
const int _kThreadKeepAlive = 6;


/// How big a sticker is in the composer's strip and in a sent bubble.
const double _kStickerThumb = 72;
const double _kStickerBubble = 198;

/// The typing indicator: three dots this big, this far apart, bouncing
/// this high over one cycle this long, each a third of a cycle behind
/// the one before it.
const double _kDot = 8;
const double _kDotGap = 5;
const double _kDotBounce = 4;
const Duration _kDotCycle = Duration(milliseconds: 1100);

/// The sheet's own colours, over the picker demo's palette. UIKit's
/// tertiary fill and secondary label at their dark and light values, so
/// the close control and the selected well read as system controls on
/// the material.
Color get _sheetFill => playgroundPalette.brightness == Brightness.dark
    ? const Color(0x3D767680)
    : const Color(0x1F767680);

Color get _sheetSecondary => playgroundPalette.brightness == Brightness.dark
    ? const Color(0x99EBEBF5)
    : const Color(0x993C3C43);

// ── The packs ────────────────────────────────────────────────────────────

/// A sticker pack: its name, and its stickers as bundled asset paths. The
/// pack's first sticker is its thumbnail in the row.
class _StickerPack {
  const _StickerPack({required this.name, required this.stickers});

  final String name;
  final List<String> stickers;

  String get cover => stickers.first;
}

/// The packs bundled with the playground, each a folder of Lottie JSON
/// files under `assets/stickers/`, the sticker's number in the pack as the
/// file name. Hot Cherry opens first.
final _packs = [
  _StickerPack(
    name: 'Hot Cherry',
    stickers: [
      for (final n in const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '27', '28', '29', '30', '31', '32', '33'])
        'assets/stickers/hot_cherry/$n.json',
    ],
  ),
  _StickerPack(
    name: 'Mia Bunny',
    stickers: [
      for (final n in const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29'])
        'assets/stickers/mia_bunny/$n.json',
    ],
  ),
  _StickerPack(
    name: 'Daisy Romashka',
    stickers: [
      for (final n in const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24'])
        'assets/stickers/daisy_romashka/$n.json',
    ],
  ),
  _StickerPack(
    name: 'Duck',
    stickers: [
      for (final n in const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35'])
        'assets/stickers/duck/$n.json',
    ],
  ),
  _StickerPack(
    name: 'Baby Yoda',
    stickers: [
      for (final n in const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19'])
        'assets/stickers/baby_yoda/$n.json',
    ],
  ),
  _StickerPack(
    name: 'High Fox',
    stickers: [
      for (final n in const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19'])
        'assets/stickers/high_fox/$n.json',
    ],
  ),
  _StickerPack(
    name: 'World Art',
    stickers: [
      for (final n in const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'])
        'assets/stickers/world_art/$n.json',
    ],
  ),
];

/// What the screen pre-warms: every pack's thumbnail and the first three
/// rows of the tab the sheet will open on, Recents once anything has been
/// sent, the first pack before that. The plugin renders their frames
/// ahead, so those cells decode from the first tick and the sheet arrives
/// with its first screen in place; the frames stay, so a reopen needs no
/// warm. Computed at warm time, since Recents changes with every send.
List<String> _warmRows() {
  final opening = _recent.isEmpty ? _packs.first.stickers : _recent;
  return opening.take(_kGridColumns * 3).toList();
}

List<String> _warmCovers() => [for (final p in _packs) p.cover];

/// One grid cell's edge on a screen [width] wide: what the sheet's cells
/// are warmed at, so the frames are rendered at the size they are shown.
/// Floored to the point, which is where the grid lays its cells: frames
/// half a point larger are another size to the renderer.
double _cellEdge(double width) =>
    ((width - 2 * _kSheetInset - (_kGridColumns - 1) * _kGridGap) /
            _kGridColumns)
        .floorToDouble();

/// How long after the screen appears the warm starts: past the push
/// transition, whose frames the warm's own view work would otherwise
/// share.
const Duration _kWarmDelay = Duration(milliseconds: 700);

/// Recently sent stickers, newest first. Kept for the app's lifetime the
/// way a sticker keyboard keeps them: the sheet is torn down on every
/// close, so this lives outside it.
final _recent = <String>[];

/// When the sticker button was last tapped, and when the warm finished.
/// The sheet logs its first frame against the tap, and whether the warm
/// had finished by then: a slow first frame with the warm still pending
/// is the warm's cost, one with the warm done is the sheet's own.
DateTime? _sheetTapAt;
DateTime? _warmDoneAt;

/// What the other side of the thread answers, in the order of the
/// messages sent to it: a reply to the first, a reply to the second,
/// silence after.
const List<String> _kReplies = ['What?', 'Thank you! 😍'];

/// How long after a send the other side starts typing, one per reply, and
/// how long it types before the reply lands: long enough to read as a reply
/// rather than an echo of the send, and longer for the second, where the
/// answer is to a sticker rather than to a line of text.
const List<Duration> _kTypingDelays = [
  Duration(milliseconds: 2500),
  Duration(milliseconds: 3500),
];
const Duration _kTypingDuration = Duration(seconds: 2);


void _noteRecent(String sticker) {
  _recent.remove(sticker);
  _recent.insert(0, sticker);
  if (_recent.length > _kRecentLimit) _recent.removeLast();
}

class StickersKeyboardDemo extends StatefulWidget {
  const StickersKeyboardDemo({super.key});

  @override
  State<StickersKeyboardDemo> createState() => _StickersKeyboardDemoState();
}

class _StickersKeyboardDemoState extends State<StickersKeyboardDemo>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  final _fieldFocus = FocusNode();
  final _list = FastListController();

  /// 0 the bar at rest → 1 the bar at full width, as the field takes focus.
  late final AnimationController _width = AnimationController(
    vsync: this,
    duration: _kWidthMove,
  );

  /// Picked but not sent yet. One at a time, the way a sticker keyboard
  /// works: tapping a second sticker replaces the first rather than
  /// queueing it.
  String? _attached;

  /// The thread, newest first: the list is reversed, so index 0 sits at
  /// the bottom and a new message lands there.
  final _messages = <_Message>[];

  /// How many messages have been sent: the other side answers the first
  /// two and says nothing after.
  int _sent = 0;

  bool _armed = false;

  @override
  void initState() {
    super.initState();
    // The status bar is the system's: without this Android paints it
    // opaque in a light system theme, which reads as a band above a dark
    // screen. Same treatment as the picker demo.
    final dark = playgroundPalette.brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    _input.addListener(_onTyped);
    _fieldFocus.addListener(_onFocus);
    _width.addListener(_repaint);
    Future.delayed(_kWarmDelay, _warm);
  }

  /// Warms the sheet's opening screen, once, when the screen appears.
  Future<void> _warm() async {
    if (!mounted) return;
    final cell = _cellEdge(MediaQuery.sizeOf(context).width);
    final covers = _warmCovers();
    final rows = _warmRows();
    final started = DateTime.now();
    dnLog('stickers: warming ${covers.length} thumbnails and '
        '${rows.length} cells of the opening entry');
    // Thumbnails and cells are the same assets at two sizes; the frames
    // are rendered once per size, as the widgets show them.
    await Future.wait([
      LottiePreWarm.warmAssets(
        covers,
        size: const Size(_kChipSize, _kChipSize),
        renderCache: RenderCache.raster,
      ),
      LottiePreWarm.warmAssets(
        rows,
        size: Size(cell, cell),
        renderCache: RenderCache.raster,
      ),
    ]);
    _warmDoneAt = DateTime.now();
    dnLog('stickers: warm done in '
        '${_warmDoneAt!.difference(started).inMilliseconds}ms');
  }

  @override
  void dispose() {
    _input.removeListener(_onTyped);
    _fieldFocus.removeListener(_onFocus);
    _fieldFocus.dispose();
    _width.dispose();
    _input.dispose();
    super.dispose();
  }

  void _repaint() => setState(() {});

  void _onFocus() {
    if (_fieldFocus.hasFocus) {
      _width.forward();
    } else {
      _width.reverse();
    }
  }

  void _onTyped() {
    final armed = _input.text.trim().isNotEmpty || _attached != null;
    if (armed != _armed) setState(() => _armed = armed);
  }

  /// The bar's side inset: its resting inset, less the width the field's
  /// focus has added. The sheet does not swell the bar the way the
  /// picker's panel does, because it does not grow out of it.
  double get _barInset =>
      kGutter + (1 - Curves.decelerate.transform(_width.value)) * _kRestInset;

  /// Opens the sticker sheet over the keyboard.
  ///
  /// The keyboard stays up underneath: the overlay is its own window above
  /// it, so the field keeps focus and the caret keeps blinking while the
  /// sheet is on screen. That is the whole point of the surface, and it is
  /// why the sheet is sized to the keyboard rather than to its grid.
  Future<void> _openSheet() async {
    _sheetTapAt = DateTime.now();
    final picked = await showStickerSheet(context);
    if (!mounted || picked == null) return;
    setState(() {
      _attached = picked;
      _armed = true;
    });
  }

  void _remove() {
    setState(() {
      _attached = null;
      _armed = _input.text.trim().isNotEmpty;
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty && _attached == null) return;
    if (_attached != null) _noteRecent(_attached!);
    _post(_Message(text: text, sticker: _attached, fromMe: true));
    setState(() {
      _attached = null;
      _input.clear();
      _armed = false;
    });
    _sent += 1;
    if (_sent <= _kReplies.length) {
      final reply = _kReplies[_sent - 1];
      // The other side types first: a dots bubble takes the reply's place
      // at the bottom, then becomes the reply where it stands.
      final typing = _Message.typing();
      Future.delayed(_kTypingDelays[_sent - 1], () {
        if (!mounted) return;
        _post(typing);
        Future.delayed(_kTypingDuration, () {
          if (!mounted) return;
          final i = _messages.indexOf(typing);
          if (i < 0) return;
          setState(() {
            _messages[i] = _Message(text: reply, sticker: null, fromMe: false);
          });
        });
      });
    }
  }

  /// Puts a message at the bottom of the thread and brings the thread to
  /// it, as the chat screen demo does after a send: the scroll goes after
  /// the frame. The list's scroll call is immediate, so in the same turn
  /// as the insert it targets the list as it was, and a programmatic jump
  /// counts as the user scrolling, which mutes the reversed list's own
  /// anchoring for the insert; that is the small shift a same-turn call
  /// showed. After the frame, item 0 is the new message.
  void _post(_Message message) {
    setState(() => _messages.insert(0, message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _list.scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gpt.background,
      // The sheet covers the keyboard's area, so a light keyboard under a
      // dark sheet would turn the pair grey. The screen's brightness is
      // the palette's, as in the picker demo.
      brightness: playgroundPalette.brightness,
      appBar: AppBar(
        title: Text('Stickers Keyboard', style: TextStyle(color: gpt.text)),
        backgroundColor: isIOS26 ? const Color(0x00000000) : gpt.background,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const SizedBox()
                  : FastList(
                      controller: _list,
                      // Bottom up: index 0 is the newest message and sits
                      // at the bottom, so a new one lands where the eye
                      // is, with no scroll to reach it.
                      reverse: true,
                      itemCount: _messages.length,
                      // A recycling list, so a bubble scrolled out of the
                      // window is released: its sticker's view goes back
                      // to the plugin's pool, frozen, and is taken again
                      // as the bubble scrolls in. Only the window and one
                      // screen each side of it are live animations.
                      keepAliveCount: _kThreadKeepAlive,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      // Keyed by the message: the typing bubble and the
                      // reply that takes its place are different messages
                      // and different bubbles, so the reply is built fresh
                      // rather than made out of the dots bubble in place.
                      itemBuilder: (_, i) => _Bubble(
                        key: ValueKey(_messages[i].id),
                        message: _messages[i],
                      ),
                    ),
            ),
            _Composer(
              input: _input,
              focus: _fieldFocus,
              inset: _barInset,
              attached: _attached,
              armed: _armed,
              onSticker: _openSheet,
              onRemove: _remove,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Composer ─────────────────────────────────────────────────────────────

/// The pill at rest, which grows a strip above its input row once a
/// sticker is attached. One surface either way, so the field never moves
/// out from under the keyboard while the sticker comes and goes.
class _Composer extends StatefulWidget {
  const _Composer({
    required this.input,
    required this.focus,
    required this.inset,
    required this.attached,
    required this.armed,
    required this.onSticker,
    required this.onRemove,
    required this.onSend,
  });

  final TextEditingController input;
  final FocusNode focus;
  final double inset;

  /// The sticker waiting to be sent, if any.
  final String? attached;

  final bool armed;
  final VoidCallback onSticker;
  final VoidCallback onRemove;
  final VoidCallback onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> with TickerProviderStateMixin {
  /// 0 no strip → 1 strip fully open.
  late final AnimationController _strip = AnimationController(
    vsync: this,
    duration: kPanelMove,
  );

  /// The strip has to outlive its sticker: the field clears on the tap that
  /// drops it, but the strip spends the next third of a second closing, and
  /// an empty strip has nothing left in it to shrink away.
  String? _retained;

  @override
  void initState() {
    super.initState();
    _strip.addListener(_repaint);
    _retained = widget.attached;
    if (_retained != null) _strip.value = 1;
  }

  @override
  void didUpdateWidget(_Composer old) {
    super.didUpdateWidget(old);
    if (widget.attached != null) {
      _retained = widget.attached;
      _strip.forward();
    } else if (_strip.value > 0) {
      _strip.reverse().whenComplete(() {
        if (!mounted || widget.attached != null) return;
        setState(() => _retained = null);
      });
    }
  }

  @override
  void dispose() {
    _strip.dispose();
    super.dispose();
  }

  void _repaint() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // The picker demo's spring with the bounce taken out, read backwards
    // on the way in: the strip is the same movement on both screens.
    final t = widget.attached == null
        ? 1 - kPanelSpringOut.transform(1 - _strip.value)
        : kPanelSpringOut.transform(_strip.value);
    final stripHeight = kStripPaddingTop + _kStickerThumb + kStripGap;
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.inset, 4, widget.inset, kGutter),
      child: _BarSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only the strip's height animates. The sticker keeps its full
            // size and is pinned to the top of the clip, so it rises out
            // of the text row rather than squashing.
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_kRadius - kStripPaddingTop),
              ),
              child: SizedBox(
                width: double.infinity,
                height: t * stripHeight,
                child: Stack(
                  children: [
                    if (_retained != null)
                      Positioned(
                        left: kStripPaddingTop,
                        top: kStripPaddingTop,
                        width: _kStickerThumb,
                        height: _kStickerThumb,
                        child: _StripSticker(
                          sticker: _retained!,
                          onRemove: widget.onRemove,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kComposerRowHeight),
              // Bottom-aligned: the icons hold the row's line while a
              // multiline field grows upward past it.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: kComposerRowPaddingLeft),
                  Expanded(
                    child: TextField(
                      controller: widget.input,
                      focusNode: widget.focus,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: gpt.placeholder),
                        border: InputBorder.none,
                        // Vertical padding sizes one line to the row's
                        // height, so the text centres on the icons' line;
                        // the bottom-aligned row otherwise leaves a short
                        // field sitting low. Extra lines grow past it.
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 6,
                      style: TextStyle(color: gpt.text, fontSize: _kFieldSize),
                    ),
                  ),
                  const SizedBox(width: _kRowGap),
                  // The sticker button, this screen's own: where the
                  // picker demo puts its microphone. It does not take
                  // focus from the field, so the keyboard stays up and the
                  // sheet opens over it rather than in its place.
                  GestureDetector(
                    onTap: widget.onSticker,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: kComposerRowHeight,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.smiley,
                          color: gpt.text,
                          size: _kStickerSize,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: _kRowGap),
                  GestureDetector(
                    onTap: widget.armed ? widget.onSend : () {},
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: kComposerRowHeight,
                      child: Center(child: _SendCircle(armed: widget.armed)),
                    ),
                  ),
                  const SizedBox(width: _kRowPaddingRight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The composer's one filled control: the voice button until there is
/// something to send, the send arrow after.
class _SendCircle extends StatelessWidget {
  const _SendCircle({required this.armed});

  final bool armed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kActionSize,
      height: _kActionSize,
      decoration: BoxDecoration(
        color: gpt.action,
        borderRadius: BorderRadius.circular(_kActionSize / 2),
      ),
      child: Center(
        child: Icon(
          armed ? CupertinoIcons.arrow_up : CupertinoIcons.waveform,
          color: gpt.onAction,
          size: 18,
        ),
      ),
    );
  }
}

/// The composer bar's surface: glass on iOS 26, the flat sampled colour
/// below it. Same treatment as the picker demo's bar.
class _BarSurface extends StatelessWidget {
  const _BarSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = playgroundPalette.brightness == Brightness.light;
    final shadow = BoxShadow(
      color: Color(light ? 0x1A000000 : 0x66000000),
      blurRadius: 18,
      offset: const Offset(0, 4),
    );
    if (isIOS26) {
      return GlassEffectContainer(
        borderRadius: BorderRadius.circular(_kRadius),
        brightness: playgroundPalette.brightness,
        // Interactive glass hosts its children inside the effect view's
        // contentView, so the field stays fully native while the glass
        // presses on any touch in the bar.
        interactive: true,
        // The glass casts the shadow itself: a rounded box around
        // interactive glass clips the system press.
        shadow: light ? shadow : null,
        child: child,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: gpt.surface,
        borderRadius: BorderRadius.circular(_kRadius),
        boxShadow: [shadow],
      ),
      child: child,
    );
  }
}

/// The attached sticker in the composer, with the badge that drops it.
///
/// It plays here as it plays everywhere else. A still frame would be a
/// second representation to keep in step with the sheet and the bubble,
/// and there is nothing to gain by it: the same renderer draws all three.
class _StripSticker extends StatelessWidget {
  const _StripSticker({required this.sticker, required this.onRemove});

  final String sticker;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Lottie(
            asset: sticker,
            loop: true,
            autoplay: true,
            fit: LottieFit.contain,
            renderCache: RenderCache.raster,
          ),
        ),
        Positioned(
          top: _kRemoveBadgeInset,
          right: _kRemoveBadgeInset,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: _kRemoveBadge,
              height: _kRemoveBadge,
              decoration: BoxDecoration(
                color: const Color(0x73000000),
                borderRadius: BorderRadius.circular(_kRemoveBadge / 2),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.xmark,
                  color: Color(0xFFFFFFFF),
                  size: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── The sticker sheet ────────────────────────────────────────────────────

/// Opens the sticker sheet over the keyboard and completes with the
/// sticker that was tapped, or null if it was closed without one.
///
/// The overlay is a window of its own above the keyboard, which is what
/// keeps the field's focus, and the caret, alive underneath it.
Future<String?> showStickerSheet(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return showKeyboardOverlay<String>(
    context: context,
    builder: (_) => _StickerSheet(screenHeight: size.height),
  );
}

class _StickerSheet extends StatefulWidget {
  const _StickerSheet({required this.screenHeight});

  final double screenHeight;

  @override
  State<_StickerSheet> createState() => _StickerSheetState();
}

class _StickerSheetState extends State<_StickerSheet>
    with SingleTickerProviderStateMixin {
  /// 0 the sheet below the screen → 1 the sheet in place. The same spring
  /// the picker demo's panel rides, so the two surfaces arrive alike.
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: kPanelMove,
  );

  /// Which row entry is lit: 0 is Recents, then the packs in order. Opens
  /// on the first pack, as a sticker keyboard does when nothing has been
  /// sent yet.
  int _selected = _recent.isEmpty ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _open.forward();
    // Two stamps split a slow open: from the tap to here is the overlay
    // window and the sheet's own code reaching this state; from here to
    // the first frame is the build, the native layout and the installs.
    final tap = _sheetTapAt;
    if (tap != null) {
      dnLog('stickers: sheet state created '
          '${DateTime.now().difference(tap).inMilliseconds}ms after tap');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _logFirstFrame());
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  String get _entryName =>
      _selected == 0 ? 'Recents' : _packs[_selected - 1].name;

  /// One line per open: the sheet's first frame timed from the tap, the
  /// entry it opened on with its sticker count, and whether the warm had
  /// finished by then.
  void _logFirstFrame() {
    final tap = _sheetTapAt;
    final ms = tap == null ? -1 : DateTime.now().difference(tap).inMilliseconds;
    dnLog('stickers: sheet first frame ${ms}ms after tap, $_entryName, '
        '${_stickers.length} stickers, '
        '${_warmDoneAt == null ? 'warm pending' : 'warm done'}');
  }

  void _select(int i) {
    setState(() => _selected = i);
    dnLog('stickers: $_entryName, ${_stickers.length} stickers');
  }

  /// Closes the sheet, handing [picked] back to the composer. The sheet
  /// slides out before the overlay is torn down, so the keyboard is never
  /// seen through a half-transparent sheet.
  Future<void> _close(String? picked) async {
    await _open.reverse();
    if (mounted) Navigator.pop(context, picked);
  }

  List<String> get _stickers =>
      _selected == 0 ? _recent : _packs[_selected - 1].stickers;

  @override
  Widget build(BuildContext context) {
    final height = widget.screenHeight * _kSheetScreenShare;
    // Built once per state change, never per animation frame: the
    // AnimatedBuilder hands the same instance back on every tick, and the
    // reconciler skips a subtree whose widget has not changed. The slide
    // itself is a translate, a transform on the surface's own layer, so
    // no frame of it lays the header, the row or the grid out again.
    final sheet = Container(
      decoration: BoxDecoration(
        color: gpt.material,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_kSheetRadius),
        ),
      ),
      // Stretched, as the framework's own sheet header column is: the
      // header's row is otherwise sized to its one flow child, the close
      // button, and centred with the title over it.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(onClose: () => _close(null)),
          _PackRow(selected: _selected, onSelect: _select),
          Expanded(
            child: _stickers.isEmpty
                ? Center(
                    child: Text(
                      'Stickers you send show up here',
                      style: TextStyle(
                        color: gpt.placeholder,
                        fontSize: 15,
                      ),
                    ),
                  )
                : _StickerGrid(
                    // A new grid per row entry: the pack's stickers
                    // replace the last pack's, cell for cell.
                    key: ValueKey(_selected),
                    stickers: _stickers,
                    onPick: _close,
                  ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: height,
          child: AnimatedBuilder(
            animation: _open,
            child: sheet,
            // Off the bottom at rest, in place at 1: the sheet takes the
            // keyboard's area by sliding over it, the way a keyboard of
            // its own would appear.
            builder: (_, child) => Transform.translate(
              offset: Offset(
                0,
                (1 - kPanelSpring.transform(_open.value)) * height,
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// The stickers of the selected row entry, four across.
class _StickerGrid extends StatelessWidget {
  const _StickerGrid({super.key, required this.stickers, required this.onPick});

  final List<String> stickers;
  final void Function(String sticker) onPick;

  @override
  Widget build(BuildContext context) {
    return FastGrid(
      itemCount: stickers.length,
      crossAxisCount: _kGridColumns,
      childAspectRatio: 1,
      mainAxisSpacing: _kGridGap,
      crossAxisSpacing: _kGridGap,
      padding: const EdgeInsets.fromLTRB(
        _kSheetInset,
        0,
        _kSheetInset,
        _kSheetInset,
      ),
      // Every visible cell holds a decoded frame and takes a share of each
      // playback tick, so this is what keeps the sheet's memory and its
      // tick flat as it scrolls: cells outside the window are released and
      // made again as they come back, which costs nothing here. Counts
      // items.
      keepAliveCount: _kKeepAlive,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onPick(stickers[i]),
        behavior: HitTestBehavior.opaque,
        child: Lottie(
          asset: stickers[i],
          loop: true,
          autoplay: true,
          fit: LottieFit.contain,
          renderCache: RenderCache.raster,
        ),
      ),
    );
  }
}

/// The sheet's title row: the pack's name, and the close control. The
/// same composition the framework gives a modal sheet's declared header,
/// with the close control on the trailing edge as the reference sheet has
/// it: on iOS 26 a standalone system glass button carrying the SF Symbol,
/// elsewhere the flat circle.
class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kHeaderInset,
        _kHeaderTop,
        _kHeaderInset,
        0,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Text(
                'Stickers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gpt.text,
                  fontSize: _kHeaderTitleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Row(
            children: [
              const Spacer(),
              if (isIOS26)
                Button(
                  variant: ButtonVariant.glass,
                  imageAsset: 'xmark',
                  onPressed: onClose,
                )
              else
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: _kCloseWell,
                    height: _kCloseWell,
                    decoration: BoxDecoration(
                      color: _sheetFill,
                      borderRadius: BorderRadius.circular(_kCloseWell / 2),
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: _sheetSecondary,
                        size: _kCloseIcon,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The row under the header: Recents, then one thumbnail per pack. A
/// thumbnail is the pack's first sticker held on its first frame, drawn
/// by the same renderer as the cells and pre-warmed like the first rows,
/// so it is there as the sheet arrives.
///
/// The Recents glyph is the system's clock symbol drawn as an image by a
/// plain native button, not an icon-font glyph in a label: a label centres
/// its line box, and the font's glyph sits above that box's middle, which
/// put the clock a few points higher than the thumbnails beside it. An
/// image centres on its own bounds. Android has no symbol set, so it keeps
/// the font glyph.
class _PackRow extends StatelessWidget {
  const _PackRow({required this.selected, required this.onSelect});

  final int selected;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kStripHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kSheetInset - 4),
        children: [
          _Chip(
            selected: selected == 0,
            onTap: () => onSelect(0),
            child: Platform.isIOS
                ? Button(
                    variant: ButtonVariant.plain,
                    imageAsset: 'clock.fill',
                    imageSize: _kRecentGlyph,
                    foregroundColor: selected == 0 ? gpt.text : _sheetSecondary,
                    padding: EdgeInsets.zero,
                    width: _kChipSize,
                    height: _kChipSize,
                    onPressed: () => onSelect(0),
                  )
                : Icon(
                    CupertinoIcons.clock_fill,
                    color: selected == 0 ? gpt.text : _sheetSecondary,
                    size: _kRecentGlyph,
                  ),
          ),
          for (var i = 0; i < _packs.length; i++)
            _Chip(
              selected: selected == i + 1,
              onTap: () => onSelect(i + 1),
              child: Lottie(
                asset: _packs[i].cover,
                autoplay: false,
                fit: LottieFit.contain,
                renderCache: RenderCache.raster,
              ),
            ),
        ],
      ),
    );
  }
}

/// One entry of the pack row: a round well when selected, the bare
/// thumbnail or glyph otherwise, with the gap to the next entry built in.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: (_kChipGap - (_kChipWell - _kChipSize)) / 2,
        ),
        child: Center(
          child: Container(
            width: _kChipWell,
            height: _kChipWell,
            decoration: BoxDecoration(
              color: selected ? _sheetFill : const Color(0x00000000),
              borderRadius: BorderRadius.circular(_kChipWell / 2),
            ),
            child: Center(
              child: SizedBox(
                width: _kChipSize,
                height: _kChipSize,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── The thread ───────────────────────────────────────────────────────────

class _Message {
  _Message({
    required this.text,
    required this.sticker,
    required this.fromMe,
  })  : typing = false,
        id = _nextId++;

  /// The other side typing: a received bubble of dots in place of text,
  /// replaced by the reply where it stands.
  _Message.typing()
      : text = '',
        sticker = null,
        fromMe = false,
        typing = true,
        id = _nextId++;

  static int _nextId = 0;

  /// Its own number, the bubble's key: a reply taking a typing bubble's
  /// place is another message, so its bubble is built fresh.
  final int id;

  final String text;
  final String? sticker;

  /// Sent from this side, or received from the other.
  final bool fromMe;

  final bool typing;
}

/// Three dots bouncing in turn, the way a chat shows the other side
/// typing. One controller repeating; each dot reads the cycle a third
/// behind the one before it and rises on a half sine.
class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: _kDotCycle,
  )..repeat();

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  /// How far up dot [i] is at cycle position [t], 0 to 1: a bounce over
  /// the first half of its own third-shifted cycle, rest for the other.
  double _lift(double t, int i) {
    final local = (t - i / 3) % 1;
    if (local > 0.5) return 0;
    return math.sin(local * 2 * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cycle,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: _kDotGap),
            Transform.translate(
              offset: Offset(0, -_kDotBounce * _lift(_cycle.value, i)),
              child: Container(
                width: _kDot,
                height: _kDot,
                decoration: BoxDecoration(
                  color: widget.color
                      .withOpacity(0.45 + 0.55 * _lift(_cycle.value, i)),
                  borderRadius: BorderRadius.circular(_kDot / 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A message in the thread. Sent ones sit on the right in the action
/// colour, received ones on the left on the surface, each a bubble sized
/// to its words up to most of the width, as the chat screen demo's are.
/// A sticker on its own has no bubble behind it, the way a sticker sits
/// bare in a thread; a sticker with text keeps the bubble, with the
/// sticker above the words. The typing message is a received bubble
/// holding the dots.
class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final sticker = message.sticker;
    final mine = message.fromMe;
    final bare = sticker != null && message.text.isEmpty;
    final textStyle = TextStyle(
      color: mine ? gpt.onAction : gpt.text,
      fontSize: 16,
      height: 1.3,
    );
    final Widget content;
    if (message.typing) {
      content = _TypingDots(color: gpt.text);
    } else if (sticker == null) {
      content = Text(message.text, style: textStyle);
    } else {
      final stickerBox = SizedBox(
        width: _kStickerBubble,
        height: _kStickerBubble,
        // Still playing, in every bubble near the screen, from the same
        // frames the grid drew it with, at this size's own rendering;
        // released with its bubble as the thread scrolls it away.
        child: Lottie(
          asset: sticker,
          loop: true,
          autoplay: true,
          fit: LottieFit.contain,
          renderCache: RenderCache.raster,
        ),
      );
      content = bare
          ? stickerBox
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                stickerBox,
                const SizedBox(height: 8),
                Text(message.text, style: textStyle),
              ],
            );
    }
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: mine ? 48 : 0,
        right: mine ? 0 : 48,
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: bare
              ? EdgeInsets.zero
              : message.typing
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 14)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          decoration: bare
              ? null
              : BoxDecoration(
                  color: mine ? gpt.action : gpt.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
          child: content,
        ),
      ),
    );
  }
}
