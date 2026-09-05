/// Audio demo — standalone example for dartnative_audio.
///
/// Exercises all four public surfaces on iOS and Android:
///   • AudioSession     — configure category before playback / recording
///   • AudioPlayer      — bundled asset playback (beep.wav)
///   • PcmStreamPlayer  — fake TTS chunk (silence then short tone)
///   • AudioRecorder    — start / stop a 16-bit LPCM WAV, show amplitude
///
/// The same code paths run on iOS (AVFoundation) and Android
/// (androidx.media3 + AudioTrack + AudioRecord + AudioManager).
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_permissions/dartnative_permissions.dart';

class AudioDemo extends StatefulWidget {
  const AudioDemo({super.key});

  @override
  State<AudioDemo> createState() => _AudioDemoState();
}

class _AudioDemoState extends State<AudioDemo> {
  // ── AudioPlayer ──────────────────────────────────────────────────────────
  late final AudioPlayer _player;
  StreamSubscription<AudioPlayerEventData>? _playerSub;
  StreamSubscription<Duration>? _playerPositionSub;
  String _playerStatus = '';
  int _playerDurationMs = 0;
  int _playerPositionMs = 0;
  bool _playerIsPlaying = false;

  // ── PcmStreamPlayer ──────────────────────────────────────────────────────
  late final PcmStreamPlayer _pcm;
  bool _pcmConfigured = false;
  String _pcmStatus = '';

  // ── AudioRecorder ────────────────────────────────────────────────────────
  late final AudioRecorder _recorder;
  StreamSubscription<double>? _recorderSub;
  double _amplitudeDb = -160.0;
  bool _isRecording = false;
  String _recorderStatus = '';
  String? _lastRecordingPath;

  // ── Session ──────────────────────────────────────────────────────────────
  String _sessionStatus = '';

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _playerSub = _player.events.listen((e) {
      if (!mounted) return;
      setState(() {
        // Short state label only — 'play' / 'pause' / 'completed' / 'error'.
        // The duration has its own row, and a long value would be truncated.
        _playerStatus = e.type.name;
        if (e.type == AudioPlayerEvent.initialized && e.durationMs != null) {
          _playerDurationMs = e.durationMs!;
        }
      });
    });

