# The DartNative app

Legend List's "Cards" screen and its chat, with photos and stickers
added, rebuilt with DartNative for the scrolling benchmark; the Cards
screen is in the benchmark's advanced mode. The React Native side is
Legend List's own example app; see `../react_native/`.

```bash
dn pub get
dn run --release                                   # CardsList (DN)
dn run --release --dart-define=BENCH_SCREEN=chat   # ChatList (DN)
dn run --release --dart-define=BENCH_SCREEN=empty  # EmptyList (DN)
```

Empty is a screen with nothing to scroll, a bar and a line of text: its
memory is what the app costs before any list, the floor the other
screens' numbers sit on; the Swift app has the same screen.

Each screen is its own app, with its own id
(`com.dartnative.benchmarks.scrollable.cards`, `.chat`, `.empty`) and
its own name, so all of them can sit on one phone. Android takes both
from `BENCH_SCREEN`. On iOS the id comes from an Xcode build setting of
the same name (`cards`, `chat` or `empty`), fixed
before the screen is known, so a screen other than Cards is built with the
setting too; the build stops with this line when the two do not match:

```bash
FLUTTER_XCODE_BENCH_SCREEN=chat dn run --release --dart-define=BENCH_SCREEN=chat
```

The list keeps rows built within 250 points of the screen on each side
(`cacheExtent: 250`, Legend List's draw distance and Flutter's default)
and reuses the rows it lets go for the rows that scroll in
(`recycleItems: true`), the counterpart of the example's `recycleItems`;
add `--dart-define=BENCH_KEEP_ALIVE=<n>` for a window of n rows on each
side instead (`keepAliveCount`), or `=0` to hold every row the user has
scrolled past, the list's default, with nothing to reuse. The results
use the 250-point window. `--dart-define=BENCH_LOG=1`
runs the app with the framework's verbose log written to
`Documents/bench_log.txt` in the app's container; off for a measured run,
since the log costs frames.

The Android manifest marks the app `profileable`, so the release build can
be profiled as it is measured (`harness/android/trace.sh`, simpleperf);
the mark changes nothing at run time. The iOS Podfile adds the harness's
auto-scroll driver (`../harness/ios/autoscroll`), which flings the list
when the harness launches the app with `BENCH_AUTOSCROLL` and is idle in
every other launch.

## What is the same

- **The data.** 1,000 cards generated exactly as the example generates them:
  the same 20 names, the same 20 avatar addresses on i.pravatar.cc, the same
  timestamp, and the same one to twelve sentences per card
  (`(index × 7919) mod 12 + 1`).
- **The card.** The same layout, sizes, colours, radii and border, the
  100-point box at the top of the list, and the screen's background colour.
- **The interactions.** A tap expands the card's text; a swipe to the left
  reveals an 80-point "Complete" action, built with every card as the
  example's `Swipeable` builds it.
- **The screen around it.** A navigation bar titled like the example's stack
  header, in the same colour and at the same height.

## Where the code differs, and why

Each of these is written the way a DartNative developer would write it;
none of them changes how much work a card costs.

- **The card's width is given explicitly.** In Flutter, a `Stack` child in a
  `SizedBox(width: double.infinity)` takes the full width; DartNative's
  `Stack` does not stretch it, so the card is given its column's width.
- **The footer's top line is a 1-point view.** The example uses a top border;
  DartNative's `Container` draws borders on all four sides or none.
- **The shadow.** On Android the example's card has `elevation: 4`, the
  platform's own view shadow, and the DartNative card draws the same
  elevation shadow. On iOS the example's `overflow: hidden` clips its shadow
  away, so neither app shows one there.
- **Text height.** On iOS the cards match to within a point. On Android
  the three apps spell a 20 sp line height three ways (`TextStyle.height`
  sizes every line box, as React Native's `lineHeight` does; Android's
  `lineHeight` spaces lines from the second one on), so a DartNative card
  is about 1.5 dp shorter than the Kotlin one and 3.5 dp shorter than the
  React Native one.

## The advanced mode

The Cards screen is in the benchmark's advanced mode, the same in every
app: the example's own `PERF_TEST` work in every card's build
(`CardData.perfTest`, its result line `_PerfLine`), one to forty
sentences per card (`CardData.longBody`) and a horizontal `FastList` of ten images
inside every card (`_ImageRail` in `item_card.dart`,
`CardData.railUrls`). A card's expanded and swiped state
belongs to the item, so a reused row resets both in `didUpdateWidget` when
it shows another card, as the example's `useRecyclingState` does.
`ItemCard(advanced: false)` keeps the example's plain card.
