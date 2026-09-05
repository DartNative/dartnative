/// Music: a music app built on the iOS 26 tabbed pattern.
///
/// Three system capabilities carry the screen, all of them native:
///   • the floating glass tab bar, with a separated search pill
///     (`BottomNavigationBarItem.search()` → `UISearchTab`)
///   • the mini player riding above it (`Scaffold.bottomAccessory` →
///     `UITabAccessory`), which morphs inline when the bar minimises
///   • minimize-on-scroll (`TabBarScrollBehavior.minimizeOnScrollDown`)
///
/// Tapping the mini player opens the now-playing sheet; playback is real
/// (dartnative_audio), so the progress bar and scrubbing are live.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import 'album_screen.dart';
import 'music_data.dart';
import 'music_player.dart';
import 'now_playing_sheet.dart';

class MusicDemo extends StatefulWidget {
  const MusicDemo({super.key});

  @override
  State<MusicDemo> createState() => _MusicDemoState();
}

class _MusicDemoState extends State<MusicDemo> {
  int _tab = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Dark-by-design screen: pin dark chrome regardless of the app theme, or
    // the status bar draws dark-on-black in light mode.
    //
    // The nav strip stays transparent on both platforms, because the bar
    // owns that area: iOS 26 floats its pill above it, and the Android bar
    // runs edge-to-edge with its surface extended under the gesture strip.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }

  @override
  void dispose() {
    // Leaving the showcase stops playback and releases the native player.
    MusicPlayer.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMusicBg,
      // NO extendBody: with the tab-controller lowering the stack container
      // already sits below the AppBar, and extending would push content
      // behind it.
      appBar: AppBar(
        // Dark-by-design screen: the chevron defaults to the system accent,
        // which reads as blue here.
        leading: BackButton(iconColor: kMusicText),
        title: const Text(
          kAlbumTitle,
          style: TextStyle(
            color: kMusicText,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isIOS26 ? const Color(0x00000000) : kMusicBg,
      ),
      // The mini player. Content stays transparent because UITabAccessory
      // draws its own capsule; a background here reads as a box in a box.
      bottomAccessory: _MiniPlayer(onTap: () => showNowPlaying(context)),
      bottomNavigationBar: BottomNavigationBar(
        scrollBehavior: TabBarScrollBehavior.minimizeOnScrollDown,
        // Only the selected destination is tinted; unselected items keep
        // the system's default treatment.
        selectedIconColor: kMusicRed,
        selectedLabelFontStyle: const TextStyle(color: kMusicRed),
        backgroundColor: isIOS26 ? null : kMusicBarBg,
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        onSearchQueryChanged: (q) => setState(() => _query = q),
        items: const [
          BottomNavigationBarItem(
            label: 'Home',
            icon: Icon(CupertinoIcons.house_fill),
          ),
          BottomNavigationBarItem(
            label: 'New',
            icon: Icon(CupertinoIcons.square_grid_2x2_fill),
          ),
          BottomNavigationBarItem(
            label: 'Radio',
            icon: Icon(CupertinoIcons.dot_radiowaves_left_right),
          ),
          BottomNavigationBarItem(
            label: 'Library',
            icon: Icon(CupertinoIcons.music_albums_fill),
          ),
          BottomNavigationBarItem.search(),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          AlbumScreen(onOpenPlayer: () => showNowPlaying(context)),
          const _PlaceholderTab(title: 'New'),
          const _PlaceholderTab(title: 'Radio'),
          const _PlaceholderTab(title: 'Library'),
          Platform.isAndroid
              ? const _AndroidSearchTab()
              : _SearchResults(query: _query),
        ],
      ),
    );
  }
}

/// The now-playing strip hosted by `UITabAccessory`: artwork, title, artist,
/// and transport. Tapping anywhere but the buttons opens the full player.
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayer.instance;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        // iOS leaves this clear, since UITabAccessory draws its own capsule.
        // On Android the strip is ours to paint and overlays the list, so it
        // takes the bar's surface.
        color: Platform.isAndroid ? kMusicBarBg : null,
        child: ValueListenableBuilder<TrackState>(
          valueListenable: player.track,
          builder: (_, state, __) {
            final song = state.song ?? kAlbumSongs.first;
            return Row(
              children: [
                // The iOS 26 accessory capsule is rounded, so the artwork
                // starts further in to clear its curve.
                SizedBox(width: isIOS26 ? 16 : 8),
                Image.asset(
                  kAlbumCover,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kMusicText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        kAlbumArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kMusicSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: player.toggle,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 48,
                    child: Center(
                      child: Icon(
                        state.playing
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        size: 20,
                        color: kMusicText,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: player.skipForward,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 40,
                    height: 48,
                    child: Center(
                      child: Icon(
                        CupertinoIcons.forward_fill,
                        size: 20,
                        color: kMusicText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Placeholder destinations. The demo's content lives in Home.
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kMusicBg,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(color: kMusicSecondary, fontSize: 17),
        ),
      ),
    );
  }
}

/// Songs whose title matches [query]; the whole album when it is empty.
List<Song> _matches(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kAlbumSongs;
  return [
    for (final s in kAlbumSongs)
      if (s.title.toLowerCase().contains(q)) s
  ];
}

/// Search for Android: the Material search pill, which morphs into a
/// full-screen search view carrying the results with it.
class _AndroidSearchTab extends StatefulWidget {
  const _AndroidSearchTab();

  @override
  State<_AndroidSearchTab> createState() => _AndroidSearchTabState();
}

class _AndroidSearchTabState extends State<_AndroidSearchTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kMusicBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBar(
              hintText: 'Artists, Songs, Lyrics, and More',
              backgroundColor: kMusicBarBg,
              surfaceColor: kMusicBg,
              onChanged: (q) => setState(() => _query = q),
              // Rendered inside the expanded search view, so the results
              // follow the field rather than staying on the page behind it.
              suggestions: _SearchResults(query: _query),
            ),
          ),
          Expanded(child: _SearchResults(query: '')),
        ],
      ),
    );
  }
}

/// The results list. On iOS the native search pill owns the field and feeds
/// [query]; on Android this also rides inside the search view.
class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final matches = _matches(query);
    return Container(
      color: kMusicBg,
      child: ListView(
        padding: EdgeInsets.only(top: 8, bottom: kListBottomPad),
        children: [
          for (final s in matches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Image.asset(
                    kAlbumCover,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.title,
                      style: const TextStyle(
                        color: kMusicText,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