    // Live position + play state, sampled by the plugin while listened.
    _playerPositionSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _playerPositionMs = pos.inMilliseconds;
        _playerIsPlaying = _player.isPlaying;
      });
    });

    _pcm = PcmStreamPlayer();
    _recorder = AudioRecorder();
    _recorderSub = _recorder.amplitudeStream.listen((db) {
      if (!mounted) return;
      setState(() => _amplitudeDb = db);
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _playerPositionSub?.cancel();
    _recorderSub?.cancel();
    _player.dispose();
    _pcm.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _configureSessionPlayback() {
    try {
      AudioSession.setCategory(AudioSessionCategory.playback);
      setState(() => _sessionStatus = 'category=playback ✓');
    } catch (e) {
      setState(() => _sessionStatus = 'Error: $e');
    }
  }

  void _configureSessionRecord() {
    try {
      AudioSession.setCategory(
        AudioSessionCategory.playAndRecord,
        mode: AudioSessionMode.measurement,
      );
      setState(
        () => _sessionStatus = 'category=playAndRecord mode=measurement ✓',
      );
    } catch (e) {
      setState(() => _sessionStatus = 'Error: $e');
    }
  }

  void _loadAndPlayAsset() {
    try {
      _player.setAsset('assets/audio/beep.wav');
      _player.play();
      setState(() => _playerStatus = 'loading…');
    } catch (e) {
      setState(() => _playerStatus = 'Error: $e');
    }
  }

  void _pausePlayer() {
    _player.pause();
    setState(() => _playerStatus = 'pause');
  }

  void _stopPlayer() {
    _player.stop();
    setState(() => _playerStatus = 'stop');
  }

  /// Jump relative to the current position.
  void _seekBy(Duration delta) {
    final target = _player.position + delta;
    _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  void _seekToStart() => _player.seek(Duration.zero);

  void _feedPcmTone() {
    try {
      if (!_pcmConfigured) {
        _pcm.configure(sampleRate: 22050, channels: 1, bitsPerSample: 16);
        _pcmConfigured = true;
      }
      // Generate a short 0.5 s 660 Hz tone, signed 16-bit mono @ 22050 Hz.
      const sr = 22050;
      const freq = 660.0;
      const seconds = 0.5;
      final n = (sr * seconds).toInt();
      final buf = ByteData(n * 2);
      for (int i = 0; i < n; i++) {
        final t = i / sr;
        // simple attack/release envelope
        double env = 1.0;
        if (t < 0.01) env = t / 0.01;
        if (t > seconds - 0.05) env = math.max(0, (seconds - t) / 0.05);
        final v = (0.6 * env * 32767 * math.sin(2 * math.pi * freq * t))
            .toInt();
        buf.setInt16(i * 2, v, Endian.little);
      }
      _pcm.feedChunk(buf.buffer.asUint8List());
      setState(
        () => _pcmStatus = 'fed ${n * 2} bytes (~${seconds * 1000}ms tone) ✓',
      );
    } catch (e) {
      setState(() => _pcmStatus = 'Error: $e');
    }
  }

  void _flushPcm() {
    try {
      _pcm.flush();
      setState(() => _pcmStatus = 'flushed ✓');
    } catch (e) {
      setState(() => _pcmStatus = 'Error: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      // The microphone is a runtime permission on both platforms: without an
      // explicit grant AudioRecorder.start() fails and the OS logs
      // "RECORD_AUDIO permission not granted". Ask first, every time — the user
      // can revoke it between runs.
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        setState(
          () => _recorderStatus = micStatus == PermissionStatus.permanentlyDenied
              ? 'Microphone blocked — enable it in Settings'
              : 'Microphone permission denied',
        );
        return;
      }
      // Use a Documents-relative path on both platforms; the OS-specific
      // temporary directory is fine for a demo.
      final tmpDir = Directory.systemTemp.path;
      final path =
          '$tmpDir/dn_audio_demo_${DateTime.now().millisecondsSinceEpoch}.wav';
      final started = _recorder.start(path);
      if (started) {
        setState(() {
          _isRecording = true;
          _recorderStatus = 'recording → ${path.split('/').last}';
          _lastRecordingPath = path;
        });
      } else {
        setState(
          () => _recorderStatus =
              'start() returned false — check microphone permission',
        );
      }
    } catch (e) {
      setState(() => _recorderStatus = 'Error: $e');
    }
  }

  void _stopRecording() {
    try {
      final p = _recorder.stop();
      setState(() {
        _isRecording = false;
        _amplitudeDb = -160.0;
        _recorderStatus =
            p == null ? 'not recording' : 'saved → ${p.split('/').last}';
      });
    } catch (e) {
      setState(() => _recorderStatus = 'Error: $e');
    }
  }

  void _playLastRecording() {
    final p = _lastRecordingPath;
    if (p == null) {
      setState(() => _playerStatus = 'no recording yet');
      return;
    }
    try {
      _player.setPath(p);
      _player.play();
      setState(() => _playerStatus = 'loading…');
    } catch (e) {
      setState(() => _playerStatus = 'Error: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'Audio',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _SectionHeader('Platform'),
          const SizedBox(height: 8),
          Text(
            'Running on ${Platform.operatingSystem}. Same Dart code calls '
            'AVFoundation on iOS and androidx.media3 / AudioTrack / AudioRecord '
            'on Android — no platform branch in this file.',
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── 1. Session ──────────────────────────────────────────────────
          const _SectionHeader('1 · AudioSession'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'playback',
                  onTap: _configureSessionPlayback,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'playAndRecord',
                  onTap: _configureSessionRecord,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ResultRow(label: 'Status', value: _sessionStatus),
          const SizedBox(height: 24),

          // ── 2. AudioPlayer ──────────────────────────────────────────────
          const _SectionHeader('2 · AudioPlayer · assets/audio/beep.wav'),
          const SizedBox(height: 12),
          _ActionButton(label: 'Load + Play', onTap: _loadAndPlayAsset),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(label: 'Pause', onTap: _pausePlayer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(label: 'Stop', onTap: _stopPlayer),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: '⏪ 1s',
                  onTap: () => _seekBy(const Duration(seconds: -1)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(label: 'Restart', onTap: _seekToStart),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: '1s ⏩',
                  onTap: () => _seekBy(const Duration(seconds: 1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ResultRow(label: 'Player', value: _playerStatus),
          _ResultRow(
            label: 'Duration',
            value: _playerDurationMs > 0 ? '${_playerDurationMs}ms' : '—',
          ),
          _ResultRow(label: 'Position', value: '${_playerPositionMs}ms'),
          _ResultRow(label: 'isPlaying', value: '$_playerIsPlaying'),
          const SizedBox(height: 24),

          // ── 3. PcmStreamPlayer ──────────────────────────────────────────
          const _SectionHeader('3 · PcmStreamPlayer · synth tone'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Feed 660Hz chunk',
                  onTap: _feedPcmTone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(label: 'Flush', onTap: _flushPcm),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ResultRow(label: 'PCM', value: _pcmStatus),
          const SizedBox(height: 24),

          // ── 4. AudioRecorder ────────────────────────────────────────────
          const _SectionHeader('4 · AudioRecorder · 16-bit LPCM WAV'),
          const SizedBox(height: 8),
          const Text(
            'Android: host app must request RECORD_AUDIO at runtime first.\n'
            'iOS: NSMicrophoneUsageDescription is in Info.plist; iOS prompts on first record().',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: _isRecording ? 'Recording…' : 'Start Recording',
                  onTap: _isRecording ? null : _startRecording,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Stop',
                  onTap: _isRecording ? _stopRecording : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ActionButton(
            label: 'Play last recording',
            onTap: _lastRecordingPath == null ? null : _playLastRecording,
          ),
          const SizedBox(height: 10),
          _ResultRow(label: 'Recorder', value: _recorderStatus),
          const SizedBox(height: 10),
          _ResultRow(
            label: 'Amplitude',
            value: '${_amplitudeDb.toStringAsFixed(1)} dBFS',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? const Color(0xFF2C2C2E) : const Color(0xFF3A3A3C),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: disabled ? const Color(0xFF48484A) : const Color(0xFF0A84FF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF636366),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
