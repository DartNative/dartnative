# Getting Started

This guide walks you through installing the `dn` CLI, setting up a new DartNative project, and running the playground.

---

## Prerequisites

DartNative supports two target platforms. Your development machine requirements depend on which targets you want to build for.

| Target | Development OS | Required tooling |
|---|---|---|
| iOS | macOS only | Xcode 26.3 or newer, a physical device or simulator |
| Android | macOS, Windows, or Linux | **Android SDK 36** + build-tools, a device or emulator |

> iOS builds require macOS because Xcode only runs on macOS. Android builds are cross-platform — you can develop for Android on Windows or Linux with no macOS involvement.

> **`dn` requires Android SDK 36.** It builds against API 36 and refuses an
> older platform outright (`DartNative requires Android SDK 36`). Install it
> from Android Studio's SDK Manager, or with
> `sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools"`.
> `dn doctor` reports what is missing.

---

## 1. Install the dn CLI

**macOS / Linux** — one command; it unpacks the SDK to `~/zero` and adds
`~/zero/bin` to your PATH:

```bash
curl -fsSL https://cdn.dartnative.com/install.sh | sh
```

**Windows** — open PowerShell and run:

```powershell
curl.exe -fsSL https://cdn.dartnative.com/dn_infra/sdk/latest/dn-sdk.tar.gz -o dn-sdk.tar.gz
tar -xzf dn-sdk.tar.gz -C $HOME
```

This unpacks the SDK to a `zero` folder in your home directory. Two more steps for Windows:

1. Search Windows for "environment variables" and add `%USERPROFILE%\zero\bin` to `Path`.
2. Install [Git for Windows](https://git-scm.com/download/win) if you don't have it — `dn` needs it.

Open a new terminal and verify:

```bash
dn --version
```

The first run downloads the prebuilt engine (a few hundred MB) into
`~/zero/bin/cache/`. Re-run the install command any time to update — your
engine cache is kept, so updates are quick.

---

## 2. Try it free — run a demo

The fastest way to see DartNative is an official demo — no account, no key,
nothing to configure. The playground demonstrates the framework across multiple
screens — lists, chat UI, canvas drawing, system controls, text input, images,
and more:

```bash
cd playground   # or any tutorials/* or plugins/*/example
dn pub get
dn run
```

The [playground](../playground/), the [tutorials](../tutorials/), and every
[plugin example](../plugins/) are free to build and run — **including release
builds**, so you can measure real performance.

On the iOS Simulator nothing needs signing. To run on a physical iPhone, open
`ios/Runner.xcworkspace` once, and under Signing & Capabilities pick your team
and set a bundle identifier of your own; a free Apple ID is enough, the
playground asks for no capability that needs a paid account. The push token
and Sign in with Apple demos are the exception: they switch on when you add
those two capabilities there, which does need the paid program.

---

## 3. Create your own project

To build and ship **your own** apps, subscribe at
[dartpub.dev](https://dartpub.dev/framework) — see
[pricing](https://dartnative.com/#pricing) for current plans. Then copy your
**license key** (`dnk_…`) from the Framework panel. Run the `dn config` command once — then
`dn run` just works as usual. Keep the key private, and regenerate it on the
Framework panel if it ever leaks.

The licence check runs inside `runApp`, from a token already on the device, in
a few milliseconds and never waiting on the network, so it does not slow your
app's launch. If your subscription ends, the apps you have already shipped keep
running for their users; a lapse only stops new builds.

**Activate and run:**

```bash
dn config --license-key dnk_...
dn create my_app
cd my_app
dn run
```

Or run without storing the key — same command, the key just rides the invocation:

```bash
dn run --dart-define=DN_LICENSE_KEY=dnk_...
```

An explicitly-passed key always wins; with neither, `dn` uses your trial token —
so running a demo never conflicts with your own builds.

Add DartNative dependencies — served from **dartpub.dev** and fetched by
`dn pub get` (just the package name; no registry or token setup):

```yaml
dependencies:
  dartnative: ^1.0.0          # core
  dartnative_ios: ^1.0.0      # iOS bindings
  dartnative_android: ^1.0.0  # Android bindings
  # dartnative_skia: ^1.0.0   # optional — only for Skia-backed canvas/pixel effects
```

Add plugins the same way — `dn pub add dartnative_video_player`, or edit
`pubspec.yaml` and run `dn pub get`.

Besides `pubspec.lock`, `dn pub get` writes `dn_plugins.lock` with the versions
of the DartNative plugins your app uses; commit both. When a newer framework
build is available, `dn` tells you, and `dn upgrade` installs it.

---

## 4. IDE setup

Install the **Dart** and **Flutter** extensions (VS Code) or the Flutter plugin
(Android Studio). Hot reload, autocomplete and debugging all run through
DartNative: the installer put `zero/bin` on your PATH, so `which flutter` in a
terminal prints a path inside your `zero` folder, and that is what the IDE
picks up.

One thing to know about VS Code: the Dart extension runs its own `dart pub get`
whenever you save `pubspec.yaml` in a project it does not recognise as Flutter,
and plain pub cannot resolve the DartNative packages, which ship with the SDK.
Projects made with `dn create` carry a `.vscode/settings.json` that turns that
off. For a project created another way, add it yourself, then run `dn pub get`
in a terminal after editing the pubspec:

```json
{ "dart.runPubGetOnPubspecChanges": "never" }
```

Have both Flutter and DartNative on your machine? DartNative wins by default.
To keep a Flutter project on stock Flutter, point its SDK setting —
`dart.flutterSdkPath` in its `.vscode/settings.json` — at your Flutter folder.

---

## 5. Build your first app

Setup done — from here, build something real. Follow
[Your first DartNative app](https://dartnative.com/tutorials/your-first-app)
step by step, or copy any [tutorial](../tutorials/) folder — each one is a
complete, runnable app.

---

## Learn more

- [Architecture](architecture.md) — how the framework works and how it differs from React Native
- [Widget reference](widgets.md) — full list of available widgets
- [Canvas & shaders](skia.md) — GPU canvas, SkSL shaders, rich text via `dartnative_skia`
- [Debugging & logging](logging.md) — native log bridge, `DartNativeLogger`, file persistence
- [Playground](../playground/) — working demo app to build and explore
- [Writing your own plugin](plugin_development.md) — plugins are ordinary Dart packages with FFI/JNI native sides; if your native code calls Dart back, see [async callbacks](plugin_async_callbacks.md)
