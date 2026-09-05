/// Image picker composer: the attach-photos flow, replicated.
///
/// The flow, in the order it happens on screen: a pill composer at rest,
/// "+" opening a panel of sources over the chat with the keyboard still
/// up, Photos handing over to the system picker
/// (`PHPickerViewController` on iOS, `PickVisualMedia` on Android),
/// the picked photos returning as large thumbnails inside the composer
/// with a badge each to drop them, and send moving them into a message.
///
/// Why it is worth a demo: two native surfaces take turns over one
/// screen. The field is a real `UITextField` / Android `EditText`, so the
/// keyboard is the system's own, and the picker is the system's own too.
/// Nothing here is a Skia repaint of a control.
///
/// The source panel is composed rather than native on purpose: dartnative
/// lowers native menus on bar items (`BarButtonItem.menu`) and not yet on
/// a button in content. The app this replicates composes its panel too:
/// circular icon chips beside the labels, which no system menu draws.
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_media_picker/gallery.dart';

import '../home/demo_ui.dart' show playgroundPalette;
import 'gpt_attachment_panel.dart';
import 'gpt_photo_library.dart';

/// The measurements the composer shares with the panel (row height,
/// strip, thumbnails, the + button's place) live in
/// [gpt_attachment_panel.dart]. The panel is anchored to this composer,
/// so a number that disagrees puts the panel in the wrong place and lands
/// the photos beside the strip instead of on it.
///
/// What is left here is the composer's own.
const double _kRadius = 24;
const double _kRowPaddingRight = 9;
const double _kRowGap = 10;

const double _kMicSize = 20;
const double _kFieldSize = 17;
const double _kActionSize = 30;

/// The ✕ badge on a picked photo. Three points over the app's own, which
/// reads small at this thumbnail size.
const double _kRemoveBadge = 20;
const double _kRemoveBadgeInset = 6;

/// How much further in the bar sits while its field is unfocused.
///
/// Measured off the app: with the keyboard down the + glyph starts at
/// x=53 and the send button ends at x=355; with it up they are at 27 and
/// 381. Both edges move 26pt, so the bar keeps its centre and grows 52pt
/// wider: 326pt at rest, 378 focused, on a 402pt screen.
const double _kRestInset = 26;

/// How long the bar takes to widen, and the shape of it. Fitted to the
/// same recording: 38% of the way at 83ms, 54% at 117ms, 85% at 217ms,
/// which is a decelerating quadratic over four hundred milliseconds.
const Duration _kWidthMove = Duration(milliseconds: 400);

/// How much wider the bar gets, each side, while the panel is open.
/// Measured off the app: the + moves about 7pt left and the send button
/// 7pt right. It is an inset rather than a scale, so the layout knows
/// where the + is.
const double _kComposerBump = 7;

/// How long to wait before paying the panel's one-time costs. Long enough
/// for the push onto this screen to have landed: the warm-up blocks for as
/// long as it takes, and doing that under a screen still sliding in is
/// the one place it would show.
const Duration _kPrewarmDelay = Duration(milliseconds: 350);

class ChatGptPickerDemo extends StatefulWidget {
  const ChatGptPickerDemo({super.key});

  @override
  State<ChatGptPickerDemo> createState() => _ChatGptPickerDemoState();
}

