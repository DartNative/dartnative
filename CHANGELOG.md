# Changelog

<!-- Generated file — edits here are overwritten on the next release.
     The changelog is maintained at https://dartnative.com/changelog -->

## PageView, plus fixes to the keyboard, text fields and right-to-left bars — Preview (2026-09-17)

This release has ten changes: one new widget, seven fixes in the
framework, and two plugin updates. Several of them come from issues you
reported on the public repo. We tested all of them on an iPhone and on an
Android phone.

To get the framework changes, run `dn upgrade`. If that prints an install
command instead, your `dn` is too old to update itself: run the command it
prints, then run `dn upgrade` again.

Two plugins also have new versions, `dartnative_video_player` 1.0.1 and
`dartnative_lottie` 1.2.1. Run `dn pub upgrade` in your app to get them.

**iOS 13 and 14 are no longer supported.** Current versions of Xcode
cannot build for anything below iOS 15, so if you build with a recent
Xcode this was already true for you. The framework now states it.

### New

- **`PageView`.** You can now build a feed of full-screen videos, or an
  onboarding carousel, without writing the paging yourself. `PageView`,
  `PageView.builder`, `PageView.custom` and `PageController` all work,
  with the same fields as in Flutter. Underneath, a `FastList` has a new
  `pagingEnabled` flag you can use directly.

  Each swipe lands on exactly one page, and the movement is the
  platform's own, so it feels the way paging feels in other apps on the
  phone. Every page fills the viewport, and the framework sizes it for
  you: a feed inside a column, or under an app bar, still pages
  correctly. If you leave the item count out of `PageView.builder`, the
  feed has no end and grows as the reader scrolls.

  One difference from Flutter: `viewportFraction` must be 1.0. Flutter
  implements paging itself in Dart, so it can stop a swipe part way
  through a page. Here the paging is the platform's own, and both
  platforms page by the whole viewport, so there is nothing for a smaller
  fraction to map onto. That is the trade: you get the real thing rather
  than an imitation of it, and one field cannot follow. For a carousel
  where the neighbouring pages peek in at the edges, use a horizontal
  `FastList`, which scrolls freely and lets you size items as you like.

### Fixed

- **The keyboard no longer covers part of your input bar on Android.**
  A button at the bottom of an input bar cleared the keyboard, but
  anything below it, a label or the bar's own padding, was still hidden,
  by exactly the height of the phone's navigation area. We were measuring the top of the keyboard
  against one thing and the window against another. Both now come from
  the same place, so the measurement is right on any phone and in either
  navigation mode.
- **Text fields draw their own box.** `InputDecoration.border`, `filled`
  and `fillColor` were accepted but did nothing, so people wrapped fields
  in a box of their own, and the keyboard then covered the bottom of that
  box. Fields now draw the box themselves, on both platforms, and the
  keyboard clears all of it.
- **Fields sit closer to the iOS keyboard.** A field in the body of a
  screen floated 24 points above the keyboard on iOS, while the same
  field sat 8dp above it on Android. It is 16 points now, which is what
  Apple's own apps use. An input bar in the scaffold sits where the one
  in Messages sits, and moves with the keyboard's animation.
- **No more red error bar after navigating away.** If a button moved the
  app to another screen and then updated its own state, a red bar
  appeared across the screen and stayed until you restarted the app. This
  is what a login button does after it signs you in. A widget that is
  removed during a frame is no longer built in that frame, which is what
  Flutter does too, and `context.mounted` now tells the truth, so the
  usual check after an `await` works.
- **App bars mirror in right-to-left apps.** In an app set to Arabic, the
  screen mirrored but the app bar did not, as soon as the bar had a
  widget action in it: the back arrow stayed on the left and the actions
  on the right. The bar is now laid out in reading order and mirrored as
  a whole, on both platforms, and the back arrow points the way back
  rather than always pointing left.
- **Pasting into a formatted field leaves the cursor where it should
  be.** If you pasted into a field whose formatter rewrites the text, a
  phone number losing its country code for example, the text came out
  right but the cursor jumped to the very start, so the next character
  you typed went to the front. The cursor the formatter asked for is now
  applied after the paste finishes.
- **The framework's iOS pods ask for iOS 15.** On Xcode 27, a newly
  created app failed to build because several pods asked for an older iOS
  than that Xcode supports. The framework's two pods now ask for 15.0.
  We have not been able to test on Xcode 27 ourselves yet.

