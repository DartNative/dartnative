/// What sits on top of each video: the rail of plain white actions down
/// the right edge with their counts, the creator and caption at the
/// bottom left, the Following | For You tabs with AirPlay and Picture in
/// Picture beside them, the thin progress line above the bar, and the
/// comments sheet. AirPlay and Picture in Picture are
/// `dartnative_video_player`'s own.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_share/dartnative_share.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

import 'tiktok_clips.dart';

const _white = Color(0xFFFFFFFF);
const _dim = Color(0xB3FFFFFF);
const _like = Color(0xFFFE2C55);
const _save = Color(0xFFFACE15);

/// The rail's fixed width.
const double kRailWidth = 56;

// Page widgets are rebuilt when they leave PageView's kept window, so
// per-clip state lives here rather than in the page.
final Set<int> _liked = {};
final Set<int> _saved = {};

TextStyle _bold(double size, [Color color = _white]) =>
    TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700);

/// One full-screen page of the feed.
class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.controller,
    required this.clip,
    required this.index,
    required this.isActive,
    required this.paused,
    required this.pipActive,
    required this.airPlayActive,
    required this.onTogglePause,
    required this.onOpenProfile,
    required this.onFollowChanged,
  });

  final VideoPlayerController? controller;
  final TikTokClip clip;
  final int index;
  final bool isActive;
  final bool paused;
  final bool pipActive;
  final bool airPlayActive;
  final VoidCallback onTogglePause;
  final VoidCallback onOpenProfile;
  final VoidCallback onFollowChanged;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool _heartBurst = false;
  Timer? _burstTimer;

  // Likes belong to the clip, not the page: a refresh reorders pages.
  int get _key => widget.clip.id;

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() => _liked.contains(_key) ? _liked.remove(_key) : _liked.add(_key));
  }

  // Double tap likes and never unlikes, like the real thing.
  void _doubleTapLike() {
    HapticFeedback.mediumImpact();
    _burstTimer?.cancel();
    setState(() {
      _liked.add(_key);
      _heartBurst = true;
    });
    _burstTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _heartBurst = false);
    });
  }

  void _toggleSave() {
    HapticFeedback.selectionClick();
    setState(() => _saved.contains(_key) ? _saved.remove(_key) : _saved.add(_key));
  }

  Future<void> _openComments(ClipSocial social) async {
    final clip = widget.clip;
    final count = social.comments + (postedComments[clip.id]?.length ?? 0);
    // The system sheet: native detents, grabber, spring and swipe to
    // dismiss. The body is a Scaffold so the composer can sit in
    // bottomInputBar and ride the keyboard.
    await showModalSheet<void>(
      context: context,
      detent: SheetDetent.large,
      backgroundColor: const Color(0xFF161616),
      header: SheetHeader(title: '${compactCount(count)} comments'),
      builder: (context) => CommentsSheet(clip: clip),
    );
    if (mounted) setState(() {});
  }

  void _follow(String handle) {
    HapticFeedback.mediumImpact();
    setState(() => followed.add(handle));
    widget.onFollowChanged();
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final social = socialFor(clip);
    final controller = widget.controller;
    final ready = controller != null && controller.isInitialized;
    final liked = _liked.contains(_key);
    final saved = _saved.contains(_key);
    // Android's Picture in Picture window shows this screen itself, shrunk:
    // the clip plays there alone, without the page around it.
    final pipWindow = Platform.isAndroid && widget.pipActive;

    return Stack(
      children: [
        // Fixed order: poster, player slot, gestures, then overlays. Filling
        // the player slot changes one child instead of moving the rest.
        Positioned.fill(child: Image.network(clip.posterUrl, fit: BoxFit.cover)),
        Positioned.fill(
          child: ready
              ? VideoPlayer(controller: controller, fit: BoxFit.cover)
              : const SizedBox.shrink(),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTogglePause,
            onDoubleTap: _doubleTapLike,
            child: const SizedBox.expand(),
          ),
        ),
        if (!pipWindow) ...[
          // Scrim so white text reads over a bright clip.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
              ),
            ),
          ),
          if (widget.isActive && widget.paused)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Icon(CupertinoIcons.play_fill, size: 72, color: Color(0x99FFFFFF)),
                ),
              ),
            ),
          if (widget.airPlayActive || widget.pipActive)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.airPlayActive
                          ? 'Playing on AirPlay'
                          : 'Playing in Picture in Picture',
                      style: _bold(15),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _heartBurst ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: AnimatedScale(
                    scale: _heartBurst ? 1 : 0.4,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: const Icon(CupertinoIcons.heart_fill, size: 110, color: _like),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            width: kRailWidth,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(
                  poster: clip.posterUrl,
                  following: followed.contains(social.handle),
                  onTap: widget.onOpenProfile,
                  onFollow: () => _follow(social.handle),
                ),
                const SizedBox(height: 15),
                _RailAction(
                  icon: CupertinoIcons.heart_fill,
                  color: liked ? _like : _white,
                  label: compactCount(social.likes + (liked ? 1 : 0)),
                  onTap: _toggleLike,
                ),
                _RailAction(
                  icon: CupertinoIcons.ellipses_bubble_fill,
                  label: compactCount(
                    social.comments + (postedComments[clip.id]?.length ?? 0),
                  ),
                  onTap: () => _openComments(social),
                ),
                _RailAction(
                  icon: CupertinoIcons.bookmark_fill,
                  color: saved ? _save : _white,
                  label: compactCount(social.saves + (saved ? 1 : 0)),
                  onTap: _toggleSave,
                ),
                _RailAction(
                  icon: CupertinoIcons.arrowshape_turn_up_right_fill,
                  label: compactCount(social.shares),
                  onTap: () => Share.share(clip.url),
                ),
                const SizedBox(height: 7),
                _Disc(poster: clip.posterUrl),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: kRailWidth + 20,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onOpenProfile,
                  child: Text(displayName(social.handle), style: _bold(16)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${social.caption} #pexels #${clip.fps}fps',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.music_note_2, size: 14, color: _white),
                    const SizedBox(width: 6),
                    Text(
                      'original sound · ${social.handle}',
                      style: const TextStyle(color: _white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Following | For You, fixed over the feed rather than part of each page,
/// with AirPlay and Picture in Picture as plain glyphs at the right edge.
///
/// Both labels have the same structure (text, gap, underline) and only the
/// underline's colour differs, so they share a baseline whichever is active.
/// The two halves either side of the labels are equal, so the labels stay
/// centred whatever the right one holds.
class FeedTabs extends StatelessWidget {
  const FeedTabs({
    super.key,
    required this.forYou,
    required this.onSelect,
    required this.pipActive,
    required this.onTogglePip,
  });

  final bool forYou;
  final ValueChanged<bool> onSelect;
  final bool pipActive;
  final VoidCallback onTogglePip;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Spacer(),
      _tab('Following', !forYou, () => onSelect(false)),
      const SizedBox(width: 24),
      _tab('For You', forYou, () => onSelect(true)),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (Platform.isIOS)
              // The plugin's one shared system picker behind a plain glyph.
              const _TopGlyph(icon: CupertinoIcons.tv, onTap: _showAirPlay),
            const SizedBox(width: 2),
            _TopGlyph(
              icon: pipActive
                  ? CupertinoIcons.rectangle_fill_on_rectangle_fill
                  : CupertinoIcons.rectangle_on_rectangle,
              onTap: onTogglePip,
            ),
            // The last glyph shares the rail's centre line: 6 in from the
            // edge plus half the rail's width.
            const SizedBox(width: 16),
          ],
        ),
      ),
    ],
  );

  Widget _tab(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: () {
      if (!active) HapticFeedback.selectionClick();
      onTap();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _bold(17, active ? _white : _dim)),
          const SizedBox(height: 5),
          Container(
            width: 26,
            height: 2.5,
            color: active ? _white : const Color(0x00FFFFFF),
          ),
        ],
      ),
    ),
  );
}

