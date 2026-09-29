# dartnative_video_player

A high-performance video player for DartNative — backed by the platform's own engines
(AVPlayer on iOS, ExoPlayer on Android) with byte-limited pre-caching. iOS and Android.

## See it in action

<table>
  <tr>
    <td width="50%"><video src="https://github.com/user-attachments/assets/c3397c4f-7652-4725-91eb-38fa6960c567" controls><a href="https://github.com/user-attachments/assets/c3397c4f-7652-4725-91eb-38fa6960c567">Watch playback</a></video></td>
    <td width="50%"><video src="https://github.com/user-attachments/assets/33df8b52-28f1-4231-b080-8b8ec750bf82" controls><a href="https://github.com/user-attachments/assets/33df8b52-28f1-4231-b080-8b8ec750bf82">Watch pre-caching</a></video></td>
  </tr>
</table>

Left, playback: a clip with the built-in controls, scrubbing, and a
turn to full screen. Right, pre-caching: four clips pre-cached and
pre-warmed for instant playback, so each one starts the moment you
swipe to it.

This is the example app. Playback runs on the platform's own engine, so
it is smooth and easy on the battery, and you can keep the built-in
controls or draw your own over the video. The pre-cache screen shows the
other half: the next clips are pre-cached and pre-warmed, within a byte
budget you choose, so playback is instant when the user gets there.
The playback demo is in the [playground app](https://github.com/DartNative/dartnative/tree/main/playground) as Video Playback;
the pre-cache demo is in the plugin's example.

## Why you'll like it

- **Native playback engines** — AVPlayer and ExoPlayer do the decoding, so playback is smooth
  and battery-friendly, with the formats each platform supports out of the box.
- **Smart pre-caching** — start buffering the next clip ahead of time, with a byte budget so
  you control how much it pulls.
- **Bring your own controls** — ship the built-in controls, or overlay your own Dart UI on top
  of a clean video surface.

## Highlights

- **`VideoPlayerController(dataSource: …)`** — drive `play` / `pause` / `seekTo` / `setVolume` /
  `setSpeed` / `setLooping`.
- **`VideoDataSource.network(url, {headers, cacheConfig})`** / **`.file(path)`** — stream or
  play local files; pass a `VideoCacheConfig` to pre-cache.
- **`VideoPlayer(controller: …)`** — the player widget; set `aspectRatio`, `fit`, and
  `showControls`.
- **Ready-made controls** — `VideoPlayerWithControls` (player + controls), or `VideoOverlayControls` /
  `VideoBottomBarControls`, themed via `VideoControlsTheme`.
- **Nothing black before the video** — the player's view is transparent until its first
  frame, so a poster under it shows until then; `VideoEventType.firstFrame` and
  `controller.hasFirstFrame` tell you when the frame is there.
- **Picture in Picture** — `enterPictureInPicture()` / `exitPictureInPicture()`, and
  `autoPictureInPicture` to float the video when the user leaves the app, as TikTok does;
  `pipStarted` / `pipStopped` / `pipFailed` events. Two lines of platform setup below.
- **Background playback and the lock screen** — `allowBackgroundPlayback` keeps the audio
  going with the screen locked; `setNowPlaying(…)` puts the clip on the lock screen, in
  Control Center and in the media notification, with play, pause, the scrubber, next and
  previous, delivered as `remoteCommand` events. A few lines of platform setup below.
- **AirPlay** — every player sends its video to the Apple TV the user picks, as Apple's own
  player does; `AirPlayButton` or `showAirPlayPicker()` opens the system's route list from
  any button, through one shared picker; `isExternalPlaybackActive` and the
  `externalPlaybackChanged` event say when the video is on the other screen. iOS.

## Install

```yaml
dependencies:
  dartnative_video_player: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

Register the plugin once, in `main()`:

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

**Play a network video**

```dart
import 'package:dartnative_video_player/dartnative_video_player.dart';

final controller = VideoPlayerController(
  dataSource: VideoDataSource.network('https://example.com/clip.mp4'),
  autoPlay: true,
);

// In your build():
VideoPlayer(
  controller: controller,
  aspectRatio: 16 / 9,
);
```

**Control playback**

```dart
controller.play();
controller.pause();
controller.seekTo(const Duration(seconds: 30));
controller.setSpeed(1.5);
controller.setVolume(0.8);
controller.setLooping(true);
```

**Play a local file**

```dart
final controller = VideoPlayerController(
  dataSource: VideoDataSource.file('/path/to/video.mp4'),
);
```

**Pre-cache ahead of time**

```dart
VideoDataSource.network(
  url,
  cacheConfig: const VideoCacheConfig(useCache: true, preCacheSize: 5 * 1024 * 1024),
);
```

**Start fast in a feed**

```dart
VideoDataSource.network(
  url,
  // Half a second of media to start instead of the player's 2.5 s
  // default; the video appears as soon as it can. Defaults are the
  // player's own; iOS starts on the first frames regardless.
  bufferingConfig: VideoBufferingConfig.feed,
)
```

**Swap in a video only once it has a frame**

```dart
final next = VideoPlayerController(dataSource: VideoDataSource.network(url))
  ..initialize();
await next.events.firstWhere((e) => e.type == VideoEventType.firstFrame);
// The frame is there on iOS, off screen too; on Android it comes once the
// player's view is on screen, so swap on `initialized` there and let the
// poster under the view cover the moment before the frame.
```

**Picture in Picture**

```dart
final controller = VideoPlayerController(
  dataSource: VideoDataSource.network(url),
  autoPlay: true,
  autoPictureInPicture: true, // floats when the user leaves the app
);

// From a button:
if (VideoPlayerController.isPictureInPictureSupported) {
  controller.enterPictureInPicture();
}

controller.events.listen((e) {
  // Android floats the whole screen, so hide your chrome while it is up.
  if (e.type == VideoEventType.pipStarted) hideChrome();
  if (e.type == VideoEventType.pipStopped) showChrome();
});
```

The window's own play and pause buttons act on the player; `isPlaying`
follows, and the controller reports each press as a `remoteCommand` event,
`play` or `pause`, the way it reports the lock screen's.

**Keep playing with the screen locked, with the lock screen's controls**

```dart
final controller = VideoPlayerController(
  dataSource: VideoDataSource.network(url),
  autoPlay: true,
  allowBackgroundPlayback: true, // the audio goes on when the user leaves
);

// The clip on the lock screen, in Control Center and in the media
// notification; a feed calls this for the page on screen.
controller.setNowPlaying(NowPlayingInfo(
  title: clip.title,
  artist: clip.author,
  artworkUrl: clip.poster,
  hasNext: true,          // the app answers next and previous
  hasPrevious: index > 0,
));

controller.events.listen((e) {
  if (e.type != VideoEventType.remoteCommand) return;
  switch (e.command!) {
    case RemoteCommand.next:     goToNext();
    case RemoteCommand.previous: goToPrevious();
    // Play, pause and seek are done by the time the event comes;
    // update what you show, if anything.
    case RemoteCommand.play:
    case RemoteCommand.pause:
    case RemoteCommand.seek:
      break;
  }
});
```

Without `allowBackgroundPlayback` a player pauses as the app leaves the foreground and
resumes when it returns, unless its video is in Picture in Picture.

**AirPlay**

```dart
// An AirPlay button, cheap enough for one on every page of a feed: it
// draws an icon, and the one route picker behind it is built on the
// first tap. Draws nothing on Android.
AirPlayButton(controller: controller, activeColor: Colors.blue)

// Or from any button of your own:
VideoPlayerController.showAirPlayPicker();

// While the video plays on the Apple TV the player's view shows nothing,
// so whatever sits under it shows; say where the video went.
controller.events.listen((e) {
  if (e.type == VideoEventType.externalPlaybackChanged) {
    showAirPlayBanner(controller.isExternalPlaybackActive);
  }
});
```

> The player is a native view rendered through DartNative's view bridge
> (ViewType **1000**), so it sits naturally inside your Dart layout.

## Platform setup

### iOS

**Picture in Picture, background playback and the lock screen** need the audio
background mode: in Xcode, Signing & Capabilities, Background Modes, "Audio, AirPlay,
and Picture in Picture", which is `UIBackgroundModes` with `audio` in Info.plist. The
plugin puts the audio session in the playback category when any of the three is used.

**AirPlay** needs nothing: the video follows the route the user picks in the app's
button or in Control Center. While an AirPlay route is on, a player streams from
the source's own address rather than from the plugin's cache, since the screen
fetches the media itself; a player already playing from the cache switches over
at its position. The simulator has no AirPlay; test on a device.

HTTPS URLs play out of the box. To play an **HTTP (non-TLS)** URL, add an App Transport
Security exception for that host in your app's `Info.plist`.

### Android

**Picture in Picture** needs `android:supportsPictureInPicture="true"` on the
activity in `AndroidManifest.xml`. The floating window shows the activity's whole
content, so hide your chrome on the `pipStarted` event and let the player fill the
screen. Automatic entry when the user leaves the app is the system's on Android 12
and later, and DartNative's activity forwards the moment on Android 8 to 11.

**Background playback and the lock screen** come through the plugin's playback
service, which posts the media notification and keeps the app alive while the
player set with `setNowPlaying` plays. Declare it in `AndroidManifest.xml`, inside
`<application>`, with the permission beside it:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>

<service
    android:name="com.dartnative.video_player.DNVideoPlaybackService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
    <intent-filter>
        <action android:name="androidx.media3.session.MediaSessionService"/>
    </intent-filter>
</service>
```

Without the service the audio still plays on while the app is hidden, but the
lock screen and the notification have no player and the system may end the
process; the plugin prints a warning with the `DNVideoPlayer` tag.

Requires **minSdk 26** — set it in `android/app/build.gradle.kts`:

```kotlin
android { defaultConfig { minSdk = 26 } }
```

The plugin's manifest already declares `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK` and
`FOREGROUND_SERVICE` — nothing to add. To play an **HTTP (cleartext)** URL on Android 9+,
enable cleartext traffic for that host (via `usesCleartextTraffic` or a network-security config).

## Example

The [`example/`](./example) app plays a network clip with custom controls and seeking — borrow
from it freely.

## Credits & license

Evolved from [`BetterPlayer`](https://github.com/jhomlala/betterplayer) (Apache-2.0) on Android,
substantially reworked for DartNative; native AVPlayer on iOS.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
