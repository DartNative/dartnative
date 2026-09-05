/// The now-playing screen, presented as a full-height native sheet.
///
/// Opened from the mini player; swipe down dismisses it (UIKit handles both).
/// The background is the artwork's own tone, sampled from the cover.
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';

import 'music_data.dart';
import 'music_player.dart';

/// Presents the player over [context].
///
/// Each platform uses its own panel: the detented sheet on iOS, Material's
/// bottom sheet on Android, which sizes itself to the content.
Future<void> showNowPlaying(BuildContext context) {
  if (Platform.isAndroid) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: kNowPlayingBg,
      cornerRadius: 28,
      builder: (_) => const NowPlayingSheet(),
    );
  }
  return showModalSheet<void>(
    context: context,
    detent: SheetDetent.large,
    showDragHandle: true,
    backgroundColor: kNowPlayingBg,
    builder: (_) => const NowPlayingSheet(),
  );
}

class NowPlayingSheet extends StatelessWidget {
  const NowPlayingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayer.instance;
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            // Clearance below the sheet's drag handle.
            SizedBox(height: Platform.isAndroid ? 28 : 52),
            Image.asset(
              kAlbumCover,
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 28),
            ValueListenableBuilder<TrackState>(
              valueListenable: player.track,
              builder: (_, state, __) => _TitleRow(
                title: state.song?.title ?? kAlbumSongs.first.title,
              ),
            ),
            const SizedBox(height: 18),
            const _ProgressSection(),
            const SizedBox(height: 8),
            ValueListenableBuilder<TrackState>(
              valueListenable: player.track,
              builder: (_, state, __) => _TransportRow(playing: state.playing),
            ),
            const SizedBox(height: 18),
            const _VolumeRow(),
            if (Platform.isAndroid)
              const SizedBox(height: 28)
            else
              const Spacer(),
            const _BottomRow(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kMusicText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const _ExplicitBadge(),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                kAlbumArtist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 20),
              ),
            ],
          ),
        ),
        const Icon(
          CupertinoIcons.ellipsis,
          size: 20,
          color: Color(0xB3FFFFFF),
        ),
      ],
    );
  }
}

/// The parental-advisory mark shown beside an explicit title. Drawn rather
/// than shipped as an asset.
class _ExplicitBadge extends StatelessWidget {
  const _ExplicitBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: const Color(0x59FFFFFF),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: const Text(
        'E',
        style: TextStyle(
          color: kMusicText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Scrub bar plus elapsed / remaining.
///
/// While a scrub is in progress the thumb follows the finger from [_scrubValue]
/// rather than the position stream, and playback is paused so repeated seeks
/// don't chatter. See [MusicPlayer.beginScrub] / [MusicPlayer.endScrub].
class _ProgressSection extends StatefulWidget {
  const _ProgressSection();

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  double? _scrubValue;

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayer.instance;
    return ValueListenableBuilder<TrackState>(
      valueListenable: player.track,
      builder: (_, state, __) {
        final totalMs = state.duration.inMilliseconds;
        return ValueListenableBuilder<Duration>(
          valueListenable: player.position,
          builder: (_, streamPos, __) {
            final scrub = _scrubValue;
            final pos = scrub != null
                ? Duration(milliseconds: (scrub * totalMs).round())
                : streamPos;
            final posMs = pos.inMilliseconds.clamp(0, totalMs == 0 ? 1 : totalMs);
            return Column(
              children: [
                Slider(
                  value: scrub ?? (totalMs == 0 ? 0 : posMs / totalMs),
                  activeColor: const Color(0xE6FFFFFF),
                  onChangeStart: (_) {
                    if (totalMs == 0) return;
                    player.beginScrub();
                  },
                  onChanged: (v) {
                    if (totalMs == 0) return;
                    setState(() => _scrubValue = v);
                  },
                  onChangeEnd: (v) {
                    if (totalMs == 0) return;
                    setState(() => _scrubValue = null);
                    player.endScrub(
                      Duration(milliseconds: (v * totalMs).round()),
                    );
                  },
                ),
                Row(
                  children: [
                    Text(
                      formatTime(pos),
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      totalMs == 0
                          ? '--:--'
                          : '-${formatTime(state.duration - pos)}',
                      style: const TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    final player = MusicPlayer.instance;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TransportButton(
          icon: CupertinoIcons.backward_fill,
          size: 34,
          onTap: () => player.seek(Duration.zero),
        ),
        _TransportButton(
          icon: playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
          size: 42,
          onTap: player.toggle,
        ),
        _TransportButton(
          icon: CupertinoIcons.forward_fill,
          size: 34,
          onTap: player.skipForward,
        ),
      ],
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: 60,
        child: Center(child: Icon(icon, size: size, color: kMusicText)),
      ),
    );
  }
}

class _VolumeRow extends StatefulWidget {
  const _VolumeRow();

  @override
  State<_VolumeRow> createState() => _VolumeRowState();
}

class _VolumeRowState extends State<_VolumeRow> {
  late double _volume = MusicPlayer.instance.volume;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.speaker_fill, size: 14, color: Color(0x99FFFFFF)),
        Expanded(
          child: Slider(
            value: _volume,
            activeColor: const Color(0xE6FFFFFF),
            onChanged: (v) {
              setState(() => _volume = v);
              MusicPlayer.instance.setVolume(v);
            },
          ),
        ),
        const Icon(CupertinoIcons.speaker_3_fill, size: 14, color: Color(0x99FFFFFF)),
      ],
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(CupertinoIcons.quote_bubble, size: 22, color: Color(0xB3FFFFFF)),
        // AirPlay has no CupertinoIcons glyph; Material Symbols carries it.
        Icon(MaterialSymbolsRounded.airplay, size: 22, color: Color(0xB3FFFFFF)),
        Icon(CupertinoIcons.list_bullet, size: 22, color: Color(0xB3FFFFFF)),
      ],
    );
  }
}
