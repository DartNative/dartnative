# The platform's own apps

The "Cards" and Chat screens written the way a good iOS and a good
Android developer write them, with no framework in between: not tuned to the benchmark, and not careless either. The code is
meant to be read, and to be agreed with as the reference every other
number is read against. The iOS app also has an Empty screen, a bar and a
line of text with nothing to scroll, as the DartNative app does: what an
app costs in memory before any list.

| Folder | Language and toolkit | What the list is |
| --- | --- | --- |
| `ios/` | Swift, UIKit | A `UITableView` whose cards are measured and prepared ahead of the scroll on a background queue as the table asks for the rows it is about to show (`UITableViewDataSourcePrefetching`: the row's height from the text's measure, the example's per-card work, the images requested), with cells laid out by frames; the text is drawn by the labels when the row appears, as UIKit draws text. |
| `android/` | Kotlin, Android views | A `RecyclerView` with a `LinearLayoutManager`. |

Both apps use the same data as the other two (the 1,000 cards, generated
the same way), the same layout, colours, sizes and radii, the 100-point box
at the top, the tap that expands a card and the swipe to the left that
reveals the "Complete" action behind it. Avatars are loaded by `URLSession`
with an in-memory cache on iOS, and by Coil on Android. The Cards screen is in the benchmark's
advanced mode (the example's `PERF_TEST` work when a card is configured,
one to forty sentences, a horizontal list of ten images inside every
card): a `UICollectionView` in the table cell, a `RecyclerView` in the
card sharing one view pool across cards.

## Building

iOS, on a connected iPhone (needs Xcode and XcodeGen):

```bash
cd ios
DEVELOPMENT_TEAM=<your team id> ./build.sh <device udid>        # CardsList (Swift)
DEVELOPMENT_TEAM=<your team id> ./build.sh <device udid> chat   # ChatList (Swift)
DEVELOPMENT_TEAM=<your team id> ./build.sh <device udid> empty  # EmptyList (Swift)
```

Android (needs a JDK 17 and the Android SDK):

```bash
cd android
./gradlew assembleRelease                      # CardsList (Kotlin)
./gradlew assembleRelease -PbenchScreen=chat   # ChatList (Kotlin)
adb install -r app/build/outputs/apk/release/app-release.apk
```

The iOS project compiles the harness's auto-scroll driver (`../harness/ios/autoscroll`, in
`project.yml`), which flings the list when the harness launches the app
with `BENCH_AUTOSCROLL` and is idle in every other launch.

Like the DartNative app, each is built for one screen, and each screen is
its own app, with its own id (`com.dartnative.benchmarks.scrollable.uikit.chat`,
`com.dartnative.benchmarks.scrollable.kotlin.chat`, ...) and name, so all
of them can sit on one phone. The harness scripts know them as `uikit` and
`kotlin`.

## What a native developer would write differently

- The swipe to reveal is written out with a pan gesture (iOS) and a touch
  listener (Android), as the React Native example's `Swipeable` does, so the
  three apps move the same views the same way. A native developer with no
  example to match would reach for `UITableView`'s trailing swipe actions
  and `ItemTouchHelper`, which look different while swiping and cost nothing
  while scrolling.
- The body text's 20 sp line height is `android:lineHeight`, which spaces
  lines from the second one on, where React Native's `lineHeight` and
  DartNative's `TextStyle.height` size every line box; the three cards
  come out within 4 dp of each other.
