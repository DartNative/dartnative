# dartnative_audio

> Play, stream, and record audio on native iOS & Android engines.

Real native audio for DartNative. Play sounds, stream PCM in real time, and record
the mic — all on the platform's own audio engines (AVFoundation on iOS,
media3 / AudioTrack / AudioRecord on Android). Write it once; it runs on both.

## Why you'll like it

- **One API, both platforms** — no per-platform branching, no channel boilerplate.
- **Low-latency by design** — direct to the platform's native audio engines.
- **Four focused tools** — playback, streaming, recording, session control. Reach for one or all.

## Highlights

- **AudioPlayer** — files & bundled assets (MP3, WAV, AAC); volume, looping, seek, and a position stream.
- **PcmStreamPlayer** — feed raw PCM chunks for buttery low-latency streaming (great for TTS).
- **AudioRecorder** — capture the mic to WAV with a live amplitude stream for waveforms.
- **AudioSession** — take control of the `AVAudioSession` category / mode when you need it.

## Install

```yaml
dependencies:
  dartnative_audio: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get   # fetches the binary and regenerates the plugin registrant
```

One call in `main()` wires up every DartNative plugin (iOS + Android):

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_audio/dartnative_audio.dart';
```

Play an asset or file:

```dart
final player = AudioPlayer()
  ..setAsset('assets/beep.mp3')
  ..setVolume(0.8)
  ..play();

player.events.listen((e) => print(e.type)); // started, completed, …
```

Drive a progress bar and scrub:

```dart
player.positionStream.listen((pos) {
  setState(() => _progress = pos.inMilliseconds / player.durationMs);
});

player.seek(const Duration(seconds: 30)); // jump
player.isPlaying;                         // real native play state
```

Stream raw PCM (e.g. TTS output):

```dart
final pcm = PcmStreamPlayer()..configure(sampleRate: 22050, channels: 1);
pcm.feedChunk(bytes); // feed chunks as they arrive
pcm.flush();          // between utterances
```

Record the microphone to a WAV file:

```dart
final rec = AudioRecorder();
rec.amplitudeStream.listen(updateWaveform); // live level for a waveform UI
rec.start('/tmp/clip.wav');
// …later…
final path = rec.stop();
```

Control the audio session:

```dart
AudioSession.setCategory(
  AudioSessionCategory.playAndRecord,
  mode: AudioSessionMode.spokenAudio,
);
```

## Platform setup

### iOS (13+)

Recording needs a microphone usage string in `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We use the microphone to record audio.</string>
```

Playback-only apps need nothing here.

### Android (minSdk 24)

The plugin already declares `RECORD_AUDIO` (and `INTERNET`, which media3 wants for network
playback), so there's nothing to add to your manifest. For recording you still must request the
**runtime** `RECORD_AUDIO` permission before calling `AudioRecorder.start()` (Android 6+). Playback
needs nothing.

## Example

Want to see it all working? The [`example/`](./example) app plays, streams, and
records — borrow from it freely.

## Credits & license

Independent DartNative implementation — inspired by
[just_audio](https://github.com/ryanheise/just_audio),
[flutter_sound](https://github.com/Canardoux/flutter_sound), and
[audio_session](https://github.com/ryanheise/audio_session).

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues
on the plugin's page.
