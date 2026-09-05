/// The attachment panel: one surface that is the menu and then the grid.
///
/// Every number here is from the reference implementation's `constants.ts`
/// (SchroederNathan/react-native-motion, chatgpt-attachments), which took
/// them frame by frame off a recording of the real app. Where a value looks
/// oddly specific, that is why.
///
/// Two things make it read the way it does. It lives above the keyboard
/// in its own window (`showKeyboardOverlay`), so it covers the keyboard
/// instead of pushing it away and the field keeps its cursor. And it is
/// one surface rather than two views taking turns: it opens as the circle
/// around the + button, grows into the menu, then becomes the grid, with
/// the same rectangle and corners throughout.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_media_picker/gallery.dart';

import '../home/demo_ui.dart' show playgroundPalette;
import 'gpt_photo_library.dart';

// ── Measured constants ────────────────────────────────────────────────────

/// Side gutter shared by the composer, the menu and the panel.
const double kGutter = 12;

const double kComposerRowHeight = 48;
const double kComposerRowPaddingLeft = 14;
const double kPlusHit = 30;

/// The circle the panel grows out of, fitted around the + glyph.
const double kPlusWell = 34;

/// The + glyph. Measured off the app at 18pt of drawn glyph, which an icon
/// box has to be a few points larger than to reach.
const double kPlusSize = 24;

/// Window x of the + button's centre with the composer at full width,
/// which is where the panel is anchored. The bar is narrower while the
/// field is unfocused, so the live value is passed in.
const double kPlusCenterX = kGutter + kComposerRowPaddingLeft + kPlusHit / 2;

const double kMenuWidth = 280;

/// The menu's left edge, which is not the panel's.
///
/// Measured off a screenshot of the app: on a 402pt screen the menu sits
/// 31pt in while the grid it morphs into runs to the composer's own 12pt
/// gutter. One surface with two insets, so the left edge travels with
/// the morph like the width and the corners do.
const double kMenuLeft = 31;
const double kMenuItemHeight = 66;
const double kMenuPaddingVertical = 12;
const double kMenuRadius = 46;
const double kMenuIconWell = 42;
const double kMenuIconSize = 22;
const double kMenuIconInset = 24;
const double kMenuLabelGap = 18;
const double kMenuLabelSize = 19;

/// The menu's centre sits this far below the + button's centre.
const double kMenuCenterOffset = 7;

const int kMenuItems = 5;
const double kMenuHeight =
    kMenuItemHeight * kMenuItems + kMenuPaddingVertical * 2;

const int kGridColumns = 3;
const double kGridGap = 1.5;

/// One grid cell's edge at [screenWidth]. Shared so the size the tiles
/// ask the photo library for is the size the cache is warmed at: warmed
/// at anything else, the cache is never read.
double gptCellEdge(double screenWidth) =>
    (screenWidth - kGutter * 2 - kGridGap * kGridColumns) / kGridColumns;
const double kGridCellRadius = 2;
const double kGridPanelRadius = 52;

/// How much of the screen the grid sheet takes. Fixed, so the sheet is
/// the same size with the keyboard up or down.
const double kGridScreenShare = 0.6;
const double kBadgeSize = 23;
const double kBadgeInset = 4;
const double kBadgeLabelSize = 14;

/// Inset from the panel's own edge, not the screen's: the controls sit in
/// the panel's bottom corners, and a corner only reads as one when both of
/// its gaps match.
const double kBarInset = 25;
const double kBackSize = 46;
const double kBackIcon = 24;
const double kPillHeight = 46;
const double kPillPaddingH = 24;
const double kPillLabelSize = 17;

/// The demo's colours, sampled off recordings of the app in both
/// appearances.
///
/// They are not one another inverted. The light surface is white with a
/// faintly cool panel and a blue send button; the dark one is black with a
/// warm-neutral panel and a white send button. The keyboard is what the
/// panel sits over for most of its height, so the two have to agree.
/// That is why the screen sets its own brightness to match.
class GptColors {
  const GptColors({
    required this.background,
    required this.surface,
    required this.material,
    required this.text,
    required this.placeholder,
    required this.iconWell,
    required this.action,
    required this.onAction,
  });

  /// The page behind everything.
  final Color background;

  /// The composer bar. A shade off [material] and deliberately so: the
  /// panel opens as a circle sitting on this bar, and the two have to read
  /// as one surface until it clears the bar's edges.
  final Color surface;

  /// The panel, menu and grid alike.
  final Color material;

  final Color text;
  final Color placeholder;

  /// The round wells behind the menu's icons.
  final Color iconWell;

  /// The composer's one filled button, and the glyph inside it.
  final Color action;
  final Color onAction;
}

const GptColors kGptLight = GptColors(
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFFCFCFC),
  material: Color(0xFFF8F7FA),
  text: Color(0xFF0D0D0D),
  placeholder: Color(0xFF757575),
  iconWell: Color(0xFFEEEEEE),
  action: Color(0xFF007AFF),
  onAction: Color(0xFFFFFFFF),
);

const GptColors kGptDark = GptColors(
  background: Color(0xFF000000),
  surface: Color(0xFF1D1D1D),
  material: Color(0xFF1E1E1E),
  text: Color(0xFFFFFFFF),
  placeholder: Color(0xFF777777),
  iconWell: Color(0x17FFFFFF),
  action: Color(0xFFFFFFFF),
  onAction: Color(0xFF1D1D1D),
);

/// Follows the playground's own light/dark switch.
GptColors get gpt =>
    playgroundPalette.brightness == Brightness.dark ? kGptDark : kGptLight;

