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

import '../demo_script.dart';
import 'language_picker_screen.dart';

/// Turns on the high-volume diagnostics: the demo's per-utterance chatter (the
/// chunk PLAN, one line per buffer fed, per-chunk PCM stats, screen-push
/// markers) AND the engine's own ([SuperTonicTTS.verboseLogging], applied in
/// `initState` — token counts, predicted durations, vocoder/trim sizes).
///
/// Off by default: a healthy utterance should be a couple of lines, not twenty.
/// Flip it (or wire it to `kDebugMode`) when chasing a streaming or buffering
/// problem — see doc/audio-noise-investigation notes.
///
/// **Defect signals ignore this flag and are always printed**: underruns,
/// old-over-new overlap, an empty or missing chunk, a plan/stream count
/// mismatch, and teardown. Losing audio is a bug, not chatter.
bool verboseLogs = false;

/// Always-on, wall-clock-stamped logger — shows as `[SuperTonicDemo …]` in
/// `dn run`. Timestamped so demo logs can be correlated with the native
/// `[DNPcmStreamPlayer]` lines, which is how a Dart-side feed is matched to the
/// buffer the player actually scheduled (or dropped).
void _log(String m) => print('[SuperTonicDemo ${_now()}] $m');

/// High-volume diagnostics: only printed when [verboseLogs] is on.
void _vlog(String m) {
  if (verboseLogs) print('[SuperTonicDemo ${_now()}] $m');
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
  /// Seeded from [DemoScript] in [initState] so it follows [_lang]'s default,
  /// and re-seeded by [_pickLanguage] whenever the language changes while the
  /// script is still untouched — so picking a language tests the SAME sentences
  /// in it. Four paragraphs, so the chunk-by-chunk streaming path is exercised.
  final _text = TextEditingController();
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
  int _steps = 10; // denoising steps / quality (2–16; 10 = default)
  double _speed = 1.0;
  bool _loading = false;
  bool _speaking = false;
  double _progress = 0;
  String _status = 'Loading…';

  // Monotonic id for each Speak invocation. Threaded into every log line so the
  // streaming/overlap behaviour can be traced: if a chunk is fed while a NEWER
  // gen is active, the old utterance is bleeding over the new one.
  int _speakGen = 0;

  // ── Feed ledger ─────────────────────────────────────────────────────────
  // Records every buffer Dart hands to the native player, so "which chunk went
  // missing?" is answered from the log instead of by ear: the ledger proves what
  // was FED, the ear reports what was HEARD, and a chunk present in one but not
  // the other was lost below Dart. That is exactly how the dropped-sentence bug
  // was pinned on DNPcmStreamPlayer, which held overflow in a single slot and
  // overwrote it (iOS) / dropped its oldest queue entry (Android). Both now
  // queue instead, so this is a regression guard rather than a live hunt.
  // Reset per Speak.
  int _feedSeq = 0; // monotonic buffer count within this utterance
  double _fedSeconds = 0; // audio seconds handed to the player so far
  Stopwatch? _playClock; // wall-clock since the FIRST feed ≈ the playback head

  /// Set by [_stop]; the stream loop breaks on it. Breaking out of an
  /// `await for` cancels the underlying `async*`, so the chunks not yet
  /// synthesised are never computed — Stop cuts the CPU load, it does not just
  /// mute what is already queued.
  bool _stopRequested = false;

  /// True from the first buffer fed until the audio is expected to have
  /// finished, so the button can offer Stop for as long as sound may still be
  /// coming out. The player gives no completion callback, so this is driven by
  /// [_playbackEndTimer] off the fed-vs-elapsed arithmetic the ledger already
  /// tracks.
  bool _playing = false;
  Timer? _playbackEndTimer;

  bool get _busy => _loading || _speaking;
  bool get _ready => _engine?.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    // Verbose engine logs follow the demo's switch (per-chunk synth/RTF lines).
    SuperTonicTTS.verboseLogging = verboseLogs;
    _text.text = DemoScript.forLanguage(_lang);
    // Make the Android system navigation bar + its divider transparent so the
    // app draws edge-to-edge; keep the dark status bar.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Color(0xFF1C1C1E),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0x00000000), // transparent
        systemNavigationBarDividerColor: Color(0x00000000), // transparent
      ),
    );
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
    _log(
      'TAP action: busy=$_busy installed=$_installed ready=$_ready '
      'loading=$_loading speaking=$_speaking',
    );
    if (_speaking || _playing) {
      _stop();
      return;
    }
    if (_loading) {
      _log('TAP ignored — a download/load is still in flight');
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
    // _playClock starts on the FIRST feed and is reset per Speak, so it is
    // exactly "audio for this utterance has reached the player". Until then the
    // listener hears silence and 'Synthesising…' is the honest label; after it,
    // later chunks are still being synthesised but the thing the user cares
    // about — sound — has started, and the status line below already says so.
    // Anything in flight — synthesising, or audio still on its way out — the
    // button's job is to stop it. The status line below carries the detail.
    if (_speaking || _playing) return 'Stop';
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
    // Flush the player so the previous utterance stops before the new one
    // is fed — when the previous Speak's stream loop ended, only its
    // synthesis was done; its audio may still be playing. See the
    // `DNPcmStreamPlayer` flush/writer logs (Android) / schedule logs (iOS).
    _log(
      'SPEAK gen=$gen START — flush() previous playback '
      '(prevGen audio may still be playing in the native player)',
    );
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
    // Fresh ledger for this utterance.
    _stopRequested = false;
    _playing = false;
    _playbackEndTimer?.cancel();
    _feedSeq = 0;
    _fedSeconds = 0;
    _playClock = null;
    try {
      final tts = _engine!;
      _log(
        'SPEAK gen=$gen generateStream(${text.length} chars, voice=$_voice, '
        'lang=$_lang, speed=$_speed, steps=$_steps)…',
      );

      // Ask the engine how it WILL split the text before synthesising anything.
      // Same splitter generateStream uses, so the indices line up — every log
      // line below can then name the chunk it belongs to, and a chunk that is
      // never audible can be identified by its text rather than guessed at.
      final planned = tts.splitText(text, maxLen: _lang == 'ko' ? 120 : 300);
      _vlog(
        'SPEAK gen=$gen PLAN: ${planned.length} chunk(s) — all of these must '
        'be heard, in this order:',
      );
      for (var i = 0; i < planned.length; i++) {
        _vlog(
          '    plan chunk[$i] (${planned[i].length} chars): "${planned[i]}"',
        );
      }

      // The engine logs the model input itself. Don't call Tokenizer here:
      // `dn run` resolves this plugin to the SDK header package, which lags
      // local source, so new API passes dart analyze but fails the build.

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
        // Breaking here cancels the async* generator, so the chunks after this
        // one are never synthesised at all.
        if (_stopRequested) {
          _log('SPEAK gen=$gen CANCELLED after $chunks chunk(s) — remaining '
              'chunks will not be synthesised');
          break;
        }
        final idx = chunks;
        final label = idx < planned.length
            ? 'chunk[$idx] "${_short(planned[idx])}"'
            : 'chunk[$idx] (UNPLANNED — more chunks than splitText predicted!)';
        // Stop feeding chunks if a newer Speak has started — anything fed
        // from here would be the old utterance bleeding over the new one.
        if (gen != _speakGen) {
          _log(
            '⚠️ OVERLAP gen=$gen superseded by gen=$_speakGen — '
            'this chunk (#$chunks) would play OVER the new utterance; '
            'still feeding it (no guard) so the bug is audible',
          );
        }
        if (audio.isEmpty) {
          _log(
            '⚠️ SPEAK gen=$gen $label yielded EMPTY audio — nothing to '
            'feed; this chunk is silently missing from playback',
          );
          chunks++;
          continue;
        }
        if (!_playerConfigured) {
          _player.configure(
            sampleRate: tts.sampleRate, // 44 100
            channels: 1,
            bitsPerSample: 16,
          );
          _playerConfigured = true;
          _vlog(
            'SPEAK gen=$gen player.configure(sr=${tts.sampleRate}, ch=1, '
            'bits=16)',
          );
        }
        // ── Critical path: hand the PCM over before doing ANYTHING else. ──
        // ONE buffer per chunk. Each chunk is trimmed to its exact duration, so
        // a short silence is needed between them — but it is PREPENDED into the
        // chunk's own buffer rather than fed separately. Two feeds per chunk
        // doubled the buffer count (2N-1 for N chunks) for no benefit: the
        // player schedules per feed, so fewer/larger buffers is strictly better.
        final lead = chunks == 0 ? 0.0 : 0.12;
        _feed(
          gen,
          label,
          _float32ToPcm16(audio, leadSilence: lead, sampleRate: tts.sampleRate),
          tts.sampleRate,
        );
        totalSamples += audio.length + (lead * tts.sampleRate).floor();

        // Everything below is diagnostics, deliberately AFTER the feed: the
        // whole point of chunked streaming is time-to-first-audio, and logging
        // ahead of the handoff spends that budget on the log.
        if (chunks == 0) {
          firstAudioMs = sw.elapsedMilliseconds;
          final dur = (audio.length / tts.sampleRate).toStringAsFixed(2);
          _log(
            '🔊 FIRST CHUNK speaking now — gen=$gen, after ${firstAudioMs}ms '
            'of silence (chunk 0 = ${dur}s audio). '
            '⟵ time-to-first-audio, measured at the handoff to the player '
            '(want this small & independent of text length)',
          );
        }
        _logAudioStats(label, audio);
        chunks++;
        if (mounted) {
          setState(
            () => _status =
                '▶︎ playing… chunk $chunks · first audio $firstAudioMs ms',
          );
        }
      }
      sw.stop();
      if (_stopRequested) return;
      if (chunks == 0) {
        _log('SPEAK gen=$gen produced 0 chunks');
        setState(() => _status = '⚠️ Generated 0 samples.');
        return;
      }
      if (chunks != planned.length) {
        _log(
          '⚠️ SPEAK gen=$gen COUNT MISMATCH: splitText planned '
          '${planned.length} chunk(s) but generateStream yielded $chunks — '
          'the loss is INSIDE the engine, not the player.',
        );
      }
      final secs = totalSamples / tts.sampleRate;
      _log(
        'SPEAK gen=$gen SYNTH DONE: $chunks chunks, ${secs.toStringAsFixed(1)}s '
        'of audio, first audio ${firstAudioMs}ms, total synth '
        '${sw.elapsedMilliseconds}ms. NOTE: button re-enables now, but this '
        'audio is still PLAYING — a new tap must flush it to avoid overlap.',
      );
      // Synthesis is done but the player still holds `_fedSeconds` of audio.
      // Keep offering Stop until it has drained; there is no completion
      // callback, so this uses the fed-vs-elapsed arithmetic the ledger tracks.
      final remaining =
          _fedSeconds - (_playClock?.elapsedMilliseconds ?? 0) / 1000.0;
      if (remaining > 0) {
        _playbackEndTimer?.cancel();
        _playbackEndTimer = Timer(
          Duration(milliseconds: (remaining * 1000).round()),
          () {
            if (mounted) setState(() => _playing = false);
          },
        );
      }

      _vlog(
        'SPEAK gen=$gen FEED LEDGER: $_feedSeq buffer(s) fed to the native '
        'player = ${_fedSeconds.toStringAsFixed(2)}s of audio, all intact on '
        'the Dart side. If a sentence was not HEARD, the loss is below this '
        'point — check the [DNPcmStreamPlayer] lines.',
      );
      setState(() {
        _status =
            '▶︎ $_voice · $_lang · ${secs.toStringAsFixed(1)}s · '
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
      message:
          'This removes the downloaded model from this device. You will '
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

  /// Stops synthesis and playback at once.
  ///
  /// This exists because SYNTH DONE arrives while ~20 s of audio is still
  /// playing: without it the only way to cut an utterance short was to tap
  /// Speak again, and re-triggering synthesis a few hundred ms after the last
  /// one finished measurably throttles the device — captured runs show ~2x
  /// slower synthesis for a re-tap under 2 s, recovering after ~5 s idle.
  void _stop() {
    _log('STOP — flush player, cancel stream '
        '(fed=${_fedSeconds.toStringAsFixed(2)}s, '
        'played≈${((_playClock?.elapsedMilliseconds ?? 0) / 1000).toStringAsFixed(2)}s)');
    _stopRequested = true;
    _playbackEndTimer?.cancel();
    _player.flush();
    setState(() {
      _playing = false;
      _playClock = null;
      _status = 'Stopped.';
    });
  }

  /// Restores the demo script for the currently selected language.
  void _useSample() {
    _text.text = DemoScript.forLanguage(_lang);
    setState(() {});
  }

  /// Opens the full-screen language picker and applies the choice. The picker
  /// pops with the chosen `code`, or `null` if the user backs out (→ no change).
  Future<void> _pickLanguage() async {
    // Deliberately NOT gated on _busy — see the _DisclosureRow comment. The
    // in-flight utterance keeps its own `text` and `lang` locals, so switching
    // here cannot affect what is currently being spoken.
    // Bracket the push: audio glitches during this transition need the native
    // [DNPcmStreamPlayer] lines pinned to the exact moment the screen opens.
    // If a ⚠️ CONFIGURATION CHANGED / INTERRUPTION / ROUTE CHANGED lands between
    // these two, the system moved the audio out from under a playing utterance.
    // If none does but the audio still glitches, nothing reconfigured it and the
    // cause is CPU contention during the transition.
    _vlog('NAV ▶ pushing language picker '
        '(fed=${_fedSeconds.toStringAsFixed(2)}s, '
        'played≈${((_playClock?.elapsedMilliseconds ?? 0) / 1000).toStringAsFixed(2)}s '
        '→ ${_playClock == null ? "nothing playing" : "AUDIO IS PLAYING"})');
    final code = await Navigator.push<String>(
      context,
      PageRoute(builder: (_) => LanguagePickerScreen(selectedCode: _lang)),
    );
    _vlog('NAV ◀ language picker popped (code=$code)');
    if (code == null || code == _lang) return;
    // Follow the language with its translation, so picking one immediately
    // speaks the SAME script in it. Only while the field still holds a built-in
    // script, though: typing over it makes the text the user's, and switching
    // language must not throw that away.
    if (DemoScript.isScript(_text.text)) {
      _text.text = DemoScript.forLanguage(code);
    }
    setState(() => _lang = code);
  }

  /// Hands [bytes] (16-bit mono PCM) to the native player and records the feed.
  ///
  /// [what] labels the buffer ("chunk[2] …"). The interesting number is
  /// **lead** = audio seconds fed MINUS wall-clock seconds since the first feed,
  /// i.e. roughly how much audio is queued ahead of the playback head.
  ///
  /// `lead ≤ 0` means the player ran dry before this buffer arrived: synthesis
  /// lost the race with playback and the listener heard a stutter. That is the
  /// number the chunk ramp in `_chunkText` is tuned to keep positive — a small
  /// first chunk to start fast, then growing chunks so the lead builds.
  ///
  /// A large lead is fine, and expected: it just means synthesis is comfortably
  /// ahead. The native player queues the surplus in order.
  ///
  /// Always-on: a lost or stuttered sentence is a defect, not routine chatter.
  void _feed(int gen, String what, Uint8List bytes, int sampleRate) {
    if (bytes.isEmpty) return;
    final secs = bytes.length / 2 / sampleRate; // 16-bit mono → 2 B per sample
    // The clock starts ON the first feed, so for that buffer played and fed are
    // both 0 and `lead` is 0 — which is not an underrun, it is the moment sound
    // begins. Only a LATER buffer arriving at lead <= 0 means the player drained.
    final firstBuffer = _playClock == null;
    _playClock ??= Stopwatch()..start();
    final played = _playClock!.elapsedMilliseconds / 1000.0;
    final lead = _fedSeconds - played;
    _feedSeq++;
    _playing = true;
    _player.feedChunk(bytes);
    _fedSeconds += secs;
    final line =
        '  FEED#$_feedSeq gen=$gen $what — ${bytes.length}B / '
        '${secs.toStringAsFixed(2)}s  '
        '[fed=${_fedSeconds.toStringAsFixed(2)}s '
        'played≈${played.toStringAsFixed(2)}s '
        'lead=${lead.toStringAsFixed(2)}s]';
    // A healthy feed is chatter; an underrun is a defect, so it carries the same
    // line through unconditionally rather than being lost with the rest.
    if (!firstBuffer && lead <= 0) {
      _log('$line  ⚠️ UNDERRUN — player ran dry before this buffer');
    } else {
      _vlog(line);
    }
  }

  /// First 40 chars of [s] on one line — enough to recognise a chunk in a log.
  static String _short(String s) =>
      s.length <= 40 ? s : '${s.substring(0, 40)}…';

  /// Per-chunk PCM sanity check: separates "the engine produced silence/garbage
  /// for this chunk" (a TTS problem) from "the engine produced good audio that
  /// never played" (a player problem). Compare `meanAbs` across chunks — an
  /// outlier is the bad one.
  ///
  /// **Sampled, not exhaustive.** A chunk is ~250 000 floats and this runs on
  /// the synthesis isolate; a full scan measured ~350–430 ms per chunk, which
  /// is a large fraction of the time-to-first-audio the chunking exists to
  /// minimise. Striding to [_statsBudget] samples answers the only question
  /// asked here — silent vs. has signal — for well under a millisecond.
  static const int _statsBudget = 8192;

  void _logAudioStats(String label, Float32List a) {
    if (a.isEmpty) {
      _log('  AUDIO STATS $label: EMPTY');
      return;
    }
    final stride = a.length <= _statsBudget ? 1 : a.length ~/ _statsBudget;
    double mn = a[0], mx = a[0], sumAbs = 0;
    var seen = 0, nonZero = 0;
    for (var i = 0; i < a.length; i += stride) {
      final v = a[i];
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      final ab = v.abs();
      sumAbs += ab;
      if (ab > 1e-4) nonZero++;
      seen++;
    }
    final line =
        '  AUDIO STATS $label: min=${mn.toStringAsFixed(4)} max=${mx.toStringAsFixed(4)} '
        'meanAbs=${(sumAbs / seen).toStringAsFixed(5)} '
        'nonZero≈${(nonZero * 100 / seen).round()}% '
        '($seen of ${a.length} sampled, stride $stride)';
    // Signal present is chatter; a wholly silent chunk means the pipeline
    // produced nothing for real text, which is always worth surfacing.
    if (nonZero == 0) {
      _log('$line → SILENT (inference/extraction bug)');
    } else {
      _vlog('$line → HAS SIGNAL');
    }
  }

  /// Float32 (-1..1) → little-endian 16-bit PCM, optionally preceded by
  /// [leadSilence] seconds of silence in the SAME buffer (the gap between
  /// chunks). A fresh `Uint8List` is zero-filled, so the lead-in needs no work
  /// beyond the offset.
  Uint8List _float32ToPcm16(
    Float32List s, {
    double leadSilence = 0,
    int sampleRate = 44100,
  }) {
    final lead = (leadSilence * sampleRate).floor();
    final out = Uint8List((lead + s.length) * 2);
    final view = ByteData.view(out.buffer);
    for (var i = 0; i < s.length; i++) {
      final v = s[i] < -1 ? -1.0 : (s[i] > 1 ? 1.0 : s[i]);
      view.setInt16((lead + i) * 2, (v * 32767).round(), Endian.little);
    }
    return out;
  }

  @override
  void dispose() {
    // Always-on: if this fires while opening another screen, the demo's State
    // was torn down by the navigation and _player.dispose() below kills the
    // AVAudioEngine mid-utterance — which would explain a glitch on push all by
    // itself. Pair it with "[DNPcmStreamPlayer] dispose() — engine torn down".
    _playbackEndTimer?.cancel();
    _log('DISPOSE demo screen — engine + player are being torn down NOW');
    _engine?.dispose();
    _player.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: const Color(0xFF000000),
      // This screen is dark by design (black ground, dark chips) regardless of
      // the system theme. Pinning the interface style is what makes the iOS
      // surfaces the app doesn't paint itself follow suit — above all the
      // KEYBOARD, which otherwise comes up light over a black screen. (iOS
      // only: on Android night mode is app-global.)
      brightness: Brightness.dark,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'SuperTonic TTS',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _text,
              minLines: 5,
              maxLines: 5,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: Platform.isAndroid ? 16 : 17,
                // A bit roomier than the 1.25 default (rows resize to match).
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Type something to speak…',
                hintStyle: TextStyle(color: Color(0xFF8E8E93)),
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
            // Not gated on _busy: picking a language only affects the NEXT
            // Speak (this one already captured its text and lang), and being
            // locked out for the whole of synthesis + playback — 20 s or more
            // — just to change what you'll say next is the wrong trade.
            enabled: true,
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
            'Quality  ·  $_steps steps${_steps == 10 ? '  (default)' : ''}',
          ),
          const SizedBox(height: 8),
          Slider(
            value: _steps.toDouble(),
            min: 2,
            max: 16,
            activeColor: const Color(0xFF0A84FF),
            inactiveColor: const Color(0xFF2C2C2E),
            onChanged: _busy
                ? null
                : (v) => setState(() => _steps = v.round()),
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
            inactiveColor: const Color(0xFF2C2C2E),
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
            // Enabled during synthesis/playback on purpose: that is exactly
            // when it is a Stop button.
            enabled: !_loading,
            fullWidth: true,
            accent: _speaking || _playing
                ? const Color(0xFFFF3B30) // red = Stop
                : _installed
                    ? const Color(0xFF34C759) // green = Speak
                    : const Color(0xFF0A84FF), // blue = Download
            onTap: _onAction,
          ),
          if (!_loading) ...[
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(color: Color(0xFFEDEDED), fontSize: 14),
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
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: Color(0xFF8E8E93),
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
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: enabled
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF8E8E93),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              '›',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 20),
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
        ? const Color(0xFF2C2C2E)
        : selected
        ? accent
        : const Color(0xFF1C1C1E);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : const Color(0xFF3A3A3C),
          ),
        ),
        child: Center(
          widthFactor: fullWidth ? null : 1,
          child: Text(
            label,
            style: TextStyle(
              color: selected || !enabled
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFEDEDED),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
