/// dartnative chat demo screen.
///
/// Showcases:
///   1. Native scroll feeling  — UIScrollView with momentum / rubber-band
///   2. Native text rendering  — UILabel (CoreText, Dynamic Type)
///   3. Native keyboard        — UITextField with correct animation
///
/// This file is intentionally written with Flutter-identical API so developers
/// familiar with Flutter can read and port it without any new concepts.
/// The only change from a regular Flutter file is the import:
///
///   // Flutter:       import 'package:flutter/material.dart';
///   // dartnative:   import 'package:dartnative/dartnative.dart';
import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

// ── List mode enum ────────────────────────────────────────────────────────────

/// All list types currently supported by dartnative.
/// Swap this value to test different scroll implementations.
enum ListMode {
  /// Standard [ListView] with static children.
  listView,

  /// [ListView.builder] — lazy builder API (items are eagerly expanded for this release).
  listViewBuilder,

  /// [CustomScrollView] with a single [SliverList.builder].
  customScrollViewSliverList,

  /// [CustomScrollView] with a [SliverToBoxAdapter] header + [SliverList.builder].
  customScrollViewMixed,

  /// [FastList] — dartnative's own high-performance list backed by UITableView (iOS)
  /// and RecyclerView (Android). Provides O(1) cell recycling and direct
  /// [FastListController.jumpToItem] / [scrollToItem] via native NSIndexPath APIs.
  fastList,
}

/// ──────────────────────────────────────────────────────────────────────────────
/// Change this flag to test different list implementations.
/// ──────────────────────────────────────────────────────────────────────────────
const ListMode _activeListMode = ListMode.fastList;

class ChatScreenDemo extends StatefulWidget {
  const ChatScreenDemo({super.key});

  @override
  State<ChatScreenDemo> createState() => _ChatScreenDemoState();
}