/// Selection badges and the ring around them: white on blue in both
/// appearances, so it does not follow the palette.
const Color kAccent = Color(0xFF007AFF);

/// The confirm capsule's blue. A tint over glass, not a fill, so it
/// carries alpha and sits deeper than [kAccent].
const Color kAccentGlass = Color(0xCC056DE7);
const Color kOnAccent = Color(0xFFFFFFFF);

/// The back button and the untinted state of the confirm capsule. A light
/// neutral grey, so the capsules read as controls resting on the photos
/// rather than as holes cut into them.
const Color kControlScrim = Color(0x8CAEAEB2);


/// The move itself: `withSpring(target, {duration: 400, dampingRatio: 0.8})`.
///
/// A spring and not a curve, and the reference says why: the panel starts as
/// the circle the + just left, and an ease-out is already a fifth of the way
/// out by the second frame, so the circle is never seen. A spring holds
/// small long enough to read it.
final Curve kPanelSpring =
    _ReanimatedSpring(durationMs: 400, dampingRatio: 0.8);

/// The same spring with the bounce taken out, for the way back into the +
/// button. Things arriving may overshoot; things leaving may not, since an
/// overshoot below zero would take the panel past the button it is
/// collapsing into.
final _ReanimatedSpring kPanelSpringOut =
    _ReanimatedSpring(durationMs: 400, dampingRatio: 1);

/// Reanimated keeps a spring alive for 1.5x its perceptual duration before
/// calling it finished, and that is the window our controllers run for.
const Duration kPanelMove = Duration(milliseconds: 600);

/// How long the panel takes to leave, as opposed to how long its
/// controller runs. A spring is inside a point of its target well before
/// its window ends, so the panel goes when it arrives rather than when
/// the controller finishes.
Duration get kPanelExit => kPanelMove * kPanelSpringOut.settleFraction;

/// Content crossfade inside the morphing panel: far shorter than the move,
/// since both layers are being scaled at once and the fade only has to
/// cover the stretch where both are legible.
const Duration kCrossfade = Duration(milliseconds: 150);

/// How long the + glyph gets to itself before the panel arrives.
const Duration kPlusLead = Duration(milliseconds: 30);

/// How far the menu has to be dragged before letting go dismisses it,
/// and how fast a flick has to be to dismiss it from anywhere.
const double kDragDismiss = 70;
const double kDragFlingVelocity = 700;

/// How far the menu will actually move, however far the finger goes.
///
/// It can be pushed off its place but not carried around: the movement
/// resists more the further it gets and never passes this, so a long drag
/// nudges the panel rather than taking it across the screen.
const double kDragGive = 26;

/// How many photos one message can carry.
const int kMaxSelection = 8;


/// The composer's attachment strip, as measured in the reference.
const double kStripPaddingTop = 8;
const double kStripGap = 7;
const double kThumbSize = 115;
const double kThumbRadius = 18;

/// Gap between the photos in the composer's strip. The reference measures
/// 7; a point tighter reads better at our thumbnail size, and the flight
/// aims through this same number so the slots stay where the photos land.
const double kThumbGap = 6;
const double kStripHeight = kStripPaddingTop + kThumbSize + kStripGap;

/// The photos crossing from the grid to the composer: `withSpring(1,
/// {duration: 400})`, which is the panel's spring with the bounce taken
/// out. The same one the composer's strip runs on, so a photo lands on the
/// slot at the moment the slot finishes opening rather than beside it.

/// Where the composer is: the bottom edge the panel hangs off, the lowest
/// the panel may reach, and the window x of the + button's centre.
class GptAnchors {
  const GptAnchors({
    required this.composer,
    required this.panel,
    required this.plusX,
  });

  final double composer;
  final double panel;
  final double plusX;
}

/// One picked photo, carried by its library id and nothing else.
///
/// The strip, the flight and the sent message all draw from the id.
/// [MediaGallery.file] exports the original, which on an iPhone means
/// writing out a HEIC, so calling it on the tap stalls exactly where the
/// photos are supposed to take off. [resolve] is there for when a photo
/// actually has to leave the device.
class GptAttachment {
  const GptAttachment(this.assetId);

  final String assetId;

  /// The file to upload. Not called by this demo: nothing here leaves the
  /// device, and everything on screen draws from the library directly.
  Future<GalleryFile> resolve() => MediaGallery.file(assetId);
}

// ── Entry point ───────────────────────────────────────────────────────────

/// Opens the panel over the keyboard. Returns the files the user picked, in
/// the order they were picked; empty when they close it without picking.
///
/// [anchors] is read every frame: the composer moves while the panel is
/// up, as its bar widens and the keyboard lifts it.
/// [onPicked] fires when the photos start flying, not when they land: the
/// composer has to open the slots they are aiming at while they are still
/// in the air, which is what makes them land ON the strip rather than near
/// it.
Future<void> showGptAttachmentPanel(
  BuildContext context, {
  required GptPhotoLibrary library,
  required GptAnchors Function() anchors,
  required int attachedCount,
  required void Function(List<GptAttachment> picked) onPicked,
  required VoidCallback onClosing,
  required VoidCallback onLanded,
  bool prewarm = false,
}) async {
  final size = MediaQuery.sizeOf(context);
  await showKeyboardOverlay<void>(
    context: context,
    builder: (_) => _AttachmentPanel(
      library: library,
      anchors: anchors,
      screenWidth: size.width,
      screenHeight: size.height,
      attachedCount: attachedCount,
      onPicked: onPicked,
      onClosing: onClosing,
      onLanded: onLanded,
      prewarm: prewarm,
    ),
  );
}

// ── The panel ─────────────────────────────────────────────────────────────

