# dartnative_supertonic_tts

> Multilingual, on-device neural text-to-speech (SuperTonic-3) for DartNative.

High-quality offline TTS in 31 languages and 10 voices. A pure-Dart, all-ONNX
4-model flow-matching pipeline runs on `dartnative_onnxruntime` — **no native
code of its own, no espeak/phonemizer** (the tokenizer is a pure-Dart codepoint
lookup). Output is PCM Float32 at 44.1 kHz, mono.

## Why you'll like it

- **Truly multilingual** — 31 languages incl. English, Italian, Spanish, French,
  Korean. Character-level, so no per-language phonemizer or data files.
- **Pure Dart, zero native glue** — the whole pipeline is Dart on top of
  `dartnative_onnxruntime`; nothing to build (no podspec / CMake / JNI).
- **Small, split download** — ~144 MB int8 model fetched on first use; bundle
  everything but the ~78 MB vector-estimator and the download halves.

## Highlights

- **SuperTonicTTS** — `initialize()` (downloads on first run) → `generateStream()` / `generate()` → `dispose()`.
- **`generateStream(text, …)`** — yields PCM **per chunk as it's synthesized** → fast, length-independent first-audio (recommended for playback).
- **`generate(text, {voice, lang, speed, steps})`** — collect-all convenience returning one `Float32List` @ 44.1 kHz.
- **10 voices** — `F1`–`F5` (female), `M1`–`M5` (male); see `TTSVoiceStyle`.
- **Quality knob** — `steps` (denoising steps, 2–16; 8 = medium) trades quality for speed.
- **Smart pronunciation** — auto-inserts lexical-stress accents for words a character-level model mis-stresses (e.g. Italian *sàbato*, *perdòno*); deterministic, no extra calls.
- **ModelManager** — download + cache + a `bundledDir` split so only the big model downloads.
- **TTSResult** — `toWavBytes()` for a 16-bit mono WAV when you need a file.

## Install

```yaml
dependencies:
  dartnative_supertonic_tts: ^1.0.0   # from dartpub.dev
  dartnative_onnxruntime: ^1.6.4  # runs the models (required)
  dartnative_path_provider: ^1.0.0 # model cache dir (required)
```

```bash
dn pub get   # fetches binaries and regenerates the plugin registrant
```

This package has no FFI symbols of its own, so the app loads ONNX Runtime once in
`main()` (the registrant does it for you):

```dart
void main() {
  DartNativePluginRegistrant.registerAll(); // calls OrtFFIBindings.loadSymbols()
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_supertonic_tts/dartnative_supertonic_tts.dart';
```

Initialize (downloads the model on first run) and synthesize:

```dart
final tts = SuperTonicTTS();                 // SuperTonicVariant.mobile (~144 MB)
await tts.initialize(
  intraOpNumThreads: 2,
  onProgress: (p, msg) => print('${(p * 100).toStringAsFixed(0)}% — $msg'),
);

final audio = await tts.generate(
  'Ciao, come stai?',
  voice: 'F1',   // F1–F5, M1–M5
  lang: 'it',    // en, ko, es, pt, fr, it, … (any SuperTonic-3 code)
  speed: 1.0,    // 0.5–2.0 (higher = faster)
  steps: 8,      // denoising steps / quality (2–16)
);
```

Play it with `dartnative_audio` (44.1 kHz PCM):

```dart
final pcm = PcmStreamPlayer()..configure(sampleRate: tts.sampleRate, channels: 1);
pcm.feedChunk(float32ToPcm16(audio)); // your Float32 → Int16 LE conversion
```

Or export a WAV file:

```dart
final wav = TTSResult(
  audioData: Float64List.fromList([for (final s in audio) s.toDouble()]),
  sampleRate: tts.sampleRate,
  duration: audio.length / tts.sampleRate,
).toWavBytes();
```