class _ChatScreenDemoState extends State<ChatScreenDemo> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _listController = ListController();
  final _fastListController = FastListController();
  // Newest message at index 0 — the chat convention: prepend on send.
  final _messages = List<_Message>.from(_kSeedMessages);

  /// The id of the message currently highlighted after a scroll-to action.
  int? _highlightedMessageId;
  Timer? _highlightTimer;

  /// Scroll-to-bottom FAB (mini, white, chevron-down). Becomes visible
  /// once the user scrolls up away from the newest message; tapping snaps back
  /// to the bottom. Lets us runtime-verify position-preserve + the FAB across
  /// ALL list modes in one screen — the ScrollView family (listView /
  /// listViewBuilder / customScrollView*) drives it from [_scrollController];
  /// the Fast family has no ScrollController, so [FastList] feeds [_updateFab]
  /// from its onScroll callback instead.
  final ValueNotifier<bool> _showFab = ValueNotifier<bool>(false);

  /// Reveal the FAB once the newest message sits more than this far below the
  /// viewport (logical px).
  static const double _kFabZone = 100;

  /// iOS 26: the list runs behind the glass AppBar (extendBody), so the
  /// visual TOP needs the bar's height reserved — otherwise the OLDEST
  /// messages can never scroll fully out from under the bar frost.
  double get _listTopPad =>
      isIOS26 ? MediaQuery.paddingOf(context).top + 62 : 8;

  void _onSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(0, _Message(text: text, isMe: true));
      _controller.clear();
    });
    // Reveal the sent message even if the user had scrolled up — POST-frame:
    // FastList's scrollToItem is an immediate native call, so pre-insert it
    // targets the OLD list (and its programmatic-jump semantics mark
    // userScrolled, muting the reverse auto-anchor for the insert). After the
    // frame, item 0 IS the new message. The ListController/ScrollController
    // modes are equally correct post-frame (re-arm + snap / new maxExtent).
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  /// Jump to message #2 (second oldest) and highlight it for 1 second.
  void _jumpToScrollToMessage() {
    final targetIndex = _messages.indexWhere(
      (m) => m.id == _kScrollToMessageId,
    );
    dnLog('[ChatDemo] ScrollTo button pressed — targetIndex=$targetIndex, '
        'listMode=$_activeListMode, messageCount=${_messages.length}');
    if (targetIndex < 0) {
      dnLog(
          '[ChatDemo] ScrollTo: message with id "$_kScrollToMessageId" not found');
      return;
    }
    if (_activeListMode == ListMode.fastList) {
      dnLog(
          '[ChatDemo] ScrollTo: calling fastListController.scrollToItem($targetIndex, alignment: 0.0)');
      _fastListController.scrollToItem(targetIndex, alignment: 0.0);
    } else {
      dnLog(
          '[ChatDemo] ScrollTo: calling listController.animateToItem($targetIndex, alignment: 0.0)');
      _listController.animateToItem(targetIndex, alignment: 0.0);
    }
    _highlightTimer?.cancel();
    dnLog('[ChatDemo] ScrollTo: about to call setState for highlight');
    setState(() => _highlightedMessageId = _messages[targetIndex].id);
    dnLog(
        '[ChatDemo] ScrollTo: setState done — highlightMessageId=${_messages[targetIndex].id}');
    _highlightTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  // ── Scroll-to-bottom FAB ──────────────────────────────────────────────────

  /// ScrollView family: native scroll events update [_scrollController]; read
  /// the live offset and toggle the FAB. (No-op for FastList, which never
  /// attaches to [_scrollController] — it feeds [_updateFab] via onScroll.)
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    _updateFab(pos.pixels, pos.maxScrollExtent);
  }

  /// Shared FAB toggle. Reverse lists put the newest message at [maxExtent]
  /// (bottom) on BOTH families, so the same "how far up from newest" test works
  /// for ScrollView lists and FastList alike.
  void _updateFab(double offset, double maxExtent) {
    final show = (maxExtent - offset) > _kFabZone;
    if (_showFab.value != show) _showFab.value = show;
  }

  /// FAB tap → snap to the newest message (bottom of a reverse list).
  void _scrollToBottom() {
    if (_activeListMode == ListMode.fastList) {
      _fastListController.scrollToBottom();
    } else if (_activeListMode == ListMode.customScrollViewSliverList ||
        _activeListMode == ListMode.customScrollViewMixed) {
      // CustomScrollView has no native scrollToBottom wiring (only ListView
      // does); animate the ScrollController to the bottom instead.
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } else {
      // listView / listViewBuilder — resets userScrolled + native bottom snap,
      // re-enabling the reverse-list auto-anchor.
      _listController.scrollToBottom();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final dark = playgroundPalette.brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      // Strip = SAME surface as the input bar (kBarBg: white light /
      // 0xFF1C1C1E dark) — the playground rule for screens with a bottom bar.
      systemNavigationBarColor: isIOS26 ? Colors.transparent : kBarBg,
      systemNavigationBarDividerColor: isIOS26 ? Colors.transparent : kBarBg,
    ));
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _showFab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _logKeyboardIfChanged(context); // debug: subscribe to _InheritedMediaQuery + log (enable when debugging keyboard)
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: kHomeBg,
      extendBody: isIOS26 ? true : false,
      appBar: AppBar(
        // Keep the avatar+name group next to the back button (WhatsApp
        // look) instead of the default centered title.
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              // iOS 26: the taller Liquid Glass bar gets a slightly larger avatar.
              borderRadius: BorderRadius.circular(isIOS26 ? 21 : 19),
              child: Image.asset(
                'assets/avatar.jpg',
                width: isIOS26 ? 42 : 38,
                height: isIOS26 ? 42 : 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lisa',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.checkmark_seal_fill,
                        color: Color(0xFF007AFF), size: 14),
                  ],
                ),
                const Text(
                  'Online',
                  style: TextStyle(color: Color(0xFF34C759), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        // Solid bar on every generation (a translucent color — alpha < 1 —
        // opts iOS 26 into the Liquid Glass frost instead).
        backgroundColor: kBarBg,
        actions: [
          BarButtonItem(
            title: 'ScrollTo #2',
            titleStyle: TextStyle(
                color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500),
            onPressed: () {
              dnLog('[ChatDemo] ScrollTo action tapped');
              _jumpToScrollToMessage();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar handles the top safe area
        bottom:
            true, //!isIOS26, // iOS 26: extend to the bottom (bubbles under glass bar)
        child: Stack(
          children: [
            Positioned.fill(child: _buildList()),
            // iOS 26: fade the bubbles out behind the Liquid Glass bar.
            if (isIOS26)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 95,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                        colors: [
                          kHomeBg.withOpacity(0.0), // transparent
                          kHomeBg.withOpacity(0.78),
                          kHomeBg, // background
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Scroll-to-bottom FAB — top layer, above the gradient.
            // iOS 26: extendBody runs this Stack to the PHYSICAL bottom, so
            // the offset must clear the pinned input bar + home indicator
            // (same 66 + bottom-inset shape as the list's bottomPad);
            // pre-26 the body ends above the bar and 16 suffices.
            Positioned(
              // right 12 = the send button's inset (the input bar's 12pt
              // horizontal padding), so FAB and send button align vertically.
              right: 12,
              bottom: isIOS26 ? 61 + MediaQuery.paddingOf(context).bottom : 16,
              child: ValueListenableBuilder<bool>(
                valueListenable: _showFab,
                builder: (_, show, __) => show
                    ? FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        // Fixed dark grey — the FAB stays white in both themes.
                        foregroundColor: const Color(0xFF48484A),
                        onPressed: _scrollToBottom,
                        child:
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
      // A new field in Scaffold for the bottom input bar. It automatically handles
      // keyboard lift with native animation and interactive keyboard dismissal.
      bottomInputBar: _BottomBar(controller: _controller, onSend: _onSend),
    );
  }

  /// Build the message list using the active [ListMode].
  Widget _buildList() {
    switch (_activeListMode) {
      case ListMode.listView:
        return _buildListView();
      case ListMode.listViewBuilder:
        return _buildListViewBuilder();
      case ListMode.customScrollViewSliverList:
        return _buildCustomScrollViewSliverList();
      case ListMode.customScrollViewMixed:
        return _buildCustomScrollViewMixed();
      case ListMode.fastList:
        return _buildFastList();
    }
  }

  // ── ListMode.listView ───────────────────────────────────────────────────────

  Widget _buildListView() {
    final widgets = _messages
        .asMap()
        .entries
        .map(
          (e) => _ChatBubble(
            message: e.value,
            messageNumber: _messages.length - e.key,
            isHighlighted: e.value.id == _highlightedMessageId,
          ),
        )
        .toList();
    return ListView(
      controller: _scrollController,
      listController: _listController,
      reverse: true,
      padding:
          EdgeInsets.only(left: 16, right: 16, top: _listTopPad, bottom: 8),
      children: widgets,
    );
  }

  // ── ListMode.listViewBuilder ────────────────────────────────────────────────

  Widget _buildListViewBuilder() {
    // listController wires ListController.jumpToItem / animateToItem to
    // UIScrollView.setContentOffset via FFI — equivalent to super_sliver_list's
    // ListController but backed by native UIScrollView instead of Flutter sliver.
    return ListView.builder(
      controller: _scrollController,
      listController: _listController,
      reverse: true,
      padding:
          EdgeInsets.only(left: 16, right: 16, top: _listTopPad, bottom: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _ChatBubble(
        message: _messages[i],
        messageNumber: _messages.length - i,
        isHighlighted: _messages[i].id == _highlightedMessageId,
      ),
    );
  }

  // ── ListMode.fastList ───────────────────────────────────────────────────────

  Widget _buildFastList() {
    // iOS 26 only: extendBody runs the list behind the glass bar, so anchor the
    // newest message ~10px above it — reserve the bar's height + gap, plus the
    // bottom safe-area inset the bar sits above. iOS 18 / Android use a solid
    // bar above the body, so a plain 8px suffices.
    final double bottomPad =
        isIOS26 ? 66 + MediaQuery.paddingOf(context).bottom : 8;
    return FastList(
      controller: _fastListController,
      reverse: true,
      itemCount: _messages.length,
      // FastList has no ScrollController; drive the FAB from onScroll instead.
      onScroll: (offset, maxExtent, viewport, dragging) =>
          _updateFab(offset, maxExtent),
      itemBuilder: (_, i) => _ChatBubble(
        message: _messages[i],
        messageNumber: _messages.length - i,
        isHighlighted: _messages[i].id == _highlightedMessageId,
      ),
      padding: EdgeInsets.only(
          left: 16, right: 16, top: _listTopPad, bottom: bottomPad),
    );
  }

  // ── ListMode.customScrollViewSliverList ─────────────────────────────────────

  Widget _buildCustomScrollViewSliverList() {
    return CustomScrollView(
      controller: _scrollController,
      listController: _listController,
      reverse: true,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8,
          ),
          sliver: SliverList.builder(
            itemCount: _messages.length,
            itemBuilder: (_, i) => _ChatBubble(
              message: _messages[i],
              messageNumber: _messages.length - i,
              isHighlighted: _messages[i].id == _highlightedMessageId,
            ),
          ),
        ),
      ],
    );
  }

  // ── ListMode.customScrollViewMixed ──────────────────────────────────────────

  Widget _buildCustomScrollViewMixed() {
    return CustomScrollView(
      controller: _scrollController,
      listController: _listController,
      reverse: true,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '⬆ SliverToBoxAdapter header — mixed sliver demo',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8,
          ),
          sliver: SliverList.builder(
            itemCount: _messages.length,
            itemBuilder: (_, i) => _ChatBubble(
              message: _messages[i],
              messageNumber: _messages.length - i,
              isHighlighted: _messages[i].id == _highlightedMessageId,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble(
      {required this.message, this.messageNumber, this.isHighlighted = false});

  final _Message message;
  final int? messageNumber;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final Color bubbleColor;
    if (isHighlighted) {
      bubbleColor = const Color(0xFF17A1FF); // highlight blue
    } else {
      bubbleColor = message.isMe ? const Color(0xFF007AFF) : kTileBg;
    }
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          minWidth: 120,
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isMe ? 18 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 18),
          ),
        ),
        // Text → UILabel. CoreText rendering, Dynamic Type, correct baseline.
        child: Text(
          messageNumber != null
              ? '$messageNumber. ${message.text}'
              : message.text,
          style: TextStyle(
            // White on the blue bubbles (sent/highlight); themed on incoming.
            color: message.isMe || isHighlighted
                ? const Color(0xFFFFFFFF)
                : kTextPrimary,
            fontSize: 17,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

// ── Bottom input bar ──────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    // TextField → UITextField. Correct keyboard animation, loupe, native return.
    final Widget textField = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Message…',
          hintStyle: TextStyle(color: kTextSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(top: 8, bottom: 10),
        ),
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        minLines: 1,
        maxLines: 6,
        style: TextStyle(color: kTextPrimary, fontSize: 17),
      ),
    );

    const Widget sendGlyph = Icon(
      CupertinoIcons.arrow_up,
      color: Color(0xFFFFFFFF),
      size: 20,
    );

    // Lifts the capsule off the messages behind it (the picker composer's
    // shadow). iOS 26 only, and only in the light theme — dark glass
    // already reads as lifted, and the solid pre-26/Android capsule
    // carries no shadow.
    final light = playgroundPalette.brightness == Brightness.light;
    final capsuleShadow = BoxShadow(
      color: Color(light ? 0x1A000000 : 0x66000000),
      blurRadius: 18,
      offset: const Offset(0, 4),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isIOS26 ? Colors.transparent : kBarBg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input capsule — iOS 26: Liquid Glass; else solid grey.
          Expanded(
            child: isIOS26
                ? GlassEffectContainer(
                    borderRadius: BorderRadius.circular(18),
                    // The glass casts the shadow itself: a rounded box
                    // around interactive glass clips the system press.
                    shadow: light ? capsuleShadow : null,
                    // Follow the playground theme (also sets the wrapped
                    // textfield's keyboard appearance).
                    brightness: playgroundPalette.brightness,
                    // The capsule presses under a tap; the multiline
                    // field inside stays fully native.
                    interactive: true,
                    child: textField,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: kTileBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: textField,
                  ),
          ),
          const SizedBox(width: 10),
          // Send button — iOS 26: blue-tinted interactive glass; else solid blue.
          GestureDetector(
            onTap: onSend,
            behavior: HitTestBehavior.opaque,
            // 40pt matches the single-line field capsule (17pt text +
            // 8/10 content padding), so the Row's CrossAxisAlignment.end
            // aligns them flush — and the button stays bottom-anchored when
            // the field grows multiline.
            child: isIOS26
                ? GlassEffectContainer(
                    borderRadius: BorderRadius.circular(20),
                    tint: const Color(0xFF007AFF),
                    interactive: true,
                    brightness: Brightness.dark,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(child: sendGlyph),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: sendGlyph,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _Message {
  _Message({required this.text, required this.isMe}) : id = _nextId++;
  static int _nextId = 0;
  final int id;
  final String text;
  final bool isMe;
}

final _kSeedMessages = [
  // Newest message first — index 0 = newest (matched by ListView(reverse: true))
  _Message(text: 'This conversation is long enough to scroll 😄', isMe: false),
  _Message(text: 'Tap scrollTo label to scroll to this message.', isMe: true),
  _Message(
    text: 'CALayer properties: cornerRadius, shadow, border — no draw pass.',
    isMe: false,
  ),
  _Message(
    text: 'Interactive dismiss too — drag the keyboard down!',
    isMe: true,
  ),
  _Message(
    text:
        'Native AppBar layout and positioning — no more weirdness caused by native abstraction.',
    isMe: false,
  ),
  _Message(text: 'CGAffineTransform for keyboard lift.', isMe: true),
  _Message(text: 'But without the JS bridge overhead 🔥', isMe: false),
  _Message(
    text:
        'Layout via FlexLayout / Yoga — same as React Native but with 0 Thread hops and zero overhead: AOT (no JIT)',
    isMe: true,
  ),
  _Message(
    text: 'Every view is a real UIView. Accessibility, VoiceOver, all free.',
    isMe: false,
  ),
  _Message(
    text: 'DartNative runs on the main thread — zero thread hops.',
    isMe: true,
  ),
  _Message(text: 'Running on UIKit via Dart FFI / JNI.', isMe: false),
  _Message(
    text:
        'Native text rendering — UILabel, CoreText, Dynamic Type.😊😊😊🚀🚀🚀',
    isMe: true,
  ),
  _Message(text: 'Native scroll physics — UIScrollView momentum.', isMe: false),
  _Message(
    text:
        'Native keyboard — iOS UITextField or android TextField, correct animation.',
    isMe: true,
  ),
  _Message(
    text: 'No Flutter compositor. No Skia. Just UIKit or Android.',
    isMe: false,
  ),
  _Message(
    text: 'Drop-in Flutter API — same widget names, same props.',
    isMe: true,
  ),
  _Message(text: 'Try typing something below 👇', isMe: false),
];

// Target message number 2 (second-to-last in newest-first ordering).
final int _kScrollToMessageId = _kSeedMessages[_kSeedMessages.length - 2].id;
