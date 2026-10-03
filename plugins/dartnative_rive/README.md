# dartnative_rive

Play Rive animations and state machines natively in DartNative — from a bundled asset, a
URL, a file, or bytes — driven by Rive's own runtimes. iOS and Android.

## See it in action

https://github.com/user-attachments/assets/8251233c-9ef1-4500-bd2b-b61a3f2d6f87

The Rive Marketplace Demos: a scripted audio player playing its music, a
traced Dragon Ball illustration with floating stones, a sleep onboarding
screen, the Big Wheel character changing its look at each tap, and a round
of StudioRun, a whole game built in Rive.

This is one section of the plugin's example app, which includes many other
examples too.

## Why you'll like it

- **The real Rive runtimes** — `rive-ios` and `rive-android`, so artboards draw through
  the platform's own Rive renderer. A looping animation costs no per-frame Dart work.
- **State machines, not just playback** — drive them through data binding, or set
  boolean, number and trigger inputs by name and watch what comes back: the events the
  machine reports, and every layer-state change it makes (on Rive's classic runtime,
  `legacy: true`).
- **Four sources** — bundled asset, remote URL (cached to disk), a file path, or bytes
  you already hold.
- **Taps and drags reach the artboard** — hit testing is on by default, so a Rive file
  authored with listeners just works.

## Highlights

- **`Rive(asset: …)` / `Rive(url: …)` / `Rive(path: …)` / `Rive(bytes: …)`** — the widget.
- **`artboardName`, `stateMachineName`, `animationName`, `autoplay`** — pick what runs.
- **`fit`** (`RiveFit`), **`alignment`** (`RiveAlignment`), **`hitTestBehavior`**
  (`RiveHitTestBehavior`) — Rive's own values, under the names its iOS runtime uses.
- **`RiveController`** — `play()` / `pause()` / `stop()` / `reset()`, `boolean(name)`,
  `number(name)`, `trigger(name)`, `setTextRunValue(name, value)`, plus `events` and
  `stateChanges` streams.
- **`legacy`** — draw with Rive's classic runtime instead of its current one. The
  current runtime is the default and runs data binding, out-of-band assets and
  semantics; inputs, events, text runs, layer-state changes and `animationName` need
  the classic one, as Rive deprecates them for data binding.
- **`semantics`** (`RiveSemantics`) — the artboard's authored semantics, handed to
  VoiceOver and TalkBack by the runtime's own view.

## Install

```yaml
dependencies:
  dartnative_rive: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_rive/dartnative_rive.dart';
```

Play a bundled artboard:

```dart
Rive(asset: 'assets/rive/bear.riv');
```

`Rive` is a native leaf widget with no size of its own — give it one:

```dart
SizedBox(
  width: 240,
  height: 240,
  child: Rive(asset: 'assets/rive/bear.riv', fit: RiveFit.contain),
);
```

Pick an artboard and a state machine, and drive its inputs. Inputs, events and text
runs belong to Rive's classic runtime, so the view that uses them sets `legacy: true`
(on the default runtime they do nothing, and the plugin logs why once):

```dart
final controller = RiveController();

Rive(
  asset: 'assets/rive/rating.riv',
  artboardName: 'Rating',
  stateMachineName: 'State Machine 1',
  controller: controller,
  legacy: true,
);

// later…
controller.number('rating')?.value = 4;
controller.boolean('hover')?.value = true;
controller.trigger('tap')?.fire();
```

Listen to the events the state machine reports:

```dart
controller.events.listen((event) {
  if (event is OpenUrlEvent) {
    openInBrowser(event.url);
  } else {
    print('${event.name} ${event.properties}');
  }
});
```

Change a text run:

```dart
controller.setTextRunValue('title', 'Hello');
```

From a URL, cached on disk after the first fetch:

```dart
Rive.network('https://cdn.example.com/bear.riv', fit: RiveFit.cover);
```

## Coming from Flutter's `rive` package

