# Changelog

<!-- Generated file — edits here are overwritten on the next release.
     The changelog is maintained at https://dartnative.com/changelog -->

## The first public preview — Preview (2026-07-31)

DartNative is in preview and already used in production — see **Gee**, a
voice-first AI companion app available on the
[App Store](https://apps.apple.com/app/id6760962082) and
[Google Play](https://play.google.com/store/apps/details?id=com.withgee.app).
The framework, the `dn` CLI and the first-party plugins are all usable today,
and the API is stable enough to ship with. We're still moving fast though, and
some things will change before 1.0.

### What's in it

- **Real native rendering** — your widgets become UIKit and Android views, not
  drawings on a canvas
- **The Flutter widget API — almost.** Same widgets, same layout, same hot
  reload. Parameters that mean nothing to a native view are dropped, a few are
  named differently, and some widgets gain options the platform offers and
  Flutter has no equivalent for. Where we diverge you get a compile error, not a
  silent change in behaviour — see
  [porting a Flutter screen](https://dartnative.com/tutorials/porting-a-flutter-screen)
- **iOS 26 Liquid Glass and Material 3** — the platform's own components, not
  re-implementations. A good portion of both is supported already, and
  we're still working through the rest
- **First-party plugins** on [dartpub.dev](https://dartpub.dev) — camera, video,
  audio, webview, maps, notifications, purchases, storage, on-device AI
- **Native `CustomPaint`**, with optional Skia Graphite for shader-heavy work
- **One log stream** for Dart and native, saved on device so a tester's crash is
  still readable tomorrow

### While we're in preview

Updates ship continuously — sometimes several times a week — so we won't list
every small fix. Meaningful releases land here as they happen: what landed,
what broke, what got faster. Every entry on this page is also published as a
release on [GitHub](https://github.com/DartNative/dartnative/releases).

Found something wrong?
[Report an issue](https://github.com/DartNative/dartnative/issues) or write to
[hello@dartnative.com](mailto:hello@dartnative.com) — bug reports from preview
users are worth more to us right now than almost anything else.
