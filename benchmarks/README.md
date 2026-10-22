# Benchmarks

Measurements of DartNative against other ways of building the same screen,
each in its own folder with everything needed to run it again: the apps,
the scripts that drive and measure them, and the numbers they produced.

| Folder | What it measures |
| --- | --- |
| [`scrollable/`](scrollable/) | Scrolling a list and a grid of cards: DartNative, React Native (Legend List, FlashList, FlatList) and the platform's own UIKit and RecyclerView, on the same phones. |
| [`hot_reload/`](hot_reload/) | Hot reload, from saving a file to the change on the screen: DartNative and Flutter, a small and a medium app, from the editor and from the terminal, on the iOS simulator with debug builds, as hot reload runs. |

Every benchmark here follows the same rules:

- **The other side's own code.** The screen being compared is taken from
  the other framework's own example, unchanged, and rebuilt for DartNative
  the way a DartNative developer would write it. Where the two had to
  differ, the folder says where and why.
- **The platform's own code as the floor.** The same screen written in
  Swift on UIKit and in Kotlin on Android views, so every number has the
  platform's own result next to it.
- **Release builds, real phones, the platform's own meters.** Frame
  statistics come from the operating system (`dumpsys gfxinfo` on Android,
  Instruments' Hitches and Display instruments on iOS), not from the
  frameworks' own counters.
- **Everything to run it again** is in the folder, with the versions and
  commits pinned.