class _AttachmentPanel extends StatefulWidget {
  const _AttachmentPanel({
    required this.library,
    required this.anchors,
    required this.screenWidth,
    required this.screenHeight,
    required this.attachedCount,
    required this.onPicked,
    required this.onClosing,
    required this.onLanded,
    required this.prewarm,
  });

  final GptPhotoLibrary library;

  /// Where the composer is right now. Called every build.
  final GptAnchors Function() anchors;

  final double screenWidth;
  final double screenHeight;

  /// Photos already in the composer's strip. The flight lands past them.
  final int attachedCount;

  final void Function(List<GptAttachment> picked) onPicked;

  /// Fires when the panel starts leaving, not when it has gone. The + it
  /// grew out of comes back into the space it is vacating, so the composer
  /// has to hear about the close at the top of it: waiting for the pop
  /// leaves the composer holding an empty slot for the length of the
  /// collapse.
  final VoidCallback onClosing;

  /// Fires on the frame the photos land, before the panel is torn down.
  /// Tearing it down is four hundred views coming out and a long frame
  /// with them: doing that first is what made the thumbnails appear on
  /// the far side of a freeze, as if they had been lost and rebuilt.
  final VoidCallback onLanded;

  /// This pass is here to pay for the panel's first native views, not to
  /// show anything. It builds the tree once and leaves.
  final bool prewarm;

  @override
  State<_AttachmentPanel> createState() => _AttachmentPanelState();
}

