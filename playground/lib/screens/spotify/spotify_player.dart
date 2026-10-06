/// Playback for the Spotify demo: the song, the silent loop behind the
/// player, and the lyrics timed against the song.
///
/// The video, the cards, the mini player and the lyrics all read one
/// controller, the Music demo's pattern: what is playing changes rarely,
/// the position several times a second, so they are separate notifiers,
/// and the current lyric line is a third that changes only between lines.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_path_provider/dartnative_path_provider.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

import 'spotify_data.dart';

/// Whether the song runs, and how long it is once loaded.
class SpState {
  const SpState({this.playing = false, this.duration = Duration.zero});

  final bool playing;
  final Duration duration;

  SpState copyWith({bool? playing, Duration? duration}) => SpState(
        playing: playing ?? this.playing,
        duration: duration ?? this.duration,
      );
}

class SpLyricLine {
  const SpLyricLine(this.time, this.text);

  final Duration time;
  final String text;
}

/// Lyrics from an LRC file: lines sorted by time, metadata tags and empty
/// lines (instrumental breaks) left out.
class SpLyrics {
  const SpLyrics(this.lines);

  final List<SpLyricLine> lines;

  static final _stamp = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\]');

  factory SpLyrics.parse(String lrc) {
    final out = <SpLyricLine>[];
    for (final raw in const LineSplitter().convert(lrc)) {
      final stamps = _stamp.allMatches(raw).toList();
      if (stamps.isEmpty) continue;
      final text = raw.substring(stamps.last.end).trim();
      if (text.isEmpty) continue;
      // A line sung more than once carries one stamp per time.
      for (final m in stamps) {
        final ms =
            int.parse(m[1]!) * 60000 + (double.parse(m[2]!) * 1000).round();
        out.add(
            SpLyricLine(Duration(milliseconds: ms) + kSpLyricsOffset, text));
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return SpLyrics(out);
  }

  factory SpLyrics.asset(String key) {
    final bytes = loadAssetBytes(key);
    return SpLyrics.parse(bytes == null ? '' : utf8.decode(bytes));
  }

  /// The line being sung at [position]; -1 before the first one.
  int indexAt(Duration position) {
    var lo = 0, hi = lines.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time <= position) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }
}

class SpotifyPlayer {
  SpotifyPlayer._();

  static final SpotifyPlayer instance = SpotifyPlayer._();

  final ValueNotifier<SpState> state = ValueNotifier(const SpState());
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<int> line = ValueNotifier(-1);
  final ValueNotifier<bool> liked = ValueNotifier(true);

  /// True from the loop's first decodable frame; the poster shows until then.
  final ValueNotifier<bool> canvasReady = ValueNotifier(false);

  late final SpLyrics lyrics = SpLyrics.asset(kSpLyrics);

  VideoPlayerController? canvas;

  AudioPlayer? _audio;
  StreamSubscription<AudioPlayerEventData>? _events;
  StreamSubscription<Duration>? _positions;
  StreamSubscription<VideoEvent>? _canvasEvents;

  /// True while a scrub is in progress: the position stream is ignored,
  /// so the thumb follows the finger.
  bool get scrubbing => _resumeAfterScrub != null;
  bool? _resumeAfterScrub;

  /// Loads the song and the loop and starts both. The song repeats, so the
  /// demo keeps playing however long it stays open.
  void start() {
    if (_audio != null) return;
    final a = AudioPlayer()
      ..positionUpdateInterval = const Duration(milliseconds: 100);
    _events = a.events.listen((e) {
      switch (e.type) {
        case AudioPlayerEvent.initialized:
          state.value = state.value
              .copyWith(duration: Duration(milliseconds: e.durationMs ?? 0));
        case AudioPlayerEvent.play:
          state.value = state.value.copyWith(playing: true);
          canvas?.play();
        case AudioPlayerEvent.pause:
        case AudioPlayerEvent.error:
          state.value = state.value.copyWith(playing: false);
          canvas?.pause();
        case AudioPlayerEvent.completed:
          break;
      }
    });
    _positions = a.positionStream.listen((p) {
      if (!scrubbing) _setPosition(p);
    });
    a.setLooping(true);
    a.setAsset(kSpSong);
    a.play();
    _audio = a;
    _startCanvas();
  }

  void _setPosition(Duration p) {
    position.value = p;
    final i = lyrics.indexAt(p);
    if (i != line.value) line.value = i;
  }

  void _startCanvas() {
    final path = _canvasFile();
    if (path == null) return;
    final c = VideoPlayerController(
      dataSource: VideoDataSource.file(path),
      autoDispose: false,
    );
    c.setHintAspectRatio(360 / 780);
    c.setFit(BoxFit.cover);
    _canvasEvents = c.events.listen((e) {
      if (e.type != VideoEventType.initialized) return;
      c.setLooping(true);
      c.setVolume(0);
      c.setFit(BoxFit.cover);
      if (state.value.playing) c.play();
      canvasReady.value = true;
    });
    canvas = c;
    c.initialize();
  }

  /// The video player reads files, not bundled assets, so the loop is
  /// copied out of the bundle once.
  String? _canvasFile() {
    final bytes = loadAssetBytes(kSpCanvas);
    if (bytes == null) return null;
    final file = File('${getTemporaryDirectory()}/spotify_canvas_loop.mp4');
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      file.writeAsBytesSync(bytes, flush: true);
    }
    return file.path;
  }

  void toggle() {
    final a = _audio;
    if (a == null) return start();
    state.value.playing ? a.pause() : a.play();
  }

  void seek(Duration to) {
    _audio?.seek(to);
    _setPosition(to);
  }

  /// Pause for the length of a scrub, so repeated seeks stay silent.
  void beginScrub() {
    if (_resumeAfterScrub != null) return;
    _resumeAfterScrub = state.value.playing;
    if (state.value.playing) _audio?.pause();
  }

  void endScrub(Duration to) {
    final resume = _resumeAfterScrub;
    _resumeAfterScrub = null;
    seek(to);
    if (resume == true) _audio?.play();
  }

  /// One song in the demo: back and forward start it again.
  void restart() => seek(Duration.zero);

  void toggleLiked() {
    HapticFeedback.lightImpact();
    liked.value = !liked.value;
  }

  /// Stops everything and releases the native players. The next visit
  /// starts again from the top.
  void release() {
    _events?.cancel();
    _positions?.cancel();
    _canvasEvents?.cancel();
    _events = null;
    _positions = null;
    _canvasEvents = null;
    _audio?.dispose();
    _audio = null;
    canvas?.dispose();
    canvas = null;
    canvasReady.value = false;
    state.value = const SpState();
    position.value = Duration.zero;
    line.value = -1;
  }
}
