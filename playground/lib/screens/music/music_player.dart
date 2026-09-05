/// Shared playback state for the Music showcase.
///
/// The mini player, the album rows, and the now-playing sheet each render in a
/// different place (the sheet is its own Dart root), so playback state lives
/// in one controller they all listen to.
///
/// Two notifiers on purpose: [track] changes rarely, [position] ticks several
/// times a second. Splitting them keeps the title and artwork out of the
/// progress bar's rebuild.
import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_audio/dartnative_audio.dart';

import 'music_data.dart';

/// What is loaded and whether it is running.
class TrackState {
  const TrackState({this.song, this.playing = false, this.duration = Duration.zero});

  final Song? song;
  final bool playing;
  final Duration duration;

  TrackState copyWith({Song? song, bool? playing, Duration? duration}) =>
      TrackState(
        song: song ?? this.song,
        playing: playing ?? this.playing,
        duration: duration ?? this.duration,
      );
}

class MusicPlayer {
  MusicPlayer._();

  static final MusicPlayer instance = MusicPlayer._();

  final ValueNotifier<TrackState> track = ValueNotifier(const TrackState());
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  AudioPlayer? _player;
  StreamSubscription<AudioPlayerEventData>? _events;
  StreamSubscription<Duration>? _positions;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;

    final p = AudioPlayer();
    _events = p.events.listen((e) {
      switch (e.type) {
        case AudioPlayerEvent.initialized:
          track.value =
              track.value.copyWith(duration: Duration(milliseconds: e.durationMs ?? 0));
        case AudioPlayerEvent.play:
          track.value = track.value.copyWith(playing: true);
        case AudioPlayerEvent.pause:
          track.value = track.value.copyWith(playing: false);
        case AudioPlayerEvent.completed:
          track.value = track.value.copyWith(playing: false);
          position.value = Duration.zero;
        case AudioPlayerEvent.error:
          track.value = track.value.copyWith(playing: false);
      }
    });
    _positions = p.positionStream.listen((pos) => position.value = pos);
    p.setVolume(_volume);
    _player = p;
    return p;
  }

  /// Load [song] and start it. Re-tapping the current song toggles play/pause.
  void playSong(Song song) {
    final p = _ensurePlayer();

    if (track.value.song?.title == song.title) {
      _togglePlayback(p);
      return;
    }
    track.value = TrackState(song: song, playing: true);
    position.value = Duration.zero;
    p.setAsset(kSampleTrack);
    p.play();
  }

  /// Play/pause. With nothing loaded yet, which happens when the player is
  /// opened before a song is picked, this starts the album so the control
  /// always does something.
  void toggle() {
    final p = _player;
    if (p == null || track.value.song == null) {
      playSong(kAlbumSongs.first);
      return;
    }
    _togglePlayback(p);
  }

  void _togglePlayback(AudioPlayer p) {
    if (track.value.playing) {
      p.pause();
    } else {
      p.play();
    }
  }

  void seek(Duration to) {
    _player?.seek(to);
    position.value = to;
  }

  /// Output level, 0..1. Held here rather than in the player UI: the native
  /// player is created lazily, so a volume set before the first play must
  /// still apply when it appears, and it has to outlive the sheet.
  double get volume => _volume;
  double _volume = 0.7;

  void setVolume(double v) {
    _volume = v.clamp(0.0, 1.0);
    _player?.setVolume(_volume);
  }

  /// True while a scrub is in progress. The position stream is ignored then,
  /// so the thumb follows the finger instead of snapping back to the
  /// last-reported playback position.
  bool get scrubbing => _resumeAfterScrub != null;
  bool? _resumeAfterScrub;

  /// Pause for the duration of a scrub. Silences the audible chatter of
  /// seeking repeatedly while playing, and remembers whether playback was
  /// running so [endScrub] can restore it.
  void beginScrub() {
    if (_resumeAfterScrub != null) return;
    final wasPlaying = track.value.playing;
    _resumeAfterScrub = wasPlaying;
    if (wasPlaying) _player?.pause();
  }

  /// Land the scrub at [to] and resume if playback was running when it began.
  void endScrub(Duration to) {
    final resume = _resumeAfterScrub;
    _resumeAfterScrub = null;
    seek(to);
    if (resume == true) _player?.play();
  }

  /// Skip forward. The demo ships one sample, so this restarts it.
  void skipForward() => seek(Duration.zero);

  /// Stop playback and release the native player. Called when the showcase is
  /// closed; the next visit re-creates it.
  void release() {
    _events?.cancel();
    _positions?.cancel();
    _events = null;
    _positions = null;
    _player?.dispose();
    _player = null;
    track.value = const TrackState();
    position.value = Duration.zero;
  }
}

/// Track time as `m:ss`.
String formatTime(Duration d) {
  final total = d.inSeconds;
  final m = total ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