class _AttachmentPanelState extends State<_AttachmentPanel>
    with TickerProviderStateMixin {
  /// 0 the circle around the + button → 1 the menu at rest.
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: kPanelMove,
  );

  /// 0 menu-shaped → 1 the grid.
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: kPanelMove,
  );

  /// The two layers' opacities, each on a timed 150ms rather than on the
  /// morph's own progress: the panel is scaling both at once, so the fade
  /// only has to cover the stretch where both are legible.
  ///
  /// Two controllers and not one crossfade, because they are not always
  /// opposites. Confirming a selection takes the grid out and leaves the
  /// menu hidden, so the panel collapses empty rather than blowing the
  /// menu rows back up inside it on the way out.
  late final AnimationController _menuFade = AnimationController(
    vsync: this,
    duration: kCrossfade,
    value: 1,
  );

  late final AnimationController _gridFade = AnimationController(
    vsync: this,
    duration: kCrossfade,
  );

  /// Which layer takes touches. Both stay mounted through the morph, and a
  /// faded-out layer still swallows taps.
  bool _showingGrid = false;

  /// Whether the grid's views exist yet. It is mounted as soon as the menu
  /// has settled rather than when the morph starts, because [GridView]
  /// builds every cell up front: a hundred and eighty native image views
  /// created on the first frame of the morph is the morph's first frames
  /// dropped. The reference gets this for free from a recycling list, and
  /// so would we from [FastGrid], but its cells swallow taps in this
  /// window, which is a framework bug of its own.
  bool _gridMounted = false;

  /// Things arriving may overshoot; things leaving may not.
  bool _closing = false;

  /// Where the finger has taken the menu, in points, before resistance.
  ///
  /// The menu can be pushed away rather than tapped away, and it can be
  /// pushed in any direction: the app lets it come off its place a little
  /// in both axes and put itself back. Only the menu takes this: the
  /// grid scrolls, and a drag in there belongs to the photos.
  Offset _drag = Offset.zero;


  /// How many cells the grid is drawing: min(assets held, budget). A page
  /// landing past the budget changes nothing on screen, and rebuilding for
  /// it re-diffs every cell to draw the same picture.
  int _held = 0;

  /// Where the grid is scrolled to, reported by FastGrid.
  double _gridOffset = 0;

  /// The grid layer, kept between frames. See [_grid].
  Widget? _gridLayer;
  String? _gridSignature;

  final List<String> _selected = [];

  /// 0 still in the grid → 1 landed on the composer's strip.
  late final AnimationController _attach = AnimationController(
    vsync: this,
    duration: kPanelMove,
  );

  /// The photos in the air: the cell each left, and the slot it is aiming
  /// at. Copies, not the cells themselves: the cells belong to a grid
  /// inside a panel that is collapsing at the same time, and nothing
  /// survives being in two places at once.
  final List<_Flight> _flights = [];

  /// The copies have reached their slots and the composer is showing its
  /// own thumbnails, so the copies stop being drawn. The list itself
  /// stays: it is what holds the panel closed to touches while a photo is
  /// in the air, and what the grid reads to lift the cells that left.
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    _open.addListener(_repaint);
    _morph.addListener(_repaint);
    _attach.addListener(_repaint);
    _menuFade.addListener(_repaint);
    _gridFade.addListener(_repaint);
    widget.library.addListener(_onLibrary);
    if (widget.prewarm) {
      // Built and gone. The panel stays at the circle it opens as, which
      // is the composer's own colour on the composer's own bar, so there
      // is nothing to see for the one frame it is up.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    // The + glyph gets a beat to itself: the panel opens as the circle
    // around it, so the two would overlap if it arrived at once.
    Future.delayed(kPlusLead, () async {
      if (!mounted) return;
      await _open.forward();
      // The menu is at rest and nothing is moving: the cheapest moment
      // there is to pay for the grid's views.
      if (mounted && !_gridMounted) setState(() => _gridMounted = true);
    });
  }

  @override
  void dispose() {
    _open.dispose();
    _morph.dispose();
    _attach.dispose();
    _menuFade.dispose();
    widget.library.removeListener(_onLibrary);
    _gridFade.dispose();
    super.dispose();
  }

  void _repaint() => setState(() {});

  void _onDrag(DragUpdateDetails d) {
    setState(() => _drag += d.delta);
  }

  /// What the panel actually moves, for a finger that has gone [travel].
  ///
  /// Resistance that grows with the distance and never passes
  /// [kDragGive], so the panel gives under a drag without being carried
  /// anywhere by it.
  double _give(double travel) {
    final away = travel.abs();
    return travel.sign * kDragGive * (1 - 1 / (away / kDragGive + 1));
  }

  void _onDragEnd(DragEndDetails d) {
    // Read off the finger's travel, not the panel's: the panel barely
    // moves, and a drag still has to be able to close it.
    final flung = d.velocity.pixelsPerSecond.dy > kDragFlingVelocity;
    if (_drag.dy > kDragDismiss || flung) {
      _close();
      return;
    }
    // Back where it was, on the panel's own spring.
    final from = _drag;
    final back = AnimationController(vsync: this, duration: kPanelMove);
    back.addListener(() {
      if (!mounted) return;
      setState(
          () => _drag = from * (1 - kPanelSpringOut.transform(back.value)));
    });
    back.forward().whenComplete(back.dispose);
  }

  /// A spring overshoots at the end of a move, so one running backwards
  /// is the same curve mirrored: playing the forward one in reverse puts
  /// the overshoot at the start, where nothing has moved yet.
  ///
  /// Back to the menu bounces like every other shape the panel takes;
  /// leaving for the + button does not, since an overshoot there would
  /// take it past the button it is collapsing into.
  double _spring(AnimationController c) {
    final leaving = c.status == AnimationStatus.reverse ||
        c.status == AnimationStatus.dismissed;
    if (!leaving) return kPanelSpring.transform(c.value);
    final curve = _closing ? kPanelSpringOut : kPanelSpring;
    return 1 - curve.transform(1 - c.value);
  }

  /// The reference app's grid listener, which is the shape this follows:
  /// near the end, and not already fetching, ask for the next page after
  /// a short settle. [GridView] here builds every cell it is given rather
  /// than the visible ones, so the cell budget grows on the same trigger.
  /// The grid draws every asset held, so a page landing is what changes
  /// its length. Nothing else here depends on the count.
  void _onLibrary() {
    final held = widget.library.assets.length;
    if (held == _held) return;
    // Deferred past the current frame, the way the playground's own
    // infinite grid does it. A page lands mid-fling, and growing the grid
    // there puts the Dart rebuild, the native insert and the overlay's
    // structural pass inside the frame being scrolled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.library.assets.length == _held) return;
      setState(() => _held = widget.library.assets.length);
    });
  }

  /// Paging a photo grid without dropping frames.
  ///
  /// Three rules, and each one is load bearing.
  ///
  /// The next page is measured against the photos already held, never
  /// against the grid's scroll extent. A collection view reports an extent
  /// that trails its item count while it is being scrolled, so a scroll
  /// that trusts it reads as "near the end" long after it isn't, and pulls
  /// a page on nearly every callback.
  ///
  /// How much is loaded is arithmetic, not a measurement: rows times row
  /// height. How far down it the finger has reached is the offset plus the
  /// viewport. Ask only when less than 2.5 viewports of loaded content are
  /// still unseen, and only one page can ever be in flight.
  ///
  /// A page has to be worth more than that threshold, or the fetch it
  /// triggers lands inside the same fling that asked for it. At three
  /// columns a page of 105 is 35 rows, roughly 4400pt, against a threshold
  /// near 1310pt on this panel.
  ///
  /// The offset is also what a photo's flight starts from, since a cell's
  /// position is its row minus the scroll.
  void _onGridScroll(
    double offset,
    double maxExtent,
    double viewport,
    bool dragging,
  ) {
    _gridOffset = offset;
    final lib = widget.library;
    // maxExtent is what says whether the grid actually grew with the
    // library: held climbing while this stands still means the new items
    // never reached the collection view.
    if (lib.isFetching || !lib.hasMore) return;
    // Measured against the photos already held, not against the grid's
    // extent. The extent lags its item count under a fling, growing a few
    // hundred points while a page adds several thousand, which leaves the
    // scroll reading as "near the end" for ever and pulls a page on nearly
    // every callback. How much is loaded, and how far down it the finger
    // has got, are both known here without asking the collection view.
    final rows = (lib.assets.length / kGridColumns).ceil();
    final loaded = rows * (gptCellEdge(widget.screenWidth) + kGridGap);
    final seen = offset + viewport;
    if (loaded - seen > 2.5 * viewport) return;

    lib.loadMore();
  }

  Future<void> _close() async {
    widget.onClosing();
    setState(() {
      _closing = true;
      _showingGrid = false;
    });
    _menuFade.forward();
    _gridFade.reverse();
    _morph.reverse();
    _open.reverse();
    await Future.delayed(kPanelExit);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _toggle(MediaAsset asset) {
    setState(() {
      if (_selected.remove(asset.id)) return;
      if (_selected.length >= kMaxSelection) return;
      _selected.add(asset.id);
    });
  }

  Future<void> _add() async {
    if (_selected.isEmpty || _flights.isNotEmpty) return;

    // Where each photo is sitting, right now, on the frame it leaves. The
    // panel is at rest and fully morphed at this point, so its own frame
    // is the offset from the window: no measure pass, and nothing that can
    // land a frame late.
    setState(() {
      for (var slot = 0; slot < _selected.length; slot++) {
        final id = _selected[slot];
        _flights.add(
          _Flight(
            assetId: id,
            from: _cellRect(id),
            // Past whatever is already in the strip: these land after it.
            slot: widget.attachedCount + slot,
          ),
        );
      }
    });

    // The composer opens its slots now, while the photos are still in the
    // air, so they land on the strip instead of near it, and takes back
    // its + while the panel is still collapsing off it.
    widget.onPicked([for (final id in _selected) GptAttachment(id)]);
    widget.onClosing();

    // The panel closes into the + button as any close does, and its
    // collapse runs the same length as the flight so the two read as one
    // move. The grid fades with it; the menu stays hidden.
    setState(() {
      _closing = true;
      _showingGrid = false;
    });
    _gridFade.reverse();
    _morph.reverse();
    _open.reverse();
    _attach.forward();
    await Future.delayed(kPanelExit);
    if (!mounted) return;
    // The flying copies come off as the composer's own thumbnails stop
    // being held back, on one frame.
    widget.onLanded();
    setState(() => _landed = true);
    // Removing the grid's views takes a long frame, so it runs once the
    // controllers have stopped. kPanelExit is only their visual settle.
    await Future.delayed(kPanelMove - kPanelExit);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  /// Where a photo is sitting right now, in window coordinates. Computed
  /// from the grid rather than measured: the cell size, its row and column
  /// and the scroll offset are all known, and a measurement would have to
  /// happen on the frame the panel starts collapsing.
  /// The grid layer, rebuilt only when what it shows changes. See
  /// [_gridLayer].
  Widget _grid() {
    // Every input the grid draws from. The width is in here because a
    // rotation changes it and a cached layer would otherwise keep laying
    // its cells out at the old one.
    final signature = '${_selected.join(',')}|$_held|'
        '${_flights.isNotEmpty}|$_gridWidth';
    if (_gridSignature != signature || _gridLayer == null) {
      _gridSignature = signature;
      _gridLayer = _Grid(
        library: widget.library,
        selected: _selected,
        width: _gridWidth,
        onScroll: _onGridScroll,
        onTap: _toggle,
        onBack: _backToMenu,
        onAdd: _add,
        lifting: _flights.isNotEmpty,
      );
    }
    return _gridLayer!;
  }

  /// One cell's edge. A hairline of the panel shows on the right and
  /// bottom of every cell, the last column included.
  double get _cellEdge => gptCellEdge(widget.screenWidth);

  Rect _cellRect(String assetId) {
    final index = widget.library.assets.indexWhere((a) => a.id == assetId);
    final cell = _cellEdge;
    if (index < 0) {
      return Rect.fromLTWH(kGutter, _gridTop, cell, cell);
    }
    final row = index ~/ kGridColumns;
    final col = index % kGridColumns;
    final scrolled = _gridOffset;
    // kGutter, not kMenuLeft: the panel is fully morphed when a photo
    // leaves it, and that is the grid's own edge.
    return Rect.fromLTWH(
      kGutter + col * (cell + kGridGap),
      _gridTop + row * (cell + kGridGap) - scrolled,
      cell,
      cell,
    );
  }

  // ── Geometry ────────────────────────────────────────────────────────────

  /// The composer's position as of this frame. Set at the top of build,
  /// and read by everything that hangs off it.
  GptAnchors _a = const GptAnchors(composer: 0, panel: 0, plusX: 0);

  double get _plusCenterY => _a.composer - kComposerRowHeight / 2;

  /// Menu and grid share a top edge, which is what the frames measure and
  /// why the morph only moves the left, right and bottom ones.
  ///
  /// The menu is centred on the + button, so with the keyboard up its
  /// lower half sits over the keyboard. With the keyboard down that half
  /// would hang off the screen, so it is lifted until it clears.
  double get _top => math.min(
        _plusCenterY + kMenuCenterOffset - kMenuHeight / 2,
        _a.panel - kMenuHeight,
      );

  double get _gridWidth => widget.screenWidth - kGutter * 2;

  /// The grid's own height, and its own top edge.
  ///
  /// The menu is centred on the + button, so its top follows the keyboard.
  /// The grid does not: it is a sheet, the same size whether the keyboard
  /// is up or down. Sharing the menu's top left it three rows tall with
  /// the keyboard closed, since the + is near the bottom of the screen
  /// then.
  double get _gridHeight => widget.screenHeight * kGridScreenShare;

  /// The grid reaches lower than the menu: measured off the app, its
  /// sheet runs to about a gutter from the screen's bottom, while the menu
  /// stops above the composer.
  double get _gridBottom => widget.screenHeight - kGutter;

  double get _gridTop => _gridBottom - _gridHeight;

  double _mix(double t, double a, double b) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    _a = widget.anchors();
    final o = _spring(_open);
    final m = _spring(_morph);

    var x = _mix(m, kMenuLeft, kGutter);
    var y = _mix(m, _top, _gridTop);
    var w = _mix(m, kMenuWidth, _gridWidth);
    var h = _mix(m, kMenuHeight, _gridHeight);
    var r = _mix(m, kMenuRadius, kGridPanelRadius);

    // The panel begins as the circle wrapping the + button and grows out of
    // it. Nothing else ever draws that circle, so there is none to see
    // while the panel is shut.
    x = _mix(o, _a.plusX - kPlusWell / 2, x);
    y = _mix(o, _plusCenterY - kPlusWell / 2, y) + _give(_drag.dy);
    x += _give(_drag.dx);
    w = _mix(o, kPlusWell, w);
    h = _mix(o, kPlusWell, h);
    r = _mix(o, kPlusWell / 2, r);

    // The contents fade in a beat after the circle, so it reads as a circle
    // before the rows arrive.
    final openFade = ((o - 0.12) / (0.6 - 0.12)).clamp(0.0, 1.0);

    // Nothing in here takes a touch once the photos are on their way: the
    // panel is leaving, and a tap on the backdrop it is still covering
    // would start a second close on top of this one.
    return IgnorePointer(
      ignoring: _flights.isNotEmpty,
      child: Stack(
        children: [
          // Tapping the page behind the panel closes it. Touches outside this
          // tree pass through to the keyboard, which stays live.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _close(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(),
            ),
          ),
          Positioned(
            left: x,
            top: y,
            width: w,
            height: h,
            child: _PanelSurface(
              radius: r,
              // The panel starts as the composer's own surface and takes
              // on the menu's material as it grows. That is why the app
              // shows no circle while the panel is small: it is the same
              // colour as the bar it is sitting on, and the + stays
              // visible on top of it the whole way.
              fill: Color.lerp(gpt.surface, gpt.material, openFade)!,
              glass: !_closing,
              child: Stack(
                children: [
                  // Both layers are laid out at their natural size and
                  // scaled to the panel, so the grid shrinks into the
                  // menu's footprint and the menu grows out of it. The one
                  // not in front stops taking taps, since a layer faded to
                  // nothing still receives them. The grid stays mounted
                  // until the panel goes: removing four hundred views is a
                  // long frame, and the photos fly through those frames.
                  if (_gridMounted)
                    IgnorePointer(
                      ignoring: !_showingGrid,
                      child: Opacity(
                        opacity: _gridFade.value * openFade,
                        child: Transform.scale(
                          scale: w / _gridWidth,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: _gridWidth,
                            height: _gridHeight,
                            child: _grid(),
                          ),
                        ),
                      ),
                    ),
                  if (!_showingGrid || _menuFade.value > 0)
                    IgnorePointer(
                      ignoring: _showingGrid,
                      // The menu can be pushed away as well as tapped
                      // away. The grid never takes a drag: it scrolls, and
                      // closes by a tap outside or the back button.
                      child: GestureDetector(
                        onPanUpdate: _showingGrid ? null : _onDrag,
                        onPanEnd: _showingGrid ? null : _onDragEnd,
                        child: Opacity(
                          opacity: _menuFade.value * openFade,
                          child: Transform.scale(
                            scale: w / kMenuWidth,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: kMenuWidth,
                              height: kMenuHeight,
                              child: _MenuRows(onPhotos: _openGrid),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // A copy of the + button, on top of the panel and in the
          // composer's own place. The panel is in the window above the
          // composer and would otherwise cover the button it collapses
          // into. It fades out as the panel's contents fade in.
          Positioned(
            left: _a.plusX - kPlusHit / 2,
            // The composer's + does not move, so neither does this copy:
            // they have to stay on top of one another for the swap at the
            // end to be invisible.
            top: _plusCenterY - kComposerRowHeight / 2,
            width: kPlusHit,
            height: kComposerRowHeight,
            // Takes no taps: the tap that dismisses the panel lands on
            // this exact spot, and it belongs to the backdrop underneath.
            child: IgnorePointer(
              child: Opacity(
                opacity: 1 - openFade,
                child: Center(
                  child: Icon(
                    CupertinoIcons.plus,
                    color: gpt.text,
                    size: kPlusSize,
                  ),
                ),
              ),
            ),
          ),
          // Above the panel, and outside its clip: the photos have left it,
          // and the last part of the way is over the composer.
          if (!_landed)
            for (final flight in _flights) _flying(flight),
        ],
      ),
    );
  }

  /// One photo in the air. Every copy runs on the same spring: they were
  /// picked together and they arrive together, and staggering them would
  /// invent an order the taps did not have.
  Widget _flying(_Flight flight) {
    final a = kPanelSpringOut.transform(_attach.value);
    // The composer is growing around the strip while this flies, so the
    // slot it is aiming at is still rising. Same curve, same clock.
    final composerTop = _a.composer - kComposerRowHeight - a * kStripHeight;
    const step = kThumbSize + kThumbGap;
    // The strip scrolls, so a slot past the right edge has nowhere to land;
    // pinning it to the last visible one is what the strip does anyway.
    final lastVisible =
        widget.screenWidth - kGutter - kStripPaddingTop - kThumbSize;
    final toX = (kGutter + kStripPaddingTop + flight.slot * step)
        .clamp(kGutter, lastVisible);
    final toY = composerTop + kStripPaddingTop;

    return Positioned(
      left: _mix(a, flight.from.left, toX),
      top: _mix(a, flight.from.top, toY),
      width: _mix(a, flight.from.width, kThumbSize),
      height: _mix(a, flight.from.height, kThumbSize),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(_mix(a, kGridCellRadius, kThumbRadius)),
        // The size the grid asked for, not the size it is landing at:
        // this is the picture the cell already has decoded, and asking for
        // a different one would send the flight off with an empty frame.
        child: GalleryThumb(assetId: flight.assetId, size: _cellEdge.round()),
      ),
    );
  }

  /// The ‹ button: back to the menu, on the panel's own spring. The panel
  /// never closes for this: it is the same surface changing shape again.
  void _backToMenu() {
    setState(() {
      _showingGrid = false;
      _selected.clear();
    });
    _morph.reverse();
    _menuFade.forward();
    _gridFade.reverse();
  }

  void _openGrid() {
    setState(() {
      _showingGrid = true;
      _gridMounted = true;
      // Nothing carries a half-finished nudge into the grid.
      _drag = Offset.zero;
    });
    _morph.forward();
    _menuFade.reverse();
    _gridFade.forward();
  }
}

/// The grid's round back button: the capsule's treatment in a circle.
class _GlassCircle extends StatelessWidget {
  const _GlassCircle({
    required this.size,
    required this.tint,
    required this.child,
  });

  final double size;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 2);
    if (isIOS26) {
      return GlassEffectContainer(
        borderRadius: radius,
        tint: tint,
        interactive: true,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, borderRadius: radius),
      child: child,
    );
  }
}

/// The grid's confirm capsule: tinted glass on iOS 26, the tint as a
/// solid fill below it.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.tint, required this.child});

  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kPillHeight / 2);
    if (isIOS26) {
      return GlassEffectContainer(
        borderRadius: radius,
        tint: tint,
        interactive: true,
        child: SizedBox(
          height: kPillHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPillPaddingH),
            child: Center(child: child),
          ),
        ),
      );
    }
    return Container(
      height: kPillHeight,
      padding: const EdgeInsets.symmetric(horizontal: kPillPaddingH),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, borderRadius: radius),
      child: child,
    );
  }
}