/// A glyph beside the tabs, centred on their text line: a label sits 6
/// down and its text is about 20 tall, so a 32 box shares the centre.
class _TopGlyph extends StatelessWidget {
  const _TopGlyph({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      width: 36,
      height: 32,
      child: Center(child: Icon(icon, size: 20, color: _white)),
    ),
  );
}

/// The creator's picture in a thin white ring, with the Follow badge
/// under it. The badge disappears once the viewer follows.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.poster,
    required this.following,
    required this.onTap,
    required this.onFollow,
  });

  final String poster;
  final bool following;
  final VoidCallback onTap;
  final VoidCallback onFollow;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: kRailWidth,
    height: _size + 10,
    child: Stack(
      children: [
        Positioned(
          left: (kRailWidth - _size) / 2,
          top: 0,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _white, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: ClipOval(child: Image.network(poster, fit: BoxFit.cover)),
              ),
            ),
          ),
        ),
        if (!following)
          Positioned(
            left: (kRailWidth - 20) / 2,
            bottom: 0,
            child: GestureDetector(
              onTap: onFollow,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: _like, shape: BoxShape.circle),
                // Two bars rather than a glyph: the plus keeps the stroke
                // the badge needs, whatever weight the icon font draws.
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 5,
                        top: 9,
                        child: Container(width: 10, height: 2, color: _white),
                      ),
                      Positioned(
                        left: 9,
                        top: 5,
                        child: Container(width: 2, height: 10, color: _white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// One rail action: a plain white glyph and its count, nothing around it.
///
/// Every size here is fixed on purpose. Each widget is a native view with a
/// layout node, and the rail is absolutely positioned; content-sized
/// columns of nested boxes made the layout re-measure the whole rail
/// several times per pass.
class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  static const double _iconBox = 40;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      width: kRailWidth,
      height: _iconBox + 2 + 16 + 11,
      child: Column(
        children: [
          SizedBox(
            width: kRailWidth,
            height: _iconBox,
            child: Center(child: Icon(icon, size: 32, color: color)),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 16,
            child: Text(label, textAlign: TextAlign.center, style: _bold(12)),
          ),
        ],
      ),
    ),
  );
}

