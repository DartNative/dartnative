# Scrolling benchmark: lists and grids

The same screen of 1,000 cards, built four ways and scrolled the same way
on the same phones:

| App | Built with | List |
| --- | --- | --- |
| DartNative | Dart, the DartNative framework | `FastList` (a `UITableView` on iOS, a `RecyclerView` on Android) |
| Swift (UIKit) | Swift, UIKit | `UITableView`; "Cards (Swift)" in its title bar |
| Kotlin | Kotlin, Android views | `RecyclerView` |
| Legend List | React Native 0.81, Legend List 3.6 | `LegendList` with `recycleItems` |

Legend List stands for React Native in the results, as the fastest of
the three lists its example app offers. The harness builds and runs the
FlashList and FlatList apps too (`react_native/setup.sh`, the `flashlist`
and `flatlist` names of `harness/apps.sh`), so anyone can measure them
the same way.

The screen is Legend List's own "Cards" example, taken from their
repository and rebuilt for DartNative, Swift and Kotlin. The React Native
apps run from their own example app at a pinned commit with the versions
their lockfiles pin, as release builds. Each card has an avatar, an author
line, a title, text and a footer; a tap expands the text and a swipe
reveals an action. The Cards screen is measured in the benchmark's **advanced mode** only, the
same in every app: the example's own per-card `PERF_TEST` work in every
card's render, text from one sentence to forty so a short card sits
beside a long one, and a horizontal list of ten images inside every card,
scrolled down and then back up: what a real feed does, and what Legend
List's own issue tracker says is hard for it. A bar button, Scroll, sends
the list to cards far away that it has never measured, with an animated
scroll, the hard case of scrolling to an item.

The second screen comes from the same example app: **Chat**, Legend
List's chat example with a looping Lottie sticker after every third
message, as messaging apps show stickers, scrolled up through its
history.

- [`RESULTS.md`](RESULTS.md): the numbers, with the device, build and
  setting behind each one.
- [`METHODOLOGY.md`](METHODOLOGY.md): what is measured, how the list is
  scrolled, and every choice that could favour a side.
- [`dartnative/`](dartnative/), [`native/`](native/),
  [`react_native/`](react_native/): the apps. Each screen of each app is an
  app of its own, opened straight on that screen, with a name that says
  the screen, the framework and the list: "CardsList (DN)", "ChatList
  (Kotlin)", "CardsList (Swift)", "ChatList (RN - FlatList)". All of them
  can sit on one phone.
- [`harness/`](harness/): the scripts that scroll, measure and summarise,
  on Android (`dumpsys gfxinfo`, `dumpsys meminfo`, a blank-space count
  from a screen recording) and on iOS (the app flings its own list, the
  same way in every app, and an Instruments trace read inside the flings
  gives the typical frame time, the hitches, the frames shown, the
  refresh rate, the CPU time and the memory).

## Running it yourself

```bash
# React Native: Legend List's example at the pinned commit, release build,
# one app per screen and list ("CardsList (RN - Legend)")
react_native/setup.sh android cards legend     # or ios; chat flatlist, ...

# DartNative ("CardsList (DN)"; dartnative/README.md has the other screens)
cd dartnative && dn pub get && dn run --release

# The platform's own apps
native/android/gradlew -p native/android assembleRelease
DEVELOPMENT_TEAM=<team> native/ios/build.sh <iphone udid>

# Android, three timed runs of each app on a device, then the summary
ANDROID_SERIAL=<device> harness/android/run.sh dartnative cards 3 out/dartnative
python3 harness/android/summarize.py out/*

# iOS, one run of 25 flings under Instruments, then its summary
harness/ios/trace.sh dartnative cards <udid> out
python3 harness/ios/trace_summary.py out/dartnative_cards.trace
```

Every script names its inputs at the top. Legend List's checkout and
build land in `react_native/.work/`, which is not committed.