To cut the first-run download roughly in half, **bundle everything but the
vector-estimator** in your app — see [Reduce the first-run download](#reduce-the-first-run-download).

## Custom voice

Beyond the 10 built-in voices, you can speak with **your own voice** by passing
`voiceStylePath` — an absolute path to a SuperTonic **voice-style JSON** (the same
shape as the built-in `voice_styles/*.json`: a `style_ttl` and a `style_dp`
tensor). When set, it overrides `voice` and the style is read from that file.

```dart
// `customVoicePath` = wherever your voice-style JSON lives on disk
// (e.g. a file you ship as an asset and resolve at runtime).
final audio = await tts.generate(
  'Ciao, come stai?',
  lang: 'it',
  voiceStylePath: customVoicePath, // ← use a custom voice instead of `voice:`
);
```

`generateStream(...)` and `generateChunk(...)` take the same `voiceStylePath`.
There's no `rootBundle` in dartnative, so resolve a bundled asset from
`Platform.resolvedExecutable`'s parent + `flutter_assets/<your-asset-path>` (see
[Reduce the first-run download](#reduce-the-first-run-download) for the same
pattern).

## Pronunciation & stress accents

SuperTonic-3 is **character-level** — it has no pronunciation dictionary and infers
word stress, defaulting to penultimate. That's right for most words but wrong for
**antepenultimate "sdrucciole"** (Italian `sabato` → *sà·ba·to*) and **stress
homographs** (`perdono` = *forgiveness* per‑**dò**‑no, not *they lose* **pèr**‑do‑no).
You fix it by marking the stressed vowel — and the tokenizer does the rest:

1. **Write the accent yourself.** Put the accent on the stressed vowel
   (`perdòno`, `Vangèlo`). The tokenizer NFKD-decomposes it into the combining
   mark the model reads, so the stress lands. Works for any language.
2. **Built-in per-language correction.** A `word → accented-respelling` map runs
   automatically (whole-word, case-preserving) before synthesis, so you can feed
   **plain text** and the common exceptions are fixed for you:

```dart
// Plain input — the tokenizer inserts the stress accents itself:
await tts.generate('Questo sabato leggiamo il Vangelo.', lang: 'it');
// → spoken as  "Questo sábato leggiamo il Vangèlo."
```

**Italian, German, Dutch, Russian, Bulgarian, Ukrainian and Romanian** ship stress
dictionaries — Italian ~3.7k (the antepenultimate *sdrucciole* the model misses) plus
a small homograph override, the rest larger syllable-aligned maps. All are generated
offline from frequency lists + **espeak-ng**, keyed by `lang`. Because it's a
deterministic in-tokenizer step there are **no extra model/LLM calls and only one
text** — you display the original, the model hears the accented form. Spanish,
Portuguese, Greek and French already carry stress in their spelling (or have none),
so they need no map.

## Streaming for instant first-audio

`generate()` returns the clip only after the **entire** text is synthesized, so
the wait before the first sound grows with length. **`generateStream()` yields
each chunk's PCM the moment it's ready** — start playing chunk 0 while the rest
is still being generated, and the time-to-first-audio stays low and roughly
constant regardless of how long the text is.

```dart
final pcm = PcmStreamPlayer()
  ..configure(sampleRate: tts.sampleRate, channels: 1, bitsPerSample: 16);

await for (final Float32List chunk in tts.generateStream(
  longText,
  voice: 'M1',
  lang: 'en',
  steps: 8,        // quality (denoising steps)
  // maxLen: 200,  // smaller ⇒ faster first audio, more chunks
)) {
  pcm.feedChunk(float32ToPcm16(chunk)); // chunk 0 plays while the rest generate
}
```

How it works:

- The plugin splits text into sentence-aligned chunks (≤ `maxLen` chars) and
  synthesizes them in order, emitting each as soon as it finishes.
- Yielded chunks carry **no inter-chunk silence** — feed a short silence buffer
  between them if you want a pause (the player owns playback shaping).
- Very short chunks are auto-merged so a chunk's audio always outlasts the next
  chunk's synthesis, which avoids playback underruns (stutter). On slow devices
  with high `steps`, synthesis can still fall behind real time — lower `steps`,
  or pre-buffer a chunk, if you hear gaps.
- `generate()` is simply `generateStream()` collected into one buffer — use it
  when you want a single clip (e.g. to cache a WAV) and don't need fast
  first-audio.

## Reduce the first-run download

The model is four files; the **vector_estimator is ~78 MB (54%)**, the rest ≈
66 MB. If you'd rather trade a bigger install for a smaller download, **bundle
everything except the vector-estimator** in your app and let `ModelManager` read
those in place — only the VE is fetched at runtime (~144 MB → ~78 MB).

`ModelManager(bundledDir:)` resolves each file as **cache → bundle → download**:
files found in `bundledDir` are used in place and never downloaded; missing ones
(the VE) are downloaded as usual.

```dart
final tts = SuperTonicTTS.withManager(ModelManager(bundledDir: bundledDir));
```

Steps:

1. **Ship the files as assets.** Place all files *except* `vector_estimator.onnx`
   under e.g. `assets/supertonic/` — `duration_predictor.onnx`,
   `text_encoder.onnx`, `vocoder.onnx`, `tts.json`, `unicode_indexer.json`, and
   `voice_styles/*.json` — and declare them in your app's `pubspec.yaml`
   `flutter: assets:`. (Fetch them at build time rather than committing ~66 MB to
   git.)
2. **Resolve `bundledDir`.** dartnative has no `rootBundle`, so locate the assets
   on disk from `Platform.resolvedExecutable`'s parent + `flutter_assets/…`. This
   resolves the same in any isolate (so a synthesis worker can use it too):

   ```dart
   String? bundledDir() {
     final exe = File(Platform.resolvedExecutable).parent.path;
     const rel = 'flutter_assets/assets/supertonic';
     for (final c in ['$exe/$rel', '$exe/Frameworks/App.framework/$rel']) {
       if (File('$c/tts.json').existsSync()) return c;
     }
     return null; // not bundled → everything downloads
   }
   ```
3. Pass it to every `ModelManager` you build (download path **and** the engine).

Notes:
- This **shifts** bytes from the runtime download to the app-store binary — the
  total a user fetches is about the same; pick based on whether a larger install
  or a larger first-run download is the better UX for you.
- If a bundled file isn't found at runtime (e.g. asset packaging differs on a
  platform), `ModelManager` simply downloads it — so this degrades safely.

