/// TikTok-style feed and profile.
///
/// A vertical `PageView.builder` of full-screen videos that never ends: the
/// pager holds exactly the clips that have "arrived", a batch of thirty at
/// a time, and grows as the user nears the end, the way a feed comes from a
/// server. Players are pooled around the page under the finger, the next
/// pages' first bytes are fetched ahead, and playback switches as a swipe
/// crosses the midpoint.
///
/// Around it, what the real app has: pull to refresh with the video holding
/// still under the finger, Following | For You, a swipe left to the
/// creator's profile, likes, comments in a system sheet, share, and the
/// video plugin's own background playback, lock-screen player, Picture in
/// Picture and AirPlay. The bar at the bottom is TikTok's, five items on
/// black with the framed plus button in the middle.
///
/// The feed follows saileshbro's video-feed-showdown app, branch
/// dartnative-pageview-revisit (github.com/saileshbro/video-feed-showdown),
/// whose report of a feed with ten thousand pages led to the lazy build of
/// the Fast family. The bar's icons are from a Freepik vector set; the
/// Profile tab carries the credit both ask for.
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

import '../home/demo_ui.dart' show playgroundOverlayStyle;
import 'tiktok_bar.dart';
import 'tiktok_clips.dart';
import 'tiktok_page.dart';
import 'tiktok_profile.dart';

/// The feed's pull-to-refresh style; change it here to see the other one.
///
/// `RefreshStyle.pullOver`, the feed's own: the video holds still under the
/// finger while the line and the two dots show over it. `RefreshStyle.pullDown`:
/// the content moves with the finger and the label rides with the dots in
/// the band that opens below the tabs.
const RefreshStyle feedRefreshStyle = RefreshStyle.pullOver;

class TikTokDemo extends StatefulWidget {
  const TikTokDemo({super.key});

  @override
  State<TikTokDemo> createState() => _TikTokDemoState();
}

class _TikTokDemoState extends State<TikTokDemo> with WidgetsBindingObserver {
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, StreamSubscription<VideoEvent>> _subs = {};
  final Set<int> _disposeScheduled = {};
  final PageController _pages = PageController();

  /// Feed and creator profile, side by side: swiping left on a video opens
  /// the profile, as on TikTok.
  final PageController _outer = PageController();
  int _outerPage = 0;

  /// The profile page is being pulled in: its grid starts loading with
  /// the drag rather than when the page has settled.
  bool _profileNear = false;

  /// The bar's selected item; 0 is Home.
  int _tab = 0;

  /// For You or Following, and the clips that feed deals from.
  bool _forYou = true;
  List<TikTokClip> _items = kClips;
  bool _refreshing = false;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  /// The next refresh's first clip, dealt and prepared while the feed is
  /// idle, the way TikTok has its next batch ready before the pull: its
  /// player initialized and paused, its poster precached. A pull then only
  /// swaps it in.
  TikTokClip? _nextRefreshClip;
  VideoPlayerController? _nextRefreshPlayer;

  /// The clip the other feed opens on, chosen while this one plays and its
  /// poster loaded ahead, so a tab switch shows a picture at once and the
  /// video takes its place as soon as its player is ready. Without it the
  /// switch dealt a random clip whose poster and player both started from
  /// nothing, and the page stayed black until one of them arrived.
  TikTokClip? _otherFeedFirst;

  /// The profile page is off screen until a swipe, so it is built after
  /// the first frame instead of in it.
  bool _profileBuilt = false;

  int _activeRow = 0;

  /// Pages the user paused by tapping; they stay paused when revisited.
  final Set<int> _userPaused = {};
  bool _pipActive = false;
  /// True once the screen has settled after the open (see
  /// [FeedTuning.openSettle]); the lock-screen entry waits for it.
  bool _settled = false;
  bool _airPlayActive = false;
  bool _inBackground = false;

