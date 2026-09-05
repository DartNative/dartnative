/// SuperTonic demo — standalone example for dartnative_supertonic_tts (iOS + Android).
///
/// • One model variant (mobile int8, ~144 MB) — downloaded on first Speak/Download.
/// • Type text, pick a Language, a Voice (F1–F5 / M1–M5) and a Quality tier
///   (denoising steps), adjust Speed, then Speak — pure-Dart 4-model ONNX
///   pipeline played through dartnative_audio's PcmStreamPlayer @ 44.1 kHz.
///
/// Models download from HuggingFace (sherpa int8 weights + official JSON
/// sidecars); the example never touches a private CDN.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_audio/dartnative_audio.dart';
import 'package:dartnative_supertonic_tts/dartnative_supertonic_tts.dart';

import 'language_picker_screen.dart';
import '../home/demo_ui.dart';

/// Single verbose-log switch for this demo. Flip to `true` (or wire to
/// `kDebugMode`) to see the high-volume per-chunk feed lines + audio stats; it
/// ALSO turns on the engine's verbose logs ([SuperTonicTTS.verboseLogging],
/// applied in `initState`). The always-on lines (tap, first-audio, overlap
/// warnings, synth-done) ignore this flag.
///
/// Note: the native audio player (`DNPcmStreamPlayer`) has its OWN verbose flag
/// in its Swift/Kotlin source — set that there to get the per-buffer native
/// logs in logcat / the Xcode console.
bool verboseLogs = false;

/// Always-on, wall-clock-stamped logger — shows as `[SuperTonicDemo …]` in
/// `dn run`. Stamped so it lines up against the native player logs
/// (`DNPcmStreamPlayer`) when chasing the overlap / first-audio issues.
void _log(String m) => dnLog('[SuperTonicDemo ${_now()}] $m');

/// Verbose, high-volume logger (per-chunk feeds, audio stats) — only prints when
/// [verboseLogs] is on.
void _vlog(String m) {
  if (verboseLogs) dnLog('[SuperTonicDemo ${_now()}] $m');
}

/// `HH:mm:ss.mmm` wall-clock stamp for cross-correlation with native logs.
String _now() {
  final t = DateTime.now();
  String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
  return '${p(t.hour)}:${p(t.minute)}:${p(t.second)}.${p(t.millisecond, 3)}';
}

/// Locates bundled model files inside `flutter_assets` (see
/// `scripts/fetch_bundled_models.sh`). Returns the dir only if it actually holds
/// the files; otherwise `null` → ModelManager downloads everything. Tries the
/// known flutter_assets locations across platforms.
String? _resolveBundledDir() {
  final exe = File(Platform.resolvedExecutable).parent.path;
  const rel = 'flutter_assets/assets/supertonic';
  final candidates = <String>[
    '$exe/$rel', // iOS (dartnative), generic
    '$exe/Frameworks/App.framework/$rel', // iOS (stock Flutter layout)
    '$exe/data/$rel', // Android-ish
  ];
  for (final c in candidates) {
    if (File('$c/tts.json').existsSync()) return c;
  }
  return null;
}

class SuperTonicDemo extends StatefulWidget {
  const SuperTonicDemo({super.key});

  @override
  State<SuperTonicDemo> createState() => _SuperTonicDemoState();
}

class _SuperTonicDemoState extends State<SuperTonicDemo> {
  final _text = TextEditingController(
    text: 'Hello! This is SuperTonic, running fully on-device.',
  );
  final _player = PcmStreamPlayer();
  bool _playerConfigured = false;

  // One manager, bundle-aware: reads files bundled in flutter_assets in place
  // and downloads only what's missing (the ~78 MB vector_estimator, if the
  // other files were bundled via scripts/fetch_bundled_models.sh).
  final ModelManager _manager = ModelManager(bundledDir: _resolveBundledDir());
  SuperTonicTTS? _engine;
  bool _installed = false;
  String _lang = 'en';
  String _voice = 'F1';
  int _steps = 8; // denoising steps / quality (2–16; 8 = medium)
  double _speed = 1.0;
  bool _loading = false;
  bool _speaking = false;
  double _progress = 0;
  String _status = 'Loading…';

  // Monotonic id for each Speak invocation. Threaded into every log line so the
  // streaming/overlap behaviour can be traced: if a chunk is fed while a NEWER
  // gen is active, the old utterance is bleeding over the new one.
  int _speakGen = 0;