/// The record at the foot of the rail: the clip's picture at the centre of
/// a dark disc, the "sound" of the clip.
class _Disc extends StatelessWidget {
  const _Disc({required this.poster});

  final String poster;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF1C1C1E),
      border: Border.all(color: const Color(0xFF3A3A3C), width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: ClipOval(child: Image.network(poster, fit: BoxFit.cover)),
    ),
  );
}

void _showAirPlay() => VideoPlayerController.showAirPlayPicker();

/// The thin line above the bar: a native progress view. There is one, over
/// the pager, following the active clip. While the clip is still loading it
/// has no value, which the framework draws as an indeterminate bar
/// sweeping end to end; once playing it tracks the position.
class PlaybackBar extends StatefulWidget {
  const PlaybackBar({super.key, required this.controller});

  final VideoPlayerController? controller;

  @override
  State<PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends State<PlaybackBar> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PlaybackBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // Ticks only while there is a position to show; four times a second is
  // plenty for a 2pt bar.
  void _sync() {
    if (widget.controller == null) {
      _tick?.cancel();
      _tick = null;
    } else {
      _tick ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    double? value;
    if (c != null) {
      final d = c.durationMs;
      value = d <= 0 ? 0.0 : (c.positionMs / d).clamp(0.0, 1.0);
    }
    return LinearProgressIndicator(
      value: value,
      minHeight: 2,
      color: _white,
      backgroundColor: const Color(0x33FFFFFF),
    );
  }
}

/// The comments sheet. Everything in it is native: the sheet is the
/// system's, the list is a native scroll view, and the composer is a
/// native text field in a Liquid Glass capsule, lifted by the keyboard's
/// own animation through `Scaffold.bottomInputBar`.
class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.clip});

  final TikTokClip clip;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _text = TextEditingController();

  static const _seed = [
    ('mira.k', 'the colours in this are unreal', '2h'),
    ('arjun_travels', 'where is this?? need to go', '3h'),
    ('slowtravel', 'saving this for later', '5h'),
    ('nepalinotes', 'watched it five times', '8h'),
    ('film.nerd', 'what lens is this', '1d'),
    ('kathmandu.frames', 'the light at 0:04', '2d'),
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _post([String? submitted]) {
    final text = (submitted ?? _text.text).trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      postedComments.putIfAbsent(widget.clip.id, () => []).insert(0, text);
      _text.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mine = postedComments[widget.clip.id] ?? const <String>[];
    return Scaffold(
      brightness: Brightness.dark,
      backgroundColor: const Color(0xFF161616),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          for (final text in mine) _comment('you', text, 'now'),
          for (final (user, text, age) in _seed) _comment(user, text, age),
        ],
      ),
      bottomInputBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: GlassEffectContainer(
                brightness: Brightness.dark,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment…',
                      hintStyle: TextStyle(color: Color(0x80FFFFFF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 10, bottom: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _post,
                    style: const TextStyle(color: _white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GlassEffectContainer(
              brightness: Brightness.dark,
              interactive: true,
              tint: _like,
              borderRadius: BorderRadius.circular(20),
              child: GestureDetector(
                onTap: _post,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Icon(CupertinoIcons.arrow_up, size: 20, color: _white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comment(String user, String text, String age) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(color: Color(0xFF2C2C2E), shape: BoxShape.circle),
          child: Center(
            child: Text(user[0].toUpperCase(), style: _bold(14, _dim)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$user · $age', style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8E))),
              const SizedBox(height: 3),
              Text(text, style: const TextStyle(fontSize: 15, color: _white)),
            ],
          ),
        ),
      ],
    ),
  );
}
