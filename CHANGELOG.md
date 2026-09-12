# Changelog

<!-- Generated file — edits here are overwritten on the next release.
     The changelog is maintained at https://dartnative.com/changelog -->

## Right-to-left layout, text input formatters, keyboard and tab bar behaviour — Preview (2026-09-12)

Three fixes, two of them reported through the public repo by a team
building an Arabic-first app, all verified on an iPhone and on an Android
phone. To get them, install the SDK again with the install command for
your system from the getting started guide, then run `dn upgrade`. The
reinstall matters: the fixes live in the native iOS and Android bindings,
and only the latest `dn` replaces those on upgrade. `dn` tells you the
update is there on your next command.

### What changed

- **Layout follows the app's direction.** `Directionality` is here, and
  `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start` and
  `TextAlign.end`, `CrossAxisAlignment.start` and `MainAxisAlignment.start`
  resolve against it, on both platforms. The root direction comes from the
  platform: an app that declares Arabic in its localizations lays out
  right-to-left under an Arabic device language, as a native app does,
  and every `Row`, `Column`, padding, alignment and tab bar mirrors with
  it. Wrap a subtree in `Directionality` to set it by hand.
- **`TextField.inputFormatters`.** `TextInputFormatter`,
  `FilteringTextInputFormatter` (`digitsOnly`, `allow`, `deny`),
  `LengthLimitingTextInputFormatter`, `TextEditingValue`, `TextSelection`
  and `TextRange` are exported, and `TextEditingController` carries the
  selection. Formatters run on every edit before the keystroke is drawn,
  caret included, so a phone field that keeps digits only shows nothing
  else, even on a paste.
- **The keyboard covers the tab bar.** A `bottomNavigationBar` stays at
  the bottom and the keyboard slides over it, the way a native tab bar
  behaves on both platforms and the way Flutter's `Scaffold` behaves. Only
  `bottomInputBar` rides the keyboard. The body still lifts to show the
  focused field, and never past the point where its bottom edge meets the
  keyboard's top; a field further down its list is scrolled the rest of
  the way. Before, the tab bar was lifted over the body and a field could
  stay under the keyboard.

---

## iOS 26 fixes: navigation bars, search bar, date picker — Preview (2026-09-08)

Seven fixes, most of them reported through the public repo, all verified
on an iPhone running iOS 26. To get them, install the SDK again with the
install command for your system from the getting started guide, then run
`dn upgrade`. This time the reinstall is needed: the fixes live in the
native iOS and Android bindings, and only the latest `dn` replaces those
on upgrade. `dn` tells you the update is there on your next command.

### What changed

- **The back button stays put.** When a screen with a large title pushed a
  screen that used the system bar, the back button travelled in with the
  bar instead of fading in at its place. On iOS 26 the system navigation
  bar is now one bar for the whole stack, as it is in a UIKit or SwiftUI
  app: a screen that draws its own bar leaves it empty, a screen that uses
  the system bar fills it, and push and pop run the platform's own
  transition. The back button fades in place and the title slides.
- **No flash after a pop.** Returning from a system-bar screen to a
  large-title screen showed the content un-blurred under the collapsed bar
  for one frame. The bar is no longer hidden after a pop, so the blur is
  continuous through the transition.
- **The search bar reports when it closes, and the title follows it.**
  `SearchBar` has a new `onClosed` callback: it fires after the user leaves
  search with the platform's own control, Cancel on iOS or the back arrow
  on Android, so a "search is open" flag in your state can follow. When
  `AppBar.searchBar` comes and goes across rebuilds, the bar's title now
  steps aside while the pill is present and returns when you remove it, on
  both platforms; before, the title stayed under the pill and the pill
  stayed in the bar after you removed it. Cancel on iOS resets the query
  and reports that through `onChanged` only when there was one. The clear
  button inside the field is a text change and still reports an empty
  string.
- **A bar you return to answers taps again on iOS 26.** With the one-bar
  model above, a screen that draws its own bar (a search pill, a large
  title, a custom title) could stop responding to taps in the bar after
  you pushed a screen and came back, and a second, empty capsule could
  show beside the back button during a push. The system bar now lets those
  touches through for good and draws no back button of its own on such
  screens.
- **The first search bar opens without a stall on iOS.** The first
  `SearchBar` an app creates made UIKit build its search chrome on the
  spot, a third of a second on the tap that showed it. That cost is now
  paid at launch behind the splash screen, where the main thread is idle
  anyway, so the first Search tap is as quick as every later one.
- **The date picker's sheet fits its picker, and Done is whole on iOS 26.**
  The sheet from `showDatePicker` showed its Done button cut off at the
  sheet's corner, and the date-and-time picker's time row could land on the
  sheet's edge the first time it opened. The picker now sits under a
  navigation bar inside the sheet, as the system's own pickers do, the
  confirm control is the system item where iOS puts it, and the sheet is as
  tall as the picker needs, every time. New: `showDatePicker(confirmText:)`
  labels that control on both platforms; unset, each platform shows its own
  (the checkmark capsule on iOS 26, "Done" on earlier iOS, "OK" on
  Android).
- **Bar buttons keep their capsule fitted on iOS 26.** A `BarButtonItem`
  whose title changes on a rebuild, "Search" becoming "Close" for
  instance, now re-sizes its glass capsule to the new text instead of
  leaving the shorter title off-centre in the old one.

- **In the tool, and it comes with the reinstall: profile runs on an
  iPhone no longer hang.** `dn run --profile` on an iPhone could sit on
  "Installing and launching…" for good while the app was already running,
  because the tool waited for a debugger signal that only debug builds
  send.

Nothing changes in your code unless you want `onClosed` or `confirmText`. Screens that set
`systemBar: true` on `AppBarIOSConfig` and screens with a large title now
transition together the way the platform does. iOS 18 and Android are
untouched by the navigation bar change.

---

## The first public preview — Preview (2026-07-31)

DartNative is in preview and already used in production — see **Gee**, a
voice-first AI companion app available on the
[App Store](https://apps.apple.com/app/id6760962082) and
[Google Play](https://play.google.com/store/apps/details?id=com.withgee.app).
The framework, the `dn` CLI and the first-party plugins are all usable today,
and the API is stable enough to ship with. We're still moving fast though, and
some things will change before 1.0.

![DartNative at launch: 527,000 lines of original Dart, Swift, Kotlin and C
across 40 repositories and ~3,900 commits; 34 first-party plugins, all free and
open source; already used in production on real iPhone and Android
devices.](https://dartnative.com/media/img/dartnative-launch-card.png)

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