class _ChatGptPickerDemoState extends State<ChatGptPickerDemo>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();

  /// Focus drives the bar's width: it sits narrower and centred until the
  /// field is being typed into.
  final _fieldFocus = FocusNode();

  /// 0 the bar at rest → 1 the bar at full width.
  late final AnimationController _width = AnimationController(
    vsync: this,
    duration: _kWidthMove,
  );

  /// 0 the bar at rest → 1 the bar swollen while the panel is open.
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: kPanelMove,
  );
  final _scroll = ScrollController();

  /// Picked but not sent yet: the strip inside the composer.
  final _attachments = <GptAttachment>[];

  /// Sent messages, oldest first.
  final _messages = <_Sent>[];

  /// Read on mount, not when the panel opens: the reference implementation
  /// loads its library in a hook at screen level for exactly this reason,
  /// and it is why its grid appears with photos already in it.
  final _library = GptPhotoLibrary();

  /// True once there is something to send, which swaps the voice button
  /// for the send arrow, the way the app being replicated does.
  bool _armed = false;

  /// True while the attachment panel is up: the + glyph slides out of the
  /// way of the panel growing out of it.
  bool _panelOpen = false;

  /// Runs while the panel's one-time costs are being paid. See
  /// [_prewarmPanel].
  Future<void>? _warm;

  /// On the + button, so [_anchors] can measure where it really is.
  final _plusKey = GlobalKey();

  /// Photos whose flying copies have not landed yet. The composer's own
  /// thumbnails stay blank until they do, so a photo is never on screen
  /// twice.
  final _pending = <String>{};

  @override
  void initState() {
    super.initState();
    // The status bar is the system's, not the bar's: Android paints it
    // opaque white in a light system theme, which reads as a white band
    // above a dark screen. Transparent strip, icons on the palette's side.
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
    _bump.addListener(_repaint);
    _library.prime();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(_kPrewarmDelay);
      if (!mounted || _panelOpen) return;
      _warm = _prewarmPanel();
      await _warm;
      _warm = null;
    });
  }

  /// Builds the panel once and throws it away. The first overlay of a run
  /// costs about a quarter of a second more than every one after it, in
  /// setup that happens once per process, so it is paid here rather than
  /// under the tap.
  Future<void> _prewarmPanel() {
    return showGptAttachmentPanel(
      context,
      library: _library,
      anchors: _anchors,
      attachedCount: 0,
      onPicked: (_) {},
      onClosing: () {},
      onLanded: () {},
      prewarm: true,
    );
  }

  /// The screen's metrics as of the last build, so [_anchors] can be
  /// called without a context.
  MediaQueryData? _media;

  /// Where the composer is right now, read by the panel every frame: the
  /// bar widens as the field takes focus and the keyboard lifts it.
  ///
  /// The panel hangs off the composer's bottom edge, and reaches lower:
  /// the keyboard's area is its to cover, the home indicator is not.
  GptAnchors _anchors() {
    final media = _media;
    if (media == null) return const GptAnchors(composer: 0, panel: 0, plusX: 0);
    final keyboard = media.viewInsets.bottom;
    final inset = keyboard > 0 ? keyboard : media.padding.bottom;
    // The floor is the screen's, so it stays arithmetic.
    final panel =
        media.size.height - (keyboard > 0 ? kGutter : media.padding.bottom);

    // The + is measured, not calculated: with the keyboard up the bar is
    // placed against the keyboard's layout guide, which puts it 5pt above
    // where the arithmetic below says.
    final render = _plusKey.currentContext?.findRenderObject();
    if (render is RenderBox) {
      final origin = render.localToGlobal(Offset.zero);
      return GptAnchors(
        // The row is the last thing in the bar, so its bottom is the bar's.
        composer: origin.dy + kComposerRowHeight,
        panel: panel,
        plusX: origin.dx + kPlusHit / 2,
      );
    }
    // Before the first layout there is nothing to measure.
    return GptAnchors(
      composer: media.size.height - inset - kGutter,
      panel: panel,
      plusX: _barInset + kComposerRowPaddingLeft + kPlusHit / 2,
    );
  }

  void _repaint() => setState(() {});

  void _onFocus() {
    if (_fieldFocus.hasFocus) {
      _width.forward();
    } else {
      _width.reverse();
    }
  }

  /// The bar's side inset: its resting inset, less the width the field's
  /// focus has added, less the swell while the panel is open.
  double get _barInset =>
      kGutter +
      (1 - Curves.decelerate.transform(_width.value)) * _kRestInset -
      _bumpOut * _kComposerBump;

  /// The swell, on the panel's spring: bouncy going out, no bounce back.
  double get _bumpOut => _panelOpen
      ? kPanelSpring.transform(_bump.value)
      : 1 - kPanelSpringOut.transform(1 - _bump.value);

  @override
  void dispose() {
    _input.removeListener(_onTyped);
    _fieldFocus.removeListener(_onFocus);
    _fieldFocus.dispose();
    _width.dispose();
    _bump.dispose();
    _input.dispose();
    _library.dispose();
    super.dispose();
  }

  void _onTyped() {
    final armed = _input.text.trim().isNotEmpty || _attachments.isNotEmpty;
    if (armed != _armed) setState(() => _armed = armed);
  }

  /// Opens the attachment panel over the keyboard. The menu is not a
  /// separate popup: it is the panel's first shape, which then morphs into
  /// the grid, so there is nothing to present twice.
  Future<void> _openPanel() async {
    final room = kMaxSelection - _attachments.length;
    if (room <= 0) return;
    // A warm-up in flight is a frame away from finishing; letting it land
    // costs less than opening a second panel on top of it.
    if (_warm != null) await _warm;
    if (!mounted) return;
    setState(() => _panelOpen = true);
    _bump.forward();
    // The panel anchors to the + button, half a row above the composer's
    // bottom edge, and reads that anchor on every frame rather than being
    // handed it once. See [_anchors].
    await showGptAttachmentPanel(
      context,
      library: _library,
      anchors: _anchors,
      attachedCount: _attachments.length,
      // Fires as the photos leave the grid, not when they land: the strip
      // has to be opening while they are in the air, or they arrive at a
      // slot that is not there yet.
      // The panel is leaving: the + comes back into the space it is
      // vacating rather than waiting for the collapse to finish.
      onClosing: () {
        if (!mounted) return;
        setState(() => _panelOpen = false);
        _bump.reverse();
      },
      // The photos have landed on their slots: stop holding the
      // composer's own thumbnails back. This runs a frame before the
      // panel is torn down, so this happens while the screen is still
      // keeping up.
      onLanded: () {
        if (mounted) setState(_pending.clear);
      },
      onPicked: (picked) {
        if (!mounted || picked.isEmpty) return;
        setState(() {
          final taken = picked.take(room);
          _attachments.addAll(taken);
          _pending.addAll(taken.map((a) => a.assetId));
          _armed = true;
        });
      },
    );
    // A backstop: the callback above runs on the landing frame, and this
    // only matters for a close that never got there.
    if (!mounted || _pending.isEmpty) return;
    setState(_pending.clear);
  }

  void _remove(GptAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
      _armed = _input.text.trim().isNotEmpty || _attachments.isNotEmpty;
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    setState(() {
      _messages.add(_Sent(text: text, photos: List.of(_attachments)));
      _attachments.clear();
      _input.clear();
      _armed = false;
    });
    // Let the new bubble land before scrolling to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _media = MediaQuery.of(context);
    // Set before the first page can land: the cache is warmed at the size
    // the tiles ask for, and the tiles ask for a grid cell.
    _library.thumbSize = gptCellEdge(MediaQuery.of(context).size.width).round();
    return Scaffold(
      backgroundColor: gpt.background,
      // The screen's brightness is the palette's, not a preference: the
      // panel sits over the keyboard for most of its height, so a light
      // keyboard under a dark panel turns the whole thing grey.
      brightness: playgroundPalette.brightness,
      // iOS 26 keeps the bar transparent for the glass; elsewhere the bar
      // carries the palette explicitly so the pre-26 iOS bar matches too.
      appBar: AppBar(
        title: Text('ChatGPT Picker', style: TextStyle(color: gpt.text)),
        backgroundColor: isIOS26 ? const Color(0x00000000) : gpt.background,
      ),
      // The composer needs the bottom inset: without it the field sits on
      // the home indicator, where a tap is half swipe-up.
      // The panel is not in this tree at all: it lives in its own window
      // above the keyboard, so the screen is just the chat and the
      // composer.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const SizedBox()
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      children: [
                        for (final m in _messages) _SentBubble(message: m),
                      ],
                    ),
            ),
            _Composer(
              input: _input,
              focus: _fieldFocus,
              plusKey: _plusKey,
              inset: _barInset,
              attachments: _attachments,
              armed: _armed,
              pendingIds: _pending,
              onPlus: _openPanel,
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

/// The composer's one filled control: the voice button until there is
/// something to send, the send arrow after. Blue with a white glyph in
/// light, white with a dark one in dark.
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

/// The pill at rest, which grows a photo strip above its input row once
/// something is attached. One surface either way, so the field never
/// moves out from under the keyboard while photos come and go.
class _Composer extends StatefulWidget {
  const _Composer({
    required this.input,
    required this.focus,
    required this.plusKey,
    required this.inset,
    required this.attachments,
    required this.armed,
    required this.pendingIds,
    required this.onPlus,
    required this.onRemove,
    required this.onSend,
  });

  final TextEditingController input;
  final FocusNode focus;

  /// Put on the + button, so the screen can measure where it ended up.
  final GlobalKey plusKey;

  /// The bar's side inset. Narrower means a wider inset: the bar sits in
  /// from both edges while its field is unfocused, and grows to the
  /// screen's gutter once it is being typed into.
  final double inset;

  final List<GptAttachment> attachments;
  final bool armed;

  /// Photos still in the air. Their slots are open and empty.
  final Set<String> pendingIds;

  final VoidCallback onPlus;
  final void Function(GptAttachment attachment) onRemove;
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

  /// The strip has to outlive its last attachment: the list empties on the
  /// tap that drops the photo, but the strip spends the next third of a
  /// second closing, and an empty strip has nothing left in it to shrink
  /// away.
  List<GptAttachment> _retained = const [];

  @override
  void initState() {
    super.initState();
    _strip.addListener(_repaint);
    _retained = List.of(widget.attachments);
    if (_retained.isNotEmpty) _strip.value = 1;
  }

  @override
  void didUpdateWidget(_Composer old) {
    super.didUpdateWidget(old);
    if (widget.attachments.isNotEmpty) {
      _retained = List.of(widget.attachments);
      _strip.forward();
    } else if (_strip.value > 0) {
      // The photos are dropped once the strip is shut, not before.
      _strip.reverse().whenComplete(() {
        if (!mounted || widget.attachments.isNotEmpty) return;
        setState(() => _retained = const []);
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
    // The strip is the panel's spring with the bounce taken out, and a
    // spring read backwards is the same curve mirrored.
    final t = widget.attachments.isEmpty
        ? 1 - kPanelSpringOut.transform(1 - _strip.value)
        : kPanelSpringOut.transform(_strip.value);
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.inset, 4, widget.inset, kGutter),
      child: _BarSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only the strip's height animates. Its contents keep their
            // full size and are pinned to the top of the clip, so the
            // photos rise out of the text row as it opens and slide back
            // down into it rather than squashing.
            //
            // The radius is the composer's own, pulled in by the strip's
            // inset so the two curves stay concentric.
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_kRadius - kStripPaddingTop),
              ),
              child: SizedBox(
                width: double.infinity,
                height: t * kStripHeight,
                child: Stack(
                  children: [
                    if (_retained.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: kStripPaddingTop,
                        height: kThumbSize,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.only(left: kStripPaddingTop),
                          children: [
                            // A gap between the photos, not after each
                            // one: a trailing gap on top of the strip's
                            // own inset is what pushed the last photo
                            // against the bar's edge and made it read as
                            // the odd one out.
                            for (var i = 0; i < _retained.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  right:
                                      i == _retained.length - 1 ? 0 : kThumbGap,
                                ),
                                child: _Thumb(
                                  attachment: _retained[i],
                                  pending: widget.pendingIds
                                      .contains(_retained[i].assetId),
                                  onRemove: () => widget.onRemove(_retained[i]),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: kComposerRowHeight),
              // Bottom-aligned: the icons hold the 48pt line the anchors
              // measure while a multiline field grows upward past it.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: kComposerRowPaddingLeft),
                  // The + does not move and does not fade. The panel
                  // grows out from under it wearing the bar's own colour,
                  // so the glyph is on top of it the whole way. That is
                  // why the app never shows an empty slot, and why
                  // nothing has to be timed to bring the + back.
                  GestureDetector(
                    onTap: widget.onPlus,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      key: widget.plusKey,
                      width: kPlusHit,
                      height: kComposerRowHeight,
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.plus,
                        color: gpt.text,
                        size: kPlusSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: _kRowGap),
                  Expanded(
                    child: TextField(
                      controller: widget.input,
                      focusNode: widget.focus,
                      decoration: InputDecoration(
                        hintText: 'Ask anything',
                        hintStyle: TextStyle(color: gpt.placeholder),
                        border: InputBorder.none,
                        // Vertical padding sizes ONE line to the row's
                        // 48pt, so the text centres on the icons' line;
                        // the bottom-aligned row otherwise leaves a short
                        // field sitting low. Extra lines grow past it.
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      // Multiline, as the app's own composer is: Return
                      // inserts a newline and the bar grows with the text.
                      // This lowers to the same native class as the chat
                      // demo's composer.
                      minLines: 1,
                      maxLines: 6,
                      style: TextStyle(color: gpt.text, fontSize: _kFieldSize),
                    ),
                  ),
                  const SizedBox(width: _kRowGap),
                  SizedBox(
                    height: kComposerRowHeight,
                    child: Center(
                      child: Icon(CupertinoIcons.mic,
                          color: gpt.text, size: _kMicSize),
                    ),
                  ),
                  const SizedBox(width: _kRowGap),
                  // One white circle in both states: the voice button until
                  // there is something to send, the send arrow after.
                  GestureDetector(
                    onTap: widget.armed ? widget.onSend : () {},
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: kComposerRowHeight,
                      child: Center(
                        child: _SendCircle(armed: widget.armed),
                      ),
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

/// The composer bar's surface: glass, the way the app draws it, with the
/// flat sampled colour below iOS 26 where Liquid Glass does not exist.
///
/// On iOS 26 the glass draws its own edge in a dark theme. On a white
/// page it has little to separate it from the background, so the shadow
/// is worn there. Below iOS 26 there is no material at all, so it is worn
/// either way.
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
        // contentView (the system composition): the field stays fully
        // native while the glass presses on any touch in the bar.
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

/// One picked photo waiting to be sent, with the badge that drops it.
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.attachment,
    required this.pending,
    required this.onRemove,
  });

  final GptAttachment attachment;

  /// This photo's copy is still flying towards this slot. The slot holds
  /// its place and stays empty until it lands.
  final bool pending;

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Hidden, not swapped out. Its slot holds the same views either way,
    // so the photo is already loaded by the time the copy in the air
    // lands on it and there is no tree to rebuild when it does.
    return Opacity(
      opacity: pending ? 0 : 1,
      child: SizedBox(
        width: kThumbSize,
        height: kThumbSize,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kThumbRadius),
                // The library asset, not the exported file: on an iPhone
                // that file is usually a HEIC, which is why the strip came
                // up empty while its height was right. The reference draws
                // its strip from the asset id too.
                child: GalleryThumb(
                  assetId: attachment.assetId,
                  size: kThumbSize.round(),
                ),
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
        ),
      ),
    );
  }
}

// ── Rest state and sent messages ─────────────────────────────────────────

class _Sent {
  const _Sent({required this.text, required this.photos});

  final String text;
  final List<GptAttachment> photos;
}

/// A sent message: its photos above its text, both inside one bubble.
class _SentBubble extends StatelessWidget {
  const _SentBubble({required this.message});

  final _Sent message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: gpt.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message.photos.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final photo in message.photos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: GalleryThumb(assetId: photo.assetId, size: 84),
                      ),
                    ),
                ],
              ),
            if (message.photos.isNotEmpty && message.text.isNotEmpty)
              const SizedBox(height: 8),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(color: gpt.text, fontSize: 16, height: 1.3),
              ),
          ],
        ),
      ),
    );
  }
}