### Plugins

- **Videos in a feed appear immediately** (`dartnative_video_player`
  1.0.1). On Android, swiping quickly through a feed showed the poster
  image, or a black screen, for a moment before the video appeared.
  Players now draw their first frame before their page is on screen, so
  the page arrives with the video already showing. Playback also reads
  the disk cache, which it had been skipping, so a video you go back to
  starts from the disk instead of the network. On the framework side,
  Android plugins can now be told when one of their views is thrown away,
  which is what made this possible.
- **A renderer built for many animations at once** (`dartnative_lottie`
  1.2.0 and 1.2.1). A sticker keyboard shows thirty animations on screen
  and cycles through hundreds. The platform's animation engine, which is
  still the default and still the right choice for a few animations or a
  large one, builds a layer tree for each and pays for it on the main
  thread every time a view appears.

  Passing `renderCache: RenderCache.raster` uses a different renderer,
  built on rlottie. Each animation is drawn once, off the main thread, at
  the size the widget shows it, then kept compressed in memory and on
  disk and played back as frames. A view costs nothing to build, an
  animation you have shown before at that size is decoded rather than
  drawn again, and playing it costs the main thread one frame per view.
  The same renderer runs on iOS and Android, and the option has the same
  name as in the Flutter Lottie package. `LottiePreWarm.warmAssets` can
  prepare a screenful ahead of time, at the size they will appear.

  Version 1.2.1 fixes the one problem we knew of in it: on a detailed
  file it stopped drawing part of the animation once it reached an
  internal limit, so a sticker could appear without its eyes. That limit
  now applies only to the kind of content that can multiply, so
  hand-drawn artwork draws in full however detailed it is.

---

## Six fixes from community reports: text input, system appearance, rebuilds, preferences — Preview (2026-09-15)

Six changes, all from reports and requests on the public repo,
verified on an iPhone and on an Android phone. Five are in the
framework, one in the
`dartnative_shared_preferences` plugin. To get the framework fixes, run
`dn upgrade`. Older `dn` versions kept the native code in place on
upgrade, so if `dn upgrade` prints an install command, run that first,
then `dn upgrade` again. The preferences fix is plugin version 1.0.1:
run `dn pub upgrade` in your app.

### What changed

- **The app follows the system appearance.** An app that takes its
  colours from `MediaQuery.platformBrightness` now rebuilds when the
  device switches between light and dark while the app runs, including
  the common path of toggling it from Control Centre and coming back, on
  both platforms. Before, the appearance was read at launch and nothing
  told the framework it had changed.
  `WidgetsBindingObserver.didChangePlatformBrightness` arrives with it,
  for an app that keeps a derived palette outside the widget tree.
- **The keyboard's action key calls `onSubmitted`.** A `TextField` with
  `textInputAction` set to done, next, go, search or send showed the
  right key, dismissed the keyboard, and never called `onSubmitted`. It
  does now, on both platforms, before the field loses focus. Multiline
  fields keep inserting a newline, as in Flutter.
- **An input bar is lifted whole on Android.** A `bottomInputBar` with
  anything below its text field, a send row, a footer button, its own
  padding, was lifted only far enough to clear the field and the rest
  stayed behind the keyboard. The bar is now lifted by its own bottom
  edge, as it already was on iOS.
- **A style change reaches native text.** A `Text` under a
  `DefaultTextStyle` whose style changed kept its old colour and size,
  and the app kept the CPU busy while the screen sat idle. A native
  element now performs its queued rebuild instead of queuing itself
  again. `AnimatedDefaultTextStyle` was on the same path and is fixed
  with it.
- **Read an inherited value without watching it.**
  `BuildContext.getInheritedWidgetOfExactType<T>()` finds the nearest
  inherited widget of a type without registering the caller as a
  dependent: the read half of the read and watch split a provider
  library needs, beside `dependOnInheritedWidgetOfExactType`. One limit,
  unchanged by this release: the context handed to a list or grid item
  builder sits outside the element tree, so both lookups return null
  there. Read the value inside the item's own widget instead.
- **Preferences no longer cut a long value short** (plugin
  `dartnative_shared_preferences` 1.0.1). `getString` returned the first
  4095 characters of a longer value, and nothing said so. It now returns
  the whole value, on both platforms.

---

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