  bool get _busy => _loading || _speaking;
  bool get _ready => _engine?.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    // Verbose engine logs follow the demo's switch (per-chunk synth/RTF lines).
    SuperTonicTTS.verboseLogging = verboseLogs;
    // Make the Android system navigation bar + its divider transparent so the
    // app draws edge-to-edge; keep the dark status bar.
    // Transparent bars (an opaque statusBarColor overlay paints over the
    // iOS 26 glass bar frost); icon brightness follows the theme.
    SystemChrome.setSystemUIOverlayStyle(playgroundOverlayStyle());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _installed = _manager.isReady();
    } catch (e) {
      _log('isReady threw $e');
    }
    if (!mounted) return;
    setState(
      () => _status = _installed
          ? 'Model ready — tap Speak.'
          : 'Tap Download to fetch the model (~${_manager.pendingDownloadMB()} MB).',
    );
  }

  void _onAction() {
    _log('TAP action: busy=$_busy installed=$_installed ready=$_ready '
        'loading=$_loading speaking=$_speaking');
    if (_busy) {
      _log('TAP ignored — busy (a Speak/Load is still in flight)');
      return;
    }
    if (!_installed) {
      _ensureLoaded();
    } else {
      _speak();
    }
  }

  String get _actionLabel {
    if (_loading) {
      return _installed
          ? 'Loading…'
          : 'Downloading…  ${(_progress * 100).toStringAsFixed(0)}%';
    }
    if (_speaking) return 'Synthesising…';
    if (!_installed)
      return 'Download model (~${_manager.pendingDownloadMB()} MB)';
    return 'Speak';
  }

  /// Download (if needed) + initialize the ONNX sessions, then cache the engine.
  Future<void> _ensureLoaded() async {
    if (_busy) return;
    if (_engine?.isInitialized ?? false) {
      setState(() => _status = 'Model ready.');
      return;
    }
    setState(() {
      _loading = true;
      _progress = 0;
      _status = 'Preparing…';
    });
    final sw = Stopwatch()..start();
    try {
      final tts = SuperTonicTTS.withManager(_manager);
      await tts.initialize(
        intraOpNumThreads: 2,
        onProgress: (p, msg) {
          if (mounted) setState(() => _progress = p);
        },
      );
      _log('initialize() DONE in ${sw.elapsedMilliseconds}ms');
      _engine = tts;
      _installed = true;
      setState(() => _status = 'Model ready — pick options and Speak.');
    } catch (e, st) {
      _log('✗ _ensureLoaded ERROR after ${sw.elapsedMilliseconds}ms: $e\n$st');
      setState(() => _status = '✗ $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _speak() async {
    if (_busy) return;
    if (_text.text.trim().isEmpty) {
      setState(() => _status = 'Type some text first.');
      return;
    }
    final gen = ++_speakGen;
    // Cut anything still sounding from the PREVIOUS utterance before we feed the
    // new one. NOTE: when the previous Speak's stream loop ended, only its
    // *synthesis* was done — its audio may still be PLAYING in the native
    // player. This flush is what's supposed to silence it; if you still hear the
    // old voice over the new one, the native flush is not cutting it. See the
    // `DNPcmStreamPlayer` flush/writer logs (Android) / schedule logs (iOS).
    _log('SPEAK gen=$gen START — flush() previous playback '
        '(prevGen audio may still be playing in the native player)');
    _player.flush();
    if (!_ready) {
      await _ensureLoaded();
      if (!_ready) return;
    }
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _status = 'Type some text first.');
      return;
    }
    setState(() {
      _speaking = true;
      _status = 'Synthesising "$_voice" ($_lang)…';
    });
    try {
      final tts = _engine!;
      _log(
        'SPEAK gen=$gen generateStream(${text.length} chars, voice=$_voice, '
        'lang=$_lang, speed=$_speed, steps=$_steps)…',
      );
      final sw = Stopwatch()..start();
      var chunks = 0;
      var totalSamples = 0;
      int? firstAudioMs;

      // Stream chunks: start playing chunk 0 the instant it's ready, then feed
      // the rest as they synthesize → first-audio is fast and independent of
      // total text length.
      await for (final Float32List audio in tts.generateStream(
        text,
        voice: _voice,
        lang: _lang,
        speed: _speed,
        steps: _steps,
      )) {
        // OVERLAP DETECTOR: if a newer Speak has begun, every chunk we feed from
        // here is the OLD utterance bleeding over the new one. With the current
        // _busy gate this should never fire — if it does in the logs, two
        // generations are feeding the player concurrently.
        if (gen != _speakGen) {
          _log('⚠️ OVERLAP gen=$gen superseded by gen=$_speakGen — '
              'this chunk (#$chunks) would play OVER the new utterance; '
              'still feeding it (no guard) so the bug is audible');
        }
        if (audio.isEmpty) continue;
        if (!_playerConfigured) {
          _player.configure(
            sampleRate: tts.sampleRate, // 44 100
            channels: 1,
            bitsPerSample: 16,
          );
          _playerConfigured = true;
          _log('SPEAK gen=$gen player.configure(sr=${tts.sampleRate}, ch=1, '
              'bits=16)');
        }
        if (chunks == 0) {
          firstAudioMs = sw.elapsedMilliseconds;
          final dur = (audio.length / tts.sampleRate).toStringAsFixed(2);
          _log(
              '🔊 FIRST CHUNK speaking now — gen=$gen, after ${firstAudioMs}ms '
              'of silence (chunk 0 = ${dur}s audio). '
              '⟵ time-to-first-audio (want this small & independent of text length)');
          _logAudioStats(audio);
        } else {
          // Short gap between chunks (each is trimmed to its exact duration, so
          // without this they'd butt together).
          final gap = _silencePcm(0.12, tts.sampleRate);
          _player.feedChunk(gap);
          totalSamples += gap.length ~/ 2;
          _vlog('SPEAK gen=$gen feed chunk $chunks '
              '(${audio.length} samples / '
              '${(audio.length / tts.sampleRate).toStringAsFixed(2)}s) '
              'at +${sw.elapsedMilliseconds}ms');
        }
        _player.feedChunk(_float32ToPcm16(audio));
        totalSamples += audio.length;
        chunks++;
        if (mounted) {
          setState(
            () => _status =
                '▶︎ playing… chunk $chunks · first audio $firstAudioMs ms',
          );
        }
      }
      sw.stop();
      if (chunks == 0) {
        _log('SPEAK gen=$gen produced 0 chunks');
        setState(() => _status = '⚠️ Generated 0 samples.');
        return;
      }
      final secs = totalSamples / tts.sampleRate;
      _log(
        'SPEAK gen=$gen SYNTH DONE: $chunks chunks, ${secs.toStringAsFixed(1)}s '
        'of audio, first audio ${firstAudioMs}ms, total synth '
        '${sw.elapsedMilliseconds}ms. NOTE: button re-enables now, but this '
        'audio is still PLAYING — a new tap must flush it to avoid overlap.',
      );
      setState(() {
        _status = '▶︎ $_voice · $_lang · ${secs.toStringAsFixed(1)}s · '
            '$chunks chunks · first audio $firstAudioMs ms';
      });
    } catch (e, st) {
      _log('✗ SPEAK gen=$gen ERROR: $e\n$st');
      setState(() => _status = '✗ $e');
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  /// Confirms the destructive delete with a native alert first — the chip is
  /// easy to tap by accident, and re-downloading the model is a ~144 MB hit.
  Future<void> _confirmAndDeleteModel() async {
    if (_busy) return;
    final choice = await showAlert(
      context: context,
      title: 'Delete model?',
      message: 'This removes the downloaded model from this device. You will '
          'need to download it again (~${_manager.downloadSizeMB()} MB) to use TTS.',
      actions: const ['Cancel', 'Delete'],
    );
    if (choice != 1) return; // 0 = Cancel (iOS default action)
    await _deleteModel();
  }

  Future<void> _deleteModel() async {
    if (_busy) return;
    final engine = _engine;
    _engine = null;
    await engine?.dispose();
    if (!mounted) return;
    _player.flush();
    try {
      _manager.delete();
      setState(() {
        _installed = false;
        _status = 'Deleted — tap Download to fetch it again.';
      });
    } catch (e) {
      setState(() => _status = '✗ delete failed: $e');
    }
  }

  /// Fills the text field with the built-in sample for the current language.
  void _useSample() {
    _text.text = TTSTestStrings.shortForLanguage(_lang);
    setState(() {});
  }

  /// Opens the full-screen language picker and applies the choice. The picker
  /// pops with the chosen `code`, or `null` if the user backs out (→ no change).
  Future<void> _pickLanguage() async {
    if (_busy) return;
    final code = await Navigator.push<String>(
      context,
      PageRoute(builder: (_) => LanguagePickerScreen(selectedCode: _lang)),
    );
    if (!mounted) return;
    if (code != null && code != _lang) setState(() => _lang = code);
  }

  void _logAudioStats(Float32List a) {
    if (!verboseLogs) return;
    if (a.isEmpty) {
      _vlog('  AUDIO STATS: EMPTY');
      return;
    }
    double mn = a[0], mx = a[0], sumAbs = 0;
    var nonZero = 0;
    for (final v in a) {
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      final ab = v.abs();
      sumAbs += ab;
      if (ab > 1e-4) nonZero++;
    }
    _vlog(
      '  AUDIO STATS: min=${mn.toStringAsFixed(4)} max=${mx.toStringAsFixed(4)} '
      'meanAbs=${(sumAbs / a.length).toStringAsFixed(5)} nonZero=$nonZero/${a.length} '
      '${nonZero == 0 ? "→ SILENT (inference/extraction bug)" : "→ HAS SIGNAL"}',
    );
  }

  /// Zero-filled 16-bit PCM of [seconds] duration — a silent gap between chunks.
  Uint8List _silencePcm(double seconds, int sampleRate) =>
      Uint8List((seconds * sampleRate).floor() * 2);

  /// Float32 (-1..1) → little-endian 16-bit PCM.
  Uint8List _float32ToPcm16(Float32List s) {
    final out = Uint8List(s.length * 2);
    final view = ByteData.view(out.buffer);
    for (var i = 0; i < s.length; i++) {
      final v = s[i] < -1 ? -1.0 : (s[i] > 1 ? 1.0 : s[i]);
      view.setInt16(i * 2, (v * 32767).round(), Endian.little);
    }
    return out;
  }

  @override
  void dispose() {
    _engine?.dispose();
    _player.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'SuperTonic TTS',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20,
              isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 20, 20, 20),
          children: [
            // ── Text ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _Label('Text'),
                GestureDetector(
                  onTap: _useSample,
                  child: const Text(
                    'Use sample',
                    style: TextStyle(color: Color(0xFF0A84FF), fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: kTileBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _text,
                minLines: 5,
                maxLines: 5,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: Platform.isAndroid ? 16 : 17,
                  // A bit roomier than the 1.25 default to exercise the new
                  // TextStyle.height wiring (rows resize to match).
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Type something to speak…',
                  hintStyle: TextStyle(color: kTextSecondary),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Language ── tap to open the full 31-language picker.
            const _Label('Language'),
            const SizedBox(height: 8),
            _DisclosureRow(
              value: TTSLanguage.fromCode(_lang).nativeName,
              enabled: !_busy,
              onTap: _pickLanguage,
            ),
            const SizedBox(height: 22),

            // ── Voice ──
            const _Label('Voice'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final v in supertonicVoices)
                  _Chip(
                    label: v,
                    selected: v == _voice,
                    enabled: !_busy,
                    onTap: () => setState(() => _voice = v),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Quality (denoising steps: 2–16, preset 8 = medium) ──
            _Label(
              'Quality  ·  $_steps steps${_steps == 8 ? '  (medium)' : ''}',
            ),
            const SizedBox(height: 8),
            Slider(
              value: _steps.toDouble(),
              min: 2,
              max: 16,
              activeColor: const Color(0xFF0A84FF),
              inactiveColor: kTileBg,
              onChanged:
                  _busy ? null : (v) => setState(() => _steps = v.round()),
            ),
            const SizedBox(height: 22),

            // ── Speed ──
            _Label('Speed  ·  ${_speed.toStringAsFixed(2)}×'),
            const SizedBox(height: 8),
            Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              activeColor: const Color(0xFF0A84FF),
              inactiveColor: kTileBg,
              onChanged: _busy
                  ? null
                  : (v) =>
                      setState(() => _speed = (v * 20).roundToDouble() / 20),
            ),
            const SizedBox(height: 26),

            // ── Action ──
            _Chip(
              label: _actionLabel,
              selected: true,
              enabled: !_busy,
              fullWidth: true,
              accent: _installed
                  ? const Color(0xFF34C759) // green = Speak
                  : const Color(0xFF0A84FF), // blue = Download
              onTap: _onAction,
            ),
            if (!_loading) ...[
              const SizedBox(height: 16),
              Text(
                _status,
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
            ],
            if (_installed && !_busy) ...[
              const SizedBox(height: 16),
              _Chip(
                label: 'Delete model from device',
                selected: false,
                enabled: !_busy,
                fullWidth: true,
                accent: const Color(0xFFFF3B30),
                onTap: _confirmAndDeleteModel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: kTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}

/// A settings-style disclosure row — the current [value] on the left and a "›"
/// chevron on the right — that opens a sub-screen when tapped. Styled like
/// [_Chip] so it sits naturally among the other controls.
class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        decoration: BoxDecoration(
          color: kRowBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kChipBg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: enabled ? kTextPrimary : kTextSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '›',
              style: TextStyle(color: kTextSecondary, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.fullWidth = false,
    this.accent = const Color(0xFF0A84FF),
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool fullWidth;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = !enabled
        ? kTileBg
        : selected
            ? accent
            : kRowBg;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : kChipBg,
          ),
        ),
        child: Center(
          widthFactor: fullWidth ? null : 1,
          child: Text(
            label,
            style: TextStyle(
              // White on the accent fill; themed on plain/disabled tiles.
              color: selected
                  ? const Color(0xFFFFFFFF)
                  : enabled
                      ? kTextPrimary
                      : kTextTertiary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
