# dartnative_autostart_settings

Send users to the **manufacturer auto-start / background-battery settings** so your
backgrounded app stops getting killed. Aggressive Android OEMs (Xiaomi/MIUI,
Oppo/ColorOS, Vivo, Huawei, Samsung, …) throttle or kill apps unless the user
allows them in an OEM-specific screen — there's no permission for it, only a deep
link. This finds the right screen for the device and opens it. A drop-in for
`autostart_settings`.

## Why you'll like it

- **Stops OEM app-killing** — opens the auto-start allow-list / battery screen the
  user must visit so local notifications and background work survive.
- **Device-aware** — carries a curated list of OEM settings activities and opens the
  first one that resolves on the current device.
- **Check before you nudge** — `canOpen(...)` tells you whether this device even has
  such a screen, so you only prompt users who need it.

## Highlights

- **`AutostartSettings.open(autoStart: true, batterySafer: true)`** — open the OEM
  auto-start and/or battery-optimization screen; returns `true` if one launched.
- **`AutostartSettings.canOpen(autoStart: true, batterySafer: true)`** — is there a
  screen to open on this device?
- **`autoStart`** targets the OEM auto-launch allow-list; **`batterySafer`** targets
  the OEM battery-optimization / background-restriction screen.

Android only — `canOpen` / `open` return `false` on every other platform.

## Install

```yaml
dependencies:
  dartnative_autostart_settings: ^1.0.0   # from dartpub.dev
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
import 'package:dartnative_autostart_settings/dartnative_autostart_settings.dart';
```

Nudge the user only when the device has a screen for it:

```dart
if (await AutostartSettings.canOpen(autoStart: true, batterySafer: true)) {
  // show your "allow background activity" explainer, then:
  await AutostartSettings.open(autoStart: true, batterySafer: true);
}
```

Battery screen only:

```dart
await AutostartSettings.open(autoStart: false, batterySafer: true);
```

## Android setup

Nothing to declare — each OEM activity is launched only after `resolveActivity()`
confirms it is exported and permission-free. Pair this with the battery-optimization
exemption (`Permission.ignoreBatteryOptimizations`) for the most reliable background
delivery.

> Android-only plugin. `canOpen` / `open` return `false` on every other platform,
> so you can call them unconditionally behind a single code path.

## Credits & license

Ported from
[`autostart_settings`](https://github.com/chris-wolf/autostart_settings)
(MIT, © 2024 Christopher Wolf) — the curated manufacturer-activity list is kept
intact; the Flutter method channel was reworked to FFI.

Commercial plugin distributed via [dartpub.dev](https://dartpub.dev) — file issues on
the plugin's page.