/// The panel's own surface.
///
/// Glass, the way the app draws it: the sheet is a material over whatever
/// is behind it (the chat, and the keyboard for its lower half) rather
/// than a grey fill. Liquid Glass is iOS 26 only and has no fallback of
/// its own, so below that it is the flat colour it was sampled at.
class _PanelSurface extends StatelessWidget {
  const _PanelSurface({
    required this.radius,
    required this.fill,
    required this.glass,
    required this.child,
  });

  final double radius;
  final Color fill;

  /// Whether to wear the material at all. It is dropped at the start of
  /// the close, as the app does: a glass circle shrinking onto the +
  /// button is a circle you can see.
  final bool glass;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child,
    );
    if (isIOS26 && glass) {
      return GlassEffectContainer(
        borderRadius: BorderRadius.circular(radius),
        brightness: playgroundPalette.brightness,
        child: clipped,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: clipped,
    );
  }
}

/// One photo crossing from the grid to the composer.
class _Flight {
  const _Flight({
    required this.assetId,
    required this.from,
    required this.slot,
  });

  /// The cell it left, in window coordinates.
  final Rect from;
  final String assetId;

  /// Which composer slot it is landing on.
  final int slot;
}

// ── The menu layer ────────────────────────────────────────────────────────

class _MenuRow {
  const _MenuRow(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _menuRows = [
  _MenuRow('Camera', CupertinoIcons.camera),
  _MenuRow('Photos', CupertinoIcons.photo),
  _MenuRow('Files', CupertinoIcons.paperclip),
  _MenuRow('Plugins', CupertinoIcons.at),
  _MenuRow('Think harder', CupertinoIcons.clock),
];

class _MenuRows extends StatelessWidget {
  const _MenuRows({required this.onPhotos});

  final VoidCallback onPhotos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kMenuPaddingVertical),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in _menuRows)
            GestureDetector(
              onTap: row.label == 'Photos' ? onPhotos : () {},
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: kMenuItemHeight,
                child: Row(
                  children: [
                    const SizedBox(width: kMenuIconInset),
                    Container(
                      width: kMenuIconWell,
                      height: kMenuIconWell,
                      decoration: BoxDecoration(
                        color: gpt.iconWell,
                        borderRadius: BorderRadius.circular(kMenuIconWell / 2),
                      ),
                      child: Center(
                        child: Icon(
                          row.icon,
                          color: gpt.text,
                          size: kMenuIconSize,
                        ),
                      ),
                    ),
                    const SizedBox(width: kMenuLabelGap),
                    Text(
                      row.label,
                      style: TextStyle(
                        color: gpt.text,
                        fontSize: kMenuLabelSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── The grid layer ────────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  const _Grid({
    required this.library,
    required this.selected,
    required this.width,
    required this.onScroll,
    required this.onTap,
    required this.onBack,
    required this.onAdd,
    required this.lifting,
  });

  final GptPhotoLibrary library;
  final List<String> selected;
  final double width;

  /// Native scroll position, for load-more and for the flight's start.
  final FastScrollCallback onScroll;
  final void Function(MediaAsset asset) onTap;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  /// The photos are on their way to the composer. Their cells are cut on
  /// the frame the flight starts: their copies are leaving from that exact
  /// rect, and one photo cannot be in two places at once.
  final bool lifting;

  @override
  Widget build(BuildContext context) {
    final lib = library;
    // A hairline of the sheet shows through on the right and bottom of
    // every cell, the last column included: that is a gap per column, not
    // one per join, and it is what keeps the grid from reading as one
    // image cut into nine.
    final cell = (width - kGridGap * kGridColumns) / kGridColumns;
    return Stack(
      children: [
        // The whole library, windowed. keepAliveCount frees the content of
        // cells far from the viewport and rebuilds it on approach, so the
        // count can be honest and the grid holds what is on screen rather
        // than everything read so far. Same shape as the playground's own
        // infinite grid.
        Positioned.fill(
          child: FastGrid(
            itemCount: lib.assets.length,
            crossAxisCount: kGridColumns,
            childAspectRatio: 1.0,
            mainAxisSpacing: kGridGap,
            crossAxisSpacing: kGridGap,
            padding: const EdgeInsets.only(right: kGridGap),
            // Items, not rows: 30 is ten rows either side of the
            // viewport on three columns. 90 kept nearly the whole library
            // built, which is what the windowing exists to avoid.
            keepAliveCount: 30,
            onScroll: onScroll,
            itemBuilder: (context, index) {
              final asset = lib.assets[index];
              final order = selected.indexOf(asset.id);
              return _Cell(
                key: ValueKey(asset.id),
                assetId: asset.id,
                size: cell,
                order: order < 0 ? null : order + 1,
                lifted: lifting && order >= 0,
                onTap: () => onTap(asset),
              );
            },
          ),
        ),
        // The controls float in the panel's bottom corners, inset from the
        // panel's own edge on all three sides.
        Positioned(
          left: kBarInset,
          bottom: kBarInset,
          child: GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: _GlassCircle(
              size: kBackSize,
              tint: kControlScrim,
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: Color(0xFFFFFFFF),
                size: kBackIcon,
              ),
            ),
          ),
        ),
        Positioned(
          right: kBarInset,
          bottom: kBarInset,
          child: GestureDetector(
            onTap: selected.isEmpty ? () {} : onAdd,
            behavior: HitTestBehavior.opaque,
            child: _GlassPill(
              // Tinted glass, not a solid fill: the colour goes into the
              // material so the photos still show through it. A saturated
              // colour has to be the capsule's tint, since the vibrancy
              // desaturates a foreground one (docs/IOS26_LIQUID_GLASS.md).
              tint: selected.isEmpty ? kControlScrim : kAccentGlass,
              child: Text(
                selected.isEmpty
                    ? 'All Photos'
                    : 'Add ${selected.length} '
                        'photo${selected.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: kPillLabelSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One photo. A selected cell is marked by the badge alone; the
/// thumbnail does not shrink, dim or round off.
class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.assetId,
    required this.size,
    required this.order,
    required this.lifted,
    required this.onTap,
  });

  final String assetId;
  final double size;
  final int? order;

  /// This photo's copy is in the air. The cell is cut, not faded: a fade
  /// would show the photo twice for the length of it.
  final bool lifted;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Hidden, not unmounted: the cell keeps its slot, and its thumbnail
    // stays decoded for the copy flying out of it.
    return Opacity(
      opacity: lifted ? 0 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kGridCellRadius),
                child: GalleryThumb(assetId: assetId, size: size.round()),
              ),
            ),
            // The badge is the one thing here allowed to look springy, and
            // it is the only sign of selection: the thumbnail is untouched,
            // as in the reference.
            Positioned(
              right: kBadgeInset,
              bottom: kBadgeInset,
              child: AnimatedScale(
                scale: order == null ? 0.4 : 1,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: order == null ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: kBadgeSize,
                    height: kBadgeSize,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(kBadgeSize / 2),
                      border: Border.all(color: kOnAccent, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        order == null ? '' : '$order',
                        style: const TextStyle(
                          color: kOnAccent,
                          fontSize: kBadgeLabelSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

// ── The spring ────────────────────────────────────────────────────────────

/// Reanimated's `withSpring({duration, dampingRatio})`, ported.
///
/// Their duration is perceptual rather than a stopwatch: it becomes a
/// stiffness by bisecting for the value whose remaining energy after 1.5x
/// the duration hits a threshold, and the position comes from the damped
/// oscillator. Both halves are theirs, from
/// react-native-reanimated/src/animation/spring, with their defaults of
/// mass 4, energy threshold 6e-9 and perceptual coefficient 1.5.
///
/// Ported rather than approximated: an ease-out of the same length is
/// visibly a different move.
class _ReanimatedSpring extends Curve {
  _ReanimatedSpring({required this.durationMs, required this.dampingRatio}) {
    final stiffness = _solveStiffness();
    _omega0 = math.sqrt(stiffness / _mass);
    _omega1 = dampingRatio < 1
        ? _omega0 * math.sqrt(1 - dampingRatio * dampingRatio)
        : 0;
  }

  final double durationMs;
  final double dampingRatio;

  static const double _mass = 4;
  static const double _energyThreshold = 6e-9;
  static const double _perceptualCoefficient = 1.5;

  late final double _omega0;
  late final double _omega1;

  /// Seconds the controller runs for: the settling window, not the
  /// perceptual duration.
  double get _settling => durationMs * _perceptualCoefficient / 1000;

  /// The fraction of the window after which the spring is within a
  /// thousandth of its target, which is where it has arrived to look at.
  /// Scanned from the end, so an overshoot on the way does not count.
  late final double settleFraction = _findSettle();

  double _findSettle() {
    const steps = 240;
    for (var i = steps; i > 0; i--) {
      if ((1 - transform(i / steps)).abs() > 0.001) {
        return (i + 1) / steps;
      }
    }
    return 0;
  }

  double _solveStiffness() {
    const x0 = -1.0; // travelling 0 → 1
    const v0 = 0.0;
    double energy(double x, double v, double k) =>
        0.5 * k * x * x + 0.5 * _mass * v * v;

    double energyDiff(double stiffness) {
      final settling = _settling;
      final omega0 = math.sqrt(stiffness / _mass) * dampingRatio;
      final decay = math.exp(-omega0 * settling);
      final xtk = (x0 + (v0 + x0 * omega0) * settling) * decay;
      final vtk = xtk * -omega0 + (v0 + x0 * omega0) * decay;
      return energy(xtk, vtk, stiffness) / energy(x0, v0, stiffness) -
          _energyThreshold;
    }

    var lo = 1e-12;
    var hi = 8e3; // their bound: 8ms animations stay under 2e3
    final precision = _energyThreshold * 1e-3;
    for (var i = 0; i < 100 && hi - lo > precision; i++) {
      final mid = (lo + hi) / 2;
      if (energyDiff(mid) > 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  @override
  double transform(double t) {
    final time = t * _settling;
    if (dampingRatio < 1) {
      final envelope = math.exp(-dampingRatio * _omega0 * time);
      return 1 -
          envelope *
              (math.cos(_omega1 * time) +
                  (dampingRatio * _omega0 / _omega1) *
                      math.sin(_omega1 * time));
    }
    final envelope = math.exp(-_omega0 * time);
    return 1 - envelope * (1 + _omega0 * time);
  }
}