The Dart names you already use are the same: `Fit`, `Alignment` and the hit-test
behaviour (as `RiveFit` / `RiveAlignment` — DartNative exports its own `Alignment`
for layout), `BooleanInput` / `NumberInput` / `TriggerInput`, `GeneralEvent` /
`OpenUrlEvent`, and `setTextRunValue`. One difference: a view that uses inputs,
events or text runs sets `legacy: true`, as those run on Rive's classic runtime.

The load is one step instead of three:

```dart
// rive
final file = await File.asset('bear.riv', riveFactory: Factory.rive);
final controller = RiveWidgetController(file,
  artboardSelector: ArtboardSelector.byName('Bear'),
  stateMachineSelector: StateMachineSelector.byName('SM'));
RiveWidget(controller: controller, fit: Fit.contain);

// dartnative_rive
Rive(asset: 'bear.riv', artboardName: 'Bear', stateMachineName: 'SM',
     fit: RiveFit.contain, controller: controller);
```

Upstream splits it because `rive_native` decodes the `.riv` **in Dart**, so you
need a decoded `File` before you can choose an artboard. Here the platform's Rive
runtime decodes it, so there is nothing to hold on the Dart side — and nothing to
await.

This plugin hosts Rive's own views, so the artboard draws straight into a native
view, and a looping animation costs no per-frame Dart work.

**Interaction is a strength here.** The artboard is a real native view, so taps
and drags reach the state machine's listeners through the platform's own hit
testing, with nothing to wire up — an artboard authored with listeners just
works.

There are therefore two kinds of input, and it is worth knowing which you have.
Inputs **your app owns** — a rating, a toggle, a trigger — are yours alone:
write them through `RiveController` and they behave exactly as you set them.
Inputs the **artboard drives itself** from pointer position, such as a hover
state, are owned by the runtime, so a value you write from Dart can be replaced
on the next touch.

If you want an artboard's inputs to be exclusively yours, turn its own touch
handling off:

```dart
Rive(
  asset: 'assets/rive/bear.riv',
  controller: controller,
  hitTestBehavior: RiveHitTestBehavior.none,   // the view stops taking touches
);
```

Nothing then competes with what you write, at the cost of the artboard's own
listeners: taps no longer reach it, so drive everything through the controller.
Use it when a Rive graphic is decoration you animate yourself, and leave the
default when the file was authored to be interacted with.

The other three values — `opaque`, `translucent`, `transparent` — all leave
the artboard's own hit testing on. They are accepted for source compatibility
with Rive's API; only `none` changes behaviour today.

## Platform setup

Bundled `.riv` files go under `dartnative: assets:` in your `pubspec.yaml`, the same as
any other asset. Assets, files and bytes need no further setup.

### iOS

The plugin needs **iOS 15.0** or later, DartNative's own minimum (Rive's runtime
needs 14.0). Nothing else for HTTPS; a plain-**HTTP** URL needs an App Transport
Security exception in `Info.plist`.

### Android

Requires **minSdk 24** — set it in `android/app/build.gradle.kts`:

```kotlin
android { defaultConfig { minSdk = 24 } }
```

The plugin's own manifest declares `android.permission.INTERNET`, which
`Rive(url: …)` and a file's hosted (CDN) fonts and images need; it merges into
your app's manifest, so there is nothing to add. A plain-**HTTP** URL also needs
`android:usesCleartextTraffic="true"` on your `<application>` tag.

## Notes

- **Sizing** — the widget has no intrinsic size. Wrap it in a `SizedBox`, a `Container`,
  or an `Expanded`.
- **`stateMachineName` wins over `animationName`** when both are given, as it does in
  Rive's own runtimes.
- **Inputs are fire-and-forget.** `controller.boolean('x')?.value = true` reports what
  this side last set; a state machine that changes its own inputs does not report back.
  A name the file does not define is ignored by the runtime.
- **Events flow only while something is listening** to `controller.events`.

## Data binding and out-of-band assets

