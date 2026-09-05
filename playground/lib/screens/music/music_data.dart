/// Album data and palette for the Music showcase.
///
/// Everything the screens render (titles, artist, artwork path, track list)
/// lives here, so swapping the album is a one-file edit.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

/// A track in the album list.
class Song {
  const Song(this.title);

  final String title;
}

/// The one bundled audio file. Every row plays it, so selecting any song
/// behaves normally even though the demo ships a single sample.
const kSampleTrack = 'assets/music/tracks/track_sample_01.mp3';

const kAlbumTitle = 'Blonde';
const kAlbumArtist = 'Frank Ocean';
const kAlbumMeta = 'R&B/Soul · 2016 · Lossless';
const kAlbumCover = 'assets/music/covers/album_main.webp';

/// The album's tracks. Only a short sample of the original track.
const kAlbumSongs = <Song>[
  Song('Nikes'),
  Song('Ivy'),
  Song('Pink + White'),
  Song('Solo'),
  Song('Self Control'),
  Song('Nights'),
];

/// The list repeats the album so there is enough content to scroll, which is
/// what drives the tab bar's minimize behaviour.
const kTrackListCycles = 5;

List<Song> get kTrackList => [
      for (int i = 0; i < kTrackListCycles; i++) ...kAlbumSongs,
    ];

// ── Palette ───────────────────────────────────────────────────────────────────
// Fixed rather than theme-driven: the artwork-derived player background
// only reads correctly against this dark presentation.

/// Bottom clearance for scrolling content. iOS 26 clears the floating pill;
/// Android's bar overlays the content while hiding on scroll, so the list
/// clears the bar band, the gesture inset, and the mini player above them.
double get kListBottomPad =>
    isIOS26 ? 150 : (Platform.isAndroid ? 156 : 24);

/// Screen background.
const kMusicBg = Color(0xFF000000);

/// Accent for the artist name and the Play / Shuffle labels.
const kMusicRed = Color(0xFFFA243C);

/// The bottom bar's surface, and the colour painted behind the system
/// navigation strip so the two meet without a seam.
///
/// Material's own dark surface-container, wallpaper-derived where the device
/// exposes a palette: it keeps the bar looking like a Material bar (distinct
/// from the playground's own) while staying a value we can hand to the strip.
/// Pinned to dark because this screen is dark whatever the app theme is.
final Color kMusicBarBg =
    DynamicColor.colorScheme(brightness: Brightness.dark)?.surfaceContainer ??
        const Color(0xFF211F26);

/// Control surfaces (the Play / Shuffle buttons).
const kMusicSurface = Color(0xFF1C1C1E);

const kMusicText = Color(0xFFFFFFFF);
const kMusicSecondary = Color(0xFF8E8E93);
const kMusicSeparator = Color(0xFF2C2C2E);

/// Now-playing background, sampled from the artwork's photograph.
const kNowPlayingBg = Color(0xFF59443B);