## Platform setup

### iOS (16+)

No native setup. The models run via `dartnative_onnxruntime` (the
`onnxruntime-objc` pod), which links automatically.

### Android (minSdk 24)

No native setup. `dartnative_onnxruntime` bundles the ONNX Runtime AAR and loads
its JNI bridge at engine attach. The pipeline runs on the **CPU** execution
provider (NNAPI mis-partitions these int8 TTS graphs).

## Example

The [`example/`](./example) app is a full playground — text input, Language,
Voice, Quality and Speed pickers, Download/Speak, and playback via
`PcmStreamPlayer`. Run `./scripts/fetch_bundled_models.sh` first to bundle the
small files (download then drops to ~78 MB), then `dn run`.

## Credits & license

Adapted from [`supertonic_flutter`](https://github.com/YofarDev/supertonic_flutter)
(Apache-2.0) — reworked onto `dartnative_onnxruntime` with chunk streaming,
explicit tensor lifecycle, and on-demand model download. Model:
[SuperTonic](https://github.com/supertone-inc/supertonic) — code MIT, weights
OpenRAIL-M (redistributable; propagate the license). The int8 ONNX weights are
the repackage by [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)
(Apache-2.0) — [`sherpa-onnx-supertonic-3-tts-int8`](https://huggingface.co/csukuangfj2/sherpa-onnx-supertonic-3-tts-int8-2026-05-11);
JSON sidecars (tokenizer, voices) come from the official SuperTonic repo.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues
on the plugin's page.
