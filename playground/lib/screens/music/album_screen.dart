/// The album screen: artwork, header, Play / Shuffle, and the track list.
///
/// This list is what drives the tab bar's minimize-on-scroll behaviour, so the
/// album repeats to give it length (see [kTrackListCycles]).
import 'package:dartnative/dartnative.dart';

import 'music_data.dart';
import 'music_player.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.onOpenPlayer});

  /// Opens the now-playing sheet (tapping a row plays; the mini player opens).
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final songs = kTrackList;
    return Container(
      color: kMusicBg,
      child: ListView(
        // Clearance for the floating bar + the mini player riding above it.
        padding: EdgeInsets.only(top: 8, bottom: kListBottomPad),
        children: [
          const _AlbumHeader(),
          for (int i = 0; i < songs.length; i++)
            _SongRow(
              song: songs[i],
              showSeparator: i != songs.length - 1,
              onTap: () => MusicPlayer.instance.playSong(songs[i]),
            ),
        ],
      ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        children: [
          // The artwork's own white field gives it its edge; a rounded
          // container clips the corners.
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset(
              kAlbumCover,
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            kAlbumTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kMusicText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            kAlbumArtist,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kMusicRed,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            kAlbumMeta,
            textAlign: TextAlign.center,
            style: TextStyle(color: kMusicSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderButton(
                  icon: CupertinoIcons.play_fill,
                  label: 'Play',
                  onTap: () {
                    MusicPlayer.instance.playSong(kAlbumSongs.first);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _HeaderButton(
                  icon: CupertinoIcons.shuffle,
                  label: 'Shuffle',
                  onTap: () {
                    MusicPlayer.instance.playSong(kAlbumSongs.first);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: kMusicSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: kMusicRed),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: kMusicRed,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.song,
    required this.showSeparator,
    required this.onTap,
  });

  final Song song;
  final bool showSeparator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset(
                kAlbumCover,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Title, artist and the separator share this column so the rule
            // starts at the text, not under the artwork.
            Expanded(
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  border: showSeparator
                      ? const Border(
                          bottom: BorderSide(color: kMusicSeparator, width: 0.5),
                        )
                      : null,
                ),
                child: Row(
                  children: [
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
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            kAlbumArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kMusicSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        CupertinoIcons.ellipsis,
                        size: 18,
                        color: kMusicSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
