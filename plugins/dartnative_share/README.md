# dartnative_share

The native share sheet for DartNative — share text and files through the system
sheet (`UIActivityViewController` on iOS, `ACTION_SEND` on Android). One call, both
platforms, nothing to configure.

## Why you'll like it

- **Zero setup** — text or files, on both platforms; the plugin bundles its own Android
  `FileProvider` and share `<queries>`, so there's nothing to add to your app.
- **Text, files, captions** — one file or many, with an optional caption (shows up as the
  photo/video caption in apps like WhatsApp).
- **Familiar** — `Share.share()`, like `share_plus`.

## Highlights

- **`Share.share(text)`** — the system share sheet for some text.
- **`Share.shareFile(path, {mimeType, text})`** — share a file with an optional caption.
- **`Share.shareFiles(paths, {mimeTypes, text})`** — share several files at once.
- **`Share.shareWithResult(text)`** (and `shareFileWithResult` /
  `shareFilesWithResult`) — resolve with the outcome once the sheet closes:
  did the user share, via which target, or did they dismiss.

```dart
final result = await Share.shareWithResult('Join me: https://…');
if (result.status == ShareResultStatus.success) {
  analytics.log('shared_via', result.raw);
}
```

## Install

```yaml
dependencies:
  dartnative_share: ^1.0.0   # from dartpub.dev
```

```bash
dn pub get
```

```dart
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const MyApp());
}
```

## Quick look

```dart
import 'package:dartnative_share/dartnative_share.dart';
```

Share text:

```dart
Share.share('Join with my code ABC123 — https://dartnative.com');
```

Share a file with a caption (e.g. a photo + caption on WhatsApp):

```dart
Share.shareFile('/tmp/photo.jpg', mimeType: 'image/jpeg', text: 'Check this out!');
```

Share several files at once:

```dart
Share.shareFiles(
  ['/tmp/a.jpg', '/tmp/b.mp4'],
  mimeTypes: ['image/jpeg', 'video/mp4'],
  text: 'Trip recap',
);
```

> On iOS the OS infers each file's type from its extension (`mimeTypes` is accepted for
> API parity but ignored). On Android files are vended through the plugin's `FileProvider`.

## Platform setup

### iOS

No native setup required.

### Android

No native setup required — the plugin ships its own `FileProvider` and share `<queries>`,
merged into your app automatically.

## This plugin is open source — read it, copy it, learn from it

Unlike the other official plugins, `dartnative_share` ships its full source
right here. It's the reference implementation for the
[**Build a plugin** tutorial](https://dartnative.com/tutorials/build-a-plugin):
every layer of a dartnative plugin in ~400 lines — the Dart API, FFI symbol
loading, the Swift `@_cdecl` bridge, the Kotlin + JNI bridge, and (in the
`*WithResult` methods) the **hot-restart-safe async callback pattern** that
every plugin with native→Dart callbacks must follow. Start here when writing
your own plugin, or when porting one you already maintain.

## Credits & license

Ported from
[`share_plus`](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/share_plus)
(BSD-3-Clause, Copyright 2017, the Flutter project authors — full license
reproduced in [THIRD_PARTY_NOTICES](./THIRD_PARTY_NOTICES)), reworked to
FFI. This plugin's own source is MIT-licensed (see [LICENSE](./LICENSE));
also distributed prebuilt via [dartpub.dev](https://dartpub.dev).