  @override
  void initState() {
    super.initState();
    // A dark, full-bleed screen whatever the app theme.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    _outer.addListener(() {
      final near = (_outer.page ?? 0) > 0.02;
      if (near != _profileNear && mounted) setState(() => _profileNear = near);
    });
    VideoCache.configure(maxCacheSize: FeedTuning.maxDiskCacheBytes);
    // Every visit opens on the Infinite Video Scrolling demo's clips;
    // everything after them is random.
    _newSequence(leading: kClips.take(kOpeningCount).toList());
    // The page under the finger has its player at once, so the video shows
    // as soon as it is ready. The pages around it, the refresh clip on the
    // side, the lock-screen entry and the profile page come once the screen
    // has settled, not while it slides in: each set-up runs on the main
    // thread.
    _ensureWindow(_activeRow, upTo: 1);
    _prepareOtherFeed();
    Future.delayed(FeedTuning.openSettle, () {
      if (!mounted) return;
      _settled = true;
      _ensureWindow(_activeRow);
      _attachMedia();
      setState(() => _profileBuilt = true);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs.values) {
      s.cancel();
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    _dropNextRefresh();
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state == AppLifecycleState.paused;
  }

  // ------------------------------------------------------------------ pool

  /// What each page shows. The feed opens on the same clips every visit and
  /// fetches the rest in batches, as a feed comes from a server:
  /// `_sequence` is what has arrived, in page order, and the pager holds
  /// exactly that many pages. A batch deals random clips nobody has seen
  /// yet from `_bag`, the shuffled remainder, refilled once it runs out.
  /// Pages already dealt keep their clip, so swiping back shows what was
  /// there.
  final List<TikTokClip> _sequence = [];
  List<TikTokClip> _bag = [];
  final Random _rng = Random();
  bool _fetching = false;

  int get _pageCount => _sequence.length;

  TikTokClip _clipAt(int index) => _sequence[index];

  /// Deals [n] clips into the sequence: one server page.
  void _dealBatch(int n) {
    for (var i = 0; i < n; i++) {
      if (_bag.isEmpty) _refillBag();
      _sequence.add(_bag.removeLast());
    }
  }

  /// The next batch, once, as a request to a server would go: the pages
  /// arrive a moment later, the pager grows by them, and the window
  /// prepares the neighbours the old end had cut off.
  Future<void> _fetchMore() async {
    if (_fetching) return;
    _fetching = true;
    final from = _sequence.length;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _fetching = false;
    // A refresh or a feed switch meanwhile started a new sequence, which
    // dealt its own first batch.
    if (_sequence.length != from) return;
    _dealBatch(FeedTuning.batch);
    setState(() {});
    _ensureWindow(_activeRow);
  }

  void _refillBag() {
    final dealt = _sequence.map((c) => c.url).toSet();
    var fresh = [for (final c in _items) if (!dealt.contains(c.url)) c];
    // Everything has been shown: start over, but not with a clip just seen.
    if (fresh.isEmpty) {
      final recent = _sequence.reversed.take(3).map((c) => c.url).toSet();
      fresh = [for (final c in _items) if (!recent.contains(c.url)) c];
      if (fresh.isEmpty) fresh = List.of(_items);
    }
    _bag = fresh..shuffle(_rng);
  }

  /// Starts a new deal with its first batch. [leading] pins the first
  /// pages, in order; the rest of the batch is random.
  void _newSequence({List<TikTokClip> leading = const []}) {
    _sequence
      ..clear()
      ..addAll(leading);
    _bag = [];
    _dealBatch(FeedTuning.batch - _sequence.length);
  }

  /// Drops every player and starts the feed over from its first page with
  /// whatever `_items` now holds: a feed switch or a refresh.
  void _resetFeed({VideoPlayerController? first}) {
    final old = Map.of(_controllers);
    final oldSubs = Map.of(_subs);
    _controllers.clear();
    _subs.clear();
    _disposeScheduled.clear();
    _userPaused.clear();
    _activeRow = 0;
    for (final c in old.values) {
      c.pause();
    }
    // A refresh hands over the new deal's first clip already initialized:
    // page 0 rebuilds with a playing video, never a black frame.
    if (first != null) {
      _attachEvents(0, first);
      _controllers[0] = first;
      first.setLooping(true);
      first.setFit(BoxFit.cover);
      if (_tab == 0 && _outerPage == 0) first.play();
    }
    if (_pages.hasClients) _pages.jumpToPage(0);
    setState(() {});
    if (first != null) _attachMedia();
    _syncAutoPip();
    // Dispose after the frame that unmounts their VideoPlayer views.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final s in oldSubs.values) {
        s.cancel();
      }
      for (final c in old.values) {
        c.dispose();
      }
      // The freed decoders settle before their replacements are created: a
      // player created while the budget is still taken can open with no
      // frame. The next refresh's clip goes first, for the head start on
      // the network.
      Future.delayed(FeedTuning.disposeSettle, () {
        if (!mounted || _items.isEmpty) return;
        _prepareNextRefresh();
        _ensureWindow(0);
        setState(() {});
      });
    });
  }

  void _selectFeed(bool forYou) {
    if (forYou == _forYou) return;
    _forYou = forYou;
    _items = forYou ? kClips : followingClips();
    final first = _otherFeedFirst;
    _newSequence(leading: [if (first != null && _items.contains(first)) first]);
    _dropNextRefresh();
    _resetFeed();
    _prepareOtherFeed();
  }

  /// Picks the clip the other feed will open on and loads its poster.
  void _prepareOtherFeed() {
    final other = _forYou ? followingClips() : kClips;
    final clip = other.isEmpty ? null : other.first;
    _otherFeedFirst = clip;
    if (clip != null) precacheImage(NetworkImage(clip.posterUrl));
  }

  /// Deals the next refresh's clip, one not yet shown, and readies it on
  /// the side: the player initializes now, paused, and the poster loads,
  /// so the pull that comes later finds both done.
  void _prepareNextRefresh() {
    if (!mounted || _nextRefreshPlayer != null) return;
    final dealt = _sequence.map((c) => c.url).toSet();
    var fresh = [for (final c in _items) if (!dealt.contains(c.url)) c];
    if (fresh.isEmpty) fresh = List.of(_items);
    if (fresh.isEmpty) return;
    final clip = fresh[_rng.nextInt(fresh.length)];
    _nextRefreshClip = clip;
    _nextRefreshPlayer = _controllerFor(clip)..initialize();
    precacheImage(NetworkImage(clip.posterUrl));
  }

  void _dropNextRefresh() {
    _nextRefreshPlayer?.dispose();
    _nextRefreshPlayer = null;
    _nextRefreshClip = null;
  }

  /// Pull to refresh, or a Home re-tap. There is no server, so "new
  /// content" is a clip not yet shown, dealt and prepared ahead of the pull
  /// ([_prepareNextRefresh]); the pull only swaps it in, and the current
  /// video keeps playing until then. A pull that comes before the prepared
  /// clip is ready waits for it a moment, and on iOS for its first frame;
  /// past that the swap goes ahead and the poster covers the page until
  /// the video arrives, since a refresh that the finger cannot feel for
  /// seconds reads as a dead screen.
  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _items = _forYou ? kClips : followingClips();
    if (_nextRefreshPlayer == null) {
      // A refresh from a page whose window holds every decoder, the Home
      // re-tap away from the top: the page farthest from the finger gives
      // its decoder up, and the freed one settles before the clip takes it.
      if (_controllers.length >= FeedTuning.maxLivePlayers) {
        final far = _controllers.keys.reduce(
          (a, b) => (a - _activeRow).abs() >= (b - _activeRow).abs() ? a : b,
        );
        _subs.remove(far)?.cancel();
        _controllers.remove(far)?.dispose();
        await Future.delayed(FeedTuning.disposeSettle);
        if (!mounted) {
          _refreshing = false;
          return;
        }
      }
      _prepareNextRefresh();
    }
    final first = _nextRefreshClip;
    final controller = _nextRefreshPlayer;
    _nextRefreshClip = null;
    _nextRefreshPlayer = null;
    if (first == null || controller == null) {
      _refreshing = false;
      return;
    }
    if (!controller.isInitialized) {
      final ready = Completer<void>();
      final sub = controller.events.listen((e) {
        if ((e.type == VideoEventType.initialized || e.type == VideoEventType.error) &&
            !ready.isCompleted) {
          ready.complete();
        }
      });
      if (controller.isInitialized && !ready.isCompleted) ready.complete();
      await ready.future.timeout(const Duration(milliseconds: 1500), onTimeout: () {});
      await sub.cancel();
    }
    // iOS decodes the first frame off screen, so the swap waits for it and
    // page 0 shows the video from its first frame. Android renders only
    // into an attached view, so there the swap goes at ready to play and
    // the poster covers the moment until the frame.
    if (Platform.isIOS && controller.isInitialized && !controller.hasFirstFrame) {
      final frame = Completer<void>();
      final sub = controller.events.listen((e) {
        if (e.type == VideoEventType.firstFrame && !frame.isCompleted) {
          frame.complete();
        }
      });
      if (controller.hasFirstFrame && !frame.isCompleted) frame.complete();
      await frame.future.timeout(const Duration(milliseconds: 600), onTimeout: () {});
      await sub.cancel();
    }
    if (!mounted) {
      controller.dispose();
      _refreshing = false;
      return;
    }
    _newSequence(leading: [first]);
    _resetFeed(first: controller);
    _refreshing = false;
  }

  void _onFollowChanged() {
    setState(() {});
    // The Following feed follows the follow list, from the top.
    if (!_forYou) {
      _items = followingClips();
      _newSequence();
      _dropNextRefresh();
      _resetFeed();
    } else {
      // Its opening clip may have changed with the list.
      _prepareOtherFeed();
    }
  }

  void _onTab(int tab) {
    HapticFeedback.selectionClick();
    if (tab == 0 && _tab == 0) {
      _homeAgain();
      return;
    }
    setState(() => _tab = tab);
    _applyVisibility();
  }

  /// Home tapped while on Home: back to the top of the feed and refresh.
  void _homeAgain() {
    if (_outerPage != 0) {
      _outer.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
    final indicator = _refreshKey.currentState;
    if (indicator != null) {
      indicator.show();
    } else {
      _refresh();
    }
  }

  /// Plays the active clip only when the feed is what's on screen.
  void _applyVisibility() {
    final c = _controllers[_activeRow];
    if (c == null || !c.isInitialized) return;
    final visible = _tab == 0 && _outerPage == 0;
    if (visible && !_userPaused.contains(_activeRow)) {
      c.play();
    } else {
      c.pause();
    }
    _syncAutoPip();
  }

  void _openClip(TikTokClip clip) {
    // From a profile grid: the clip becomes the next page, and everything
    // dealt after it is dealt again.
    final next = _activeRow + 1;
    _sequence
      ..removeRange(next, _sequence.length)
      ..add(clip);
    _bag.remove(clip);
    // Players already built for the old pages go, after the frame that
    // unmounts their views.
    final stale = <VideoPlayerController>[];
    for (final i in _controllers.keys.where((i) => i >= next).toList()) {
      _subs.remove(i)?.cancel();
      stale.add(_controllers.remove(i)!..pause());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in stale) {
        c.dispose();
      }
    });
    _outer.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    _pages.jumpToPage(next);
    _onPageChanged(next);
  }

  /// How many page players may live around [center]. On the first page,
  /// the only one a pull can refresh, one decoder stays free for the next
  /// refresh's prepared clip; everywhere else the pages have them all,
  /// so the page ahead is ready before the swipe lands on it.
  int _budgetAt(int center) => FeedTuning.maxLivePlayers - (center == 0 ? 1 : 0);

  /// The pages that hold a player around [center], in fill order and
  /// within the budget: the page under the finger, then the next, then the
  /// previous, then the ones after next.
  List<int> _windowFor(int center) {
    final ordered = <int>{
      center,
      center + 1,
      center - 1,
      for (var k = 2; k <= FeedTuning.preloadAhead; k++) center + k,
    }.where((i) => i >= 0 && i < _pageCount);
    return ordered.take(_budgetAt(center)).toList();
  }

  /// Fills the window around [center]. With [upTo], players are created
  /// only until that many exist (the open: the page under the finger
  /// alone), and the refresh clip and the pre-caching wait for the full
  /// call.
  void _ensureWindow(int center, {int? upTo}) {
    final window = _windowFor(center);
    for (final i in window) {
      // The poster of every page in the window, so a page shows its picture
      // from its first frame while its player readies.
      precacheImage(NetworkImage(_clipAt(i).posterUrl));
      if (_controllers.containsKey(i) || _disposeScheduled.contains(i)) continue;
      if (_controllers.length >= _budgetAt(center)) break;
      if (upTo != null && _controllers.length >= upTo) break;
      _create(i);
    }
    if (upTo != null) return;
    // Back on the first page with its window settled, the refresh clip
    // takes the decoder kept for it.
    if (center == 0 && _controllers.length <= _budgetAt(0) && _disposeScheduled.isEmpty) {
      _prepareNextRefresh();
    }
    final last = center + FeedTuning.preloadAhead + FeedTuning.preCacheBeyond;
    for (var i = center + 1; i <= last && i < _pageCount; i++) {
      final url = _clipAt(i).url;
      VideoCache.preCache(url, cacheKey: url, preCacheSize: FeedTuning.preCacheBytes);
    }
  }

  void _create(int index) {
    final controller = _controllerFor(_clipAt(index));
    _attachEvents(index, controller);
    _controllers[index] = controller;
    controller.initialize();
  }

  /// A configured player for [clip], not yet initialized.
  VideoPlayerController _controllerFor(TikTokClip clip) {
    final controller = VideoPlayerController(
      dataSource: VideoDataSource.network(
        clip.url,
        cacheConfig: VideoCacheConfig(
          useCache: true,
          preCacheSize: FeedTuning.preCacheBytes,
          maxCacheSize: FeedTuning.maxDiskCacheBytes,
          key: clip.url,
        ),
        videoExtension: 'mp4',
        bufferingConfig: VideoBufferingConfig.feed,
      ),
      autoPlay: false,
      autoDispose: false,
      // The audio goes on with the screen locked.
      allowBackgroundPlayback: true,
    );
    controller.setHintAspectRatio(clip.aspectRatio);
    controller.setFit(BoxFit.cover);
    return controller;
  }

  void _attachEvents(int index, VideoPlayerController controller) {
    _subs[index] = controller.events.listen((e) {
      if (!mounted) return;
      switch (e.type) {
        case VideoEventType.initialized:
          controller.setLooping(true);
          controller.setFit(BoxFit.cover);
          if (index == _activeRow &&
              !_userPaused.contains(index) &&
              _tab == 0 &&
              _outerPage == 0) {
            controller.play();
          }
          setState(() {});
          if (index == _activeRow) _attachMedia();
          _syncAutoPip();
        case VideoEventType.pipStarted:
          setState(() => _pipActive = true);
        case VideoEventType.pipStopped:
        case VideoEventType.pipFailed:
          setState(() => _pipActive = false);
        case VideoEventType.remoteCommand:
          // The lock screen, Control Center, the notification, headphones.
          // Play, pause and the scrubber are done by the plugin; next and
          // previous move the feed.
          switch (e.command!) {
            case RemoteCommand.next:
              _goTo(_activeRow + 1);
            case RemoteCommand.previous:
              _goTo(_activeRow - 1);
            case RemoteCommand.play:
              setState(() => _userPaused.remove(index));
            case RemoteCommand.pause:
              setState(() => _userPaused.add(index));
            case RemoteCommand.seek:
              break;
          }
        case VideoEventType.externalPlaybackChanged:
          // The video went to an AirPlay screen, or came back; the page
          // shows a line over the poster meanwhile.
          if (index == _activeRow) {
            setState(() => _airPlayActive = controller.isExternalPlaybackActive);
          }
        case VideoEventType.error:
          // A page whose player failed keeps its poster; the reason goes
          // to the console so a clip that never starts can be traced.
          dnLog('[TikTok] page $index clip ${_clipAt(index).id} failed: '
              '${e.errorMessage ?? 'no message'}');
        default:
          break;
      }
    });
  }

  void _evictFar(int center) {
    final keep = _windowFor(center).toSet();
    for (final i in _controllers.keys.toList()) {
      if (keep.contains(i) || _disposeScheduled.contains(i)) continue;
      _disposeScheduled.add(i);
      _controllers[i]?.pause();
      // The freed decoder settles before its replacement is created; the
      // page that takes it is the one ahead, off screen, never the one
      // under the finger, which was readied a swipe earlier.
      Future.delayed(FeedTuning.disposeSettle, () {
        _disposeScheduled.remove(i);
        if (!mounted) return;
        if (_windowFor(_activeRow).contains(i)) return;
        _subs.remove(i)?.cancel();
        _controllers.remove(i)?.dispose();
        _ensureWindow(_activeRow);
        if (mounted) setState(() {});
      });
    }
  }

  // -------------------------------------------------------------- playback

  void _applyActive(int row) {
    for (final entry in _controllers.entries) {
      if (entry.key == row) {
        if (entry.value.isInitialized && !_userPaused.contains(row)) {
          entry.value.play();
        }
      } else {
        entry.value.pause();
      }
    }
    _syncAutoPip();
  }

  /// Only the clip on screen floats when the user leaves the app: the
  /// plugin's automatic Picture in Picture follows the active page.
  void _syncAutoPip() {
    final visible = _tab == 0 && _outerPage == 0;
    for (final entry in _controllers.entries) {
      entry.value.setAutoPictureInPicture(visible && entry.key == _activeRow);
    }
  }

  /// Fires as a swipe crosses the midpoint between two pages.
  void _onPageChanged(int row) {
    if (row == _activeRow) return;
    _activeRow = row;
    // Away from the first page a pull cannot reach the feed, and the clip
    // prepared for it gives its decoder to the page ahead.
    if (row != 0) _dropNextRefresh();
    _ensureWindow(row);
    _applyActive(row);
    _evictFar(row);
    if (mounted) setState(() {});
    _attachMedia();
    // Near the end of what has arrived: the next batch goes out now.
    if (row >= _sequence.length - FeedTuning.fetchAhead) _fetchMore();
  }

  void _togglePause() {
    final c = _controllers[_activeRow];
    if (c == null || !c.isInitialized) return;
    setState(() {
      if (c.isPlaying) {
        c.pause();
        _userPaused.add(_activeRow);
      } else {
        c.play();
        _userPaused.remove(_activeRow);
      }
    });
  }

  /// Puts the active page's player on the lock screen, in Control Center
  /// and in the media notification through the video plugin. AirPlay needs
  /// nothing here: every player routes its video to the screen the user
  /// picks, and the page follows the plugin's event.
  void _attachMedia() {
    if (!_settled) return;
    final row = _activeRow;
    final c = _controllers[row];
    if (c == null || !c.isInitialized) return;
    final clip = _clipAt(row);
    final social = socialFor(clip);
    c.setNowPlaying(NowPlayingInfo(
      title: social.caption,
      artist: '@${social.handle}',
      artworkUrl: clip.posterUrl,
      hasNext: true,
      hasPrevious: row > 0,
    ));
    _airPlayActive = c.isExternalPlaybackActive;
  }

  void _goTo(int row) {
    if (row < 0 || row >= _pageCount) return;
    // In the background there is no display link to animate with, so jump.
    if (_inBackground) {
      _pages.jumpToPage(row);
    } else {
      _pages.animateToPage(
        row,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    // Keeps the pool right even if the jump does not report a page change.
    _onPageChanged(row);
  }

  /// Android's Picture in Picture window shows the screen itself, shrunk,
  /// so while it is open the screen is the playing clip alone.
  bool get _pipWindow => Platform.isAndroid && _pipActive;

  /// The feed's loading mark, two animated dots (a Lottie animation).
  static const Widget _dots = SizedBox(
    width: 40,
    height: 16,
    child: Lottie(asset: 'assets/animations/loading_dots.json', loop: true),
  );

  VideoPlayerController? _readyController(int row) {
    final c = _controllers[row];
    return c != null && c.isInitialized ? c : null;
  }

  /// The plugin's own Picture in Picture on the active page's player.
  void _togglePip() {
    final c = _controllers[_activeRow];
    if (c == null) return;
    if (c.isPictureInPictureActive) {
      c.exitPictureInPicture();
    } else {
      c.enterPictureInPicture();
    }
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    // The bar is opaque and sits under the feed, so the video ends at its
    // top edge and the bar takes the bottom safe area.
    return Scaffold(
      brightness: Brightness.dark,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _home(context),
                const _Placeholder(
                  icon: CupertinoIcons.search,
                  text: 'Search is not part of this demo',
                ),
                const _Placeholder(
                  icon: CupertinoIcons.plus_app,
                  text: 'Creating is not part of this demo',
                ),
                const _Placeholder(icon: CupertinoIcons.tray, text: 'No new activity'),
                const _About(),
              ],
            ),
          ),
          if (!_pipWindow) TikTokBar(current: _tab, onTap: _onTab),
        ],
      ),
    );
  }

  Widget _home(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return PageView(
      controller: _outer,
      scrollDirection: Axis.horizontal,
      allowImplicitScrolling: true,
      onPageChanged: (page) {
        _outerPage = page;
        setState(() {});
        _applyVisibility();
      },
      children: _homePages(context, insets),
    );
  }

  List<Widget> _homePages(BuildContext context, EdgeInsets insets) => [
    if (_items.isEmpty)
      Stack(
        children: [
          const _Placeholder(
            icon: CupertinoIcons.person_2,
            text: 'Follow creators and their videos show up here',
          ),
          Positioned(
            top: insets.top + 4,
            left: 0,
            right: 0,
            child: FeedTabs(
              forYou: _forYou,
              onSelect: _selectFeed,
              pipActive: _pipActive,
              onTogglePip: _togglePip,
            ),
          ),
          _backButton(context, insets),
        ],
      )
    else
      // Pull over, the default: the video holds still under the finger,
      // and the tab row turns into the refresh line while the pull and the
      // refresh last, as the platform's own feeds do. Pull down, from the
      // arrow glyph in the tab row: the content follows the finger and the
      // label rides with it in the band below the tab row. Both show the
      // feed's two animated dots.
      RefreshIndicator(
        key: _refreshKey,
        style: feedRefreshStyle,
        onRefresh: _refresh,
        // Pull down: the band opens below the tab row, and a trigger close
        // to the rest keeps the content from bumping up at the release.
        edgeOffset: switch (feedRefreshStyle) {
          RefreshStyle.pullDown => insets.top + 44,
          RefreshStyle.pullOver => 0,
        },
        triggerDistance: switch (feedRefreshStyle) {
          RefreshStyle.pullDown => 40,
          RefreshStyle.pullOver => 80,
        },
        displacement: switch (feedRefreshStyle) {
          RefreshStyle.pullDown => 44,
          RefreshStyle.pullOver => 40,
        },
        builder: (context, pager, pull) => Stack(
          children: [
            pager,
            if (!_pipWindow) ...[
              if (feedRefreshStyle == RefreshStyle.pullDown)
                // The pull's own label and the dots ride with the content,
                // the label kept through the refresh and the way back: the
                // refresh completes at once here, and a loading word
                // flashing as the row rides up reads wrong. A fixed width
                // keeps the dots in place as the label changes.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PullDownIndicator(
                    state: pull,
                    edgeOffset: insets.top + 44,
                    size: 20,
                    gap: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 136,
                          child: Text(
                            pull.phase == RefreshPhase.pulling
                                ? 'Pull down to refresh'
                                : 'Release to refresh',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _dots,
                      ],
                    ),
                  ),
                )
              else
                // While the finger pulls, the refresh line slides down in
                // the tab row's place over the top gradient and the tabs
                // fade out; on release the line slides back up, the dots
                // that rode beside it stay where it rested while the
                // refresh runs, and the tabs return when it ends.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: PullOverIndicator(
                      state: pull,
                      labelOffset: insets.top + 30,
                      child: _dots,
                    ),
                  ),
                ),
              Positioned(
                top: insets.top + 4,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: feedRefreshStyle == RefreshStyle.pullOver &&
                          (pull.phase == RefreshPhase.pulling ||
                              pull.phase == RefreshPhase.armed ||
                              pull.phase == RefreshPhase.refreshing)
                      ? 0
                      : 1,
                  duration: const Duration(milliseconds: 160),
                  child: FeedTabs(
                forYou: _forYou,
                onSelect: _selectFeed,
                pipActive: _pipActive,
                onTogglePip: _togglePip,
              ),
                ),
              ),
              _backButton(context, insets),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PlaybackBar(controller: _readyController(_activeRow)),
              ),
            ],
          ],
        ),
        child: PageView.builder(
          controller: _pages,
          scrollDirection: Axis.vertical,
          // Pages are built as the user nears them, as Flutter's are, so
          // itemCount is a number, not a cost: a feed of ten thousand
          // pages launches like one of thirty. What a feed passes is what
          // it has: the clips that have arrived, grown as batches land, or
          // null for no end. A page that leaves the kept window releases
          // what it built, so page state lives here in the parent (the
          // player pool, the likes), never in the page.
          itemCount: _sequence.length,
          // The neighbour page is built before the swipe reveals it, so a
          // swipe lands on a page with its video, never on a black one; the
          // players are windowed anyway.
          allowImplicitScrolling: true,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final isActive = index == _activeRow;
            return FeedPage(
              controller: _controllers[index],
              clip: _clipAt(index),
              index: index,
              isActive: isActive,
              paused: _userPaused.contains(index),
              pipActive: isActive && _pipActive,
              airPlayActive: isActive && _airPlayActive,
              onTogglePause: _togglePause,
              onOpenProfile: () => _outer.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              onFollowChanged: _onFollowChanged,
            );
          },
        ),
      ),
    if (_items.isNotEmpty && _profileBuilt)
      ProfilePage(
        handle: socialFor(_clipAt(_activeRow)).handle,
        showGrid: _outerPage == 1 || _profileNear,
        onBack: () => _outer.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
        onFollowChanged: _onFollowChanged,
        onOpenClip: _openClip,
      ),
  ];

  /// The way out of the demo, at the top left where the real app keeps
  /// its LIVE button, in the same place and size as the profile's back
  /// button, so the arrow holds still when the profile slides in.
  Widget _backButton(BuildContext context, EdgeInsets insets) => Positioned(
    top: insets.top,
    left: TikTokBackButton.inset,
    child: TikTokBackButton(onTap: () => Navigator.pop(context)),
  );
}

/// The Profile tab: where this demo comes from, and the credit the bar's
/// icons ask for.
class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.info_circle, size: 44, color: Color(0x66FFFFFF)),
            const SizedBox(height: 12),
            const Text(
              'About this demo',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The feed follows the video-feed-showdown app by saileshbro on '
              'GitHub, branch dartnative-pageview-revisit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bar icons designed by Freepik.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: const Color(0x66FFFFFF)),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 15)),
        ],
      ),
    ),
  );
}
