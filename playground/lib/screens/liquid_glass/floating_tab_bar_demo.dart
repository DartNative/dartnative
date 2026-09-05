/// Liquid Glass — the BARS, finale: the iOS 26 floating tab bar with the
/// CONTROLLER-GATED trio — minimize-on-scroll (`scrollBehavior`), the
/// bottom accessory (`Scaffold.bottomAccessory` → `UITabAccessory`) and the
/// system search pill (`BottomNavigationBarItem.search()` → `UISearchTab`).
///
/// Using any of the three opts the Scaffold's tab pattern into a REAL
/// non-root `UITabBarController`: the IndexedStack children become real
/// child view controllers, so the system behaviors come along 100% native.
/// These APIs live on UITabBarController and need the tab screens to be
/// real child view controllers — a platform-view bar has no screens to
/// give it. Here every tab is a live Dart page.
import 'package:dartnative/dartnative.dart';

import '../home/demo_ui.dart';

class FloatingTabBarDemo extends StatefulWidget {
  const FloatingTabBarDemo({super.key});

  @override
  State<FloatingTabBarDemo> createState() => _FloatingTabBarDemoState();
}

class _FloatingTabBarDemoState extends State<FloatingTabBarDemo> {
  int _tab = 0;
  bool _playing = false;
  String _query = '';

  static const _artists = [
    'Arcade Fire',
    'Beach House',
    'Caribou',
    'Daft Punk',
    'Erlend Øye',
    'Four Tet',
    'Grimes',
    'Hot Chip',
    'Interpol',
    'James Blake',
    'Khruangbin',
    'LCD Soundsystem',
    'M83',
    'Nujabes',
    'Overmono',
    'Phoenix',
    'Röyksopp',
    'SBTRKT',
    'Tame Impala',
    'Yaeji',
  ];

  Widget _row(String text) => Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: kRowBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: kTextPrimary, fontSize: 14),
            ),
          ),
        ),
      );

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        child: Text(
          text,
          style: TextStyle(color: kTextSecondary, fontSize: 13),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? _artists
        : [
            for (final a in _artists)
              if (a.toLowerCase().contains(q)) a
          ];
    return Scaffold(
      // NO extendBody — the tab-controller geometry: the
      // stack container sits BELOW the AppBar, so tab content (and the
      // search results overlay, which shares the container's frame) can
      // never run under it. extendBody would make the container fullscreen
      // and push everything behind the bar.
      appBar: AppBar(
        title: Text(
          'Floating Tab Bar',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? kBarBgGlass : kBarBg,
      ),
      backgroundColor: kHomeBg,
      // The Music-style strip: a LIVE Dart widget hosted by UITabAccessory —
      // floats above the pill and morphs INLINE beside it on minimize.
      // TRANSPARENT content: UITabAccessory draws its own capsule surface —
      // a background here renders as a box-inside-a-box on the platter.
      bottomAccessory: GestureDetector(
        onTap: () => setState(() => _playing = !_playing),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              _playing ? '♫ Playing — Neon Nights' : '▶︎ Paused — tap to play',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown,
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        onSearchQueryChanged: (q) => setState(() => _query = q),
        items: const [
          BottomNavigationBarItem(
            label: 'Feed',
            // Badge on the icon lowers to the NATIVE pill badge.
            icon: Badge(count: 3, child: Icon(CupertinoIcons.list_bullet)),
          ),
          BottomNavigationBarItem(
            label: 'Library',
            icon: Icon(CupertinoIcons.music_note),
          ),
          BottomNavigationBarItem.search(),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          // Tab 0 — Feed: scroll drives the minimize.
          ListView(
            padding: EdgeInsets.only(bottom: isIOS26 ? 140 : 12, top: 8),
            children: [
              _note(
                'Scroll down — the floating pill MINIMIZES into a capsule '
                '(the real tabBarMinimizeBehavior) and the Now Playing '
                'strip morphs inline beside it. Scroll up to restore. Tap '
                'the strip: it\'s a live Dart widget inside UITabAccessory.',
              ),
              for (var i = 0; i < 40; i++) _row('feed item $i'),
              Padding(
                padding: EdgeInsets.only(left: 28, right: 28, top: 12),
                child: Text(
                  'WHY NATIVE MATTERS — minimize, the accessory and the '
                  'search pill are UITabBarController API: they need the '
                  'tab screens to be REAL child view controllers, which a '
                  'platform-view bar cannot reach. Here each of these '
                  'three tabs is a live Dart page hosted as a real child '
                  'view controller.',
                  style: TextStyle(color: kTextTertiary, fontSize: 12),
                ),
              ),
            ],
          ),
          // Tab 1 — Library: switching tabs is native controller switching.
          ListView(
            padding: EdgeInsets.only(bottom: isIOS26 ? 140 : 12, top: 8),
            children: [
              _note(
                'A second live Dart page — switching tabs is real '
                'UITabBarController switching, IndexedStack state intact.',
              ),
              for (final a in _artists) _row(a),
            ],
          ),
          // Tab 2 — the SEARCH tab's results content: the system pill's
          // query streams to Dart and filters this list live.
          ListView(
            padding: EdgeInsets.only(bottom: isIOS26 ? 90 : 12, top: 8),
            children: [
              _note(
                'The separated pill is the system UISearchTab. Type — the '
                'query streams to Dart (onSearchQueryChanged) and filters '
                'this list live${q.isEmpty ? '' : ' · "$q"'}.',
              ),
              if (results.isEmpty)
                _note('No artists match — clear the field to reset.'),
              for (final a in results) _row(a),
            ],
          ),
        ],
      ),
    );
  }
}