Both follow rive-flutter's API, so upstream code moves with the import swap.
`controller.viewModelInstance` is the file's default view-model instance, bound
automatically (`Rive(autoBind: true)`); `number('Coin/Item_Value')`,
`string(…)`, `boolean(…)`, `color(…)`, `enumerator(…)`, `trigger(…)` and
`viewModel(…)` resolve properties by path, each with `value`, listeners and a
`valueStream`. Values are pushed from the runtime, so `value` reflects the last
push (the runtime is read on the platform side, not synchronously from Dart).
A value set before the widget mounts (a screen's `initState`) is sent when it
does, so upstream code that configures the instance right after creating the
controller behaves the same.
`image(…)` takes a `RenderImage` from `RiveFactory.decodeImage` (null clears
it); `artboard(…)` takes a `BindableArtboard` from
`RiveFile.asset(path).artboardToBind(name)`, rive-flutter's `File` under a name
that does not hide `dart:io`'s; `list(…)` takes instances made with
`controller.viewModelByName(name).createInstance()` through `add`, `insert`,
`remove`, `removeAt` and `swap`. New instances and list edits live in the view's
file, so they need the widget mounted, as upstream's need the file loaded.
`Rive(assetLoader: (asset, bytes) => …)` is upstream's callback for a font,
image or audio clip the file references but does not embed: `asset.decode(bytes)`
hands the runtime the bytes, `loadAssetBytes` (the DartNative equivalent of
`rootBundle.load`) reads a bundled one.

## What is not here

Shared textures (`RivePanel`), `RiveBuilder`, the
nested-artboard `path:` input variants, font properties, and reading a data-bound
list back (`length`, `instanceAt`) are not in this version. `MIGRATION.md` lists them with the reason for each, and
what would change if they were added.

## Example

The [`example/`](./example) app rebuilds rive-flutter's own example app screen for
screen: the same menu, sections, screen names, descriptions and `.riv` files, in
their dark theme, so the two can be walked side by side on a phone. Each ported
screen is re-expressed against this plugin's API and carries a header naming the
upstream file it came from and what changed. Every screen upstream ships runs, the
two Semantics screens included.
The section "Rive Marketplace Demos" plays files as they were published: four
from the Rive Marketplace, a scripted audio player by RiottersDesign, the
StudioRun game by thelittlelabs, the Big Wheel Demo by JcToon and a sleep
onboarding screen by marciofpantoja (all CC BY 4.0, credited on their screens),
and DartNative's own trace of an image generated with
Craiyon (also credited on its screen). The last
section, "Additional demos", holds this example's own screens:
playback and inputs, who owns an input (`hitTestBehavior`), every fit and
alignment, text runs and artboard selection, and a recycling grid. Borrow from
it freely.

`parity/` holds the same screens written natively — SwiftUI against RiveRuntime,
Kotlin against rive-android — so the two can be run side by side. A difference
there is this plugin's doing, since the same C++ renderer draws both.

## Credits & license

Powered by Rive's own runtimes — [`rive-ios`](https://github.com/rive-app/rive-ios) and
[`rive-android`](https://github.com/rive-app/rive-android) (MIT). The Dart API mirrors
[`rive-flutter`](https://github.com/rive-app/rive-flutter)'s names where they are pure
Dart, so code moves across with the import swap.

The example ports screens from rive-flutter's `example/` (MIT) and bundles sample
`.riv` files from rive-ios's `Example-iOS/Assets` and rive-flutter's `example/assets`
under the same MIT licence; each ported file names its source, and the plugin's
`THIRD_PARTY_NOTICES` lists every file and reproduces the licences. Rive community
files are not covered by it — read the terms on any file you take from there. The
four the example bundles, "Audio Player" by RiottersDesign, "StudioRun - A Cosmic
Game by TheLittleLabs" by thelittlelabs, "Big Wheel Demo" by JcToon and "Sleep
onboarding screen" by marciofpantoja (illustration by Afsar Hossen), are under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) and bundled unmodified;
`example/assets/rive/marketplace/NOTICE.md` credits them, with the licence's full
text beside it.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on the
plugin's page.
