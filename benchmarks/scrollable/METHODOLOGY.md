# How the scrolling benchmark is measured

The point of this document is that anyone can check every step, run it
again on their own phone, and get the same kind of numbers. Where a choice
could favour one side, it says which side and why the choice was made.

## The screen

Legend List's example app has a "Cards" screen: 1,000 cards, each with an
avatar, an author line, a title, one to twelve sentences of text and a
footer; a tap expands the text, a swipe to the left reveals a "Complete"
action. The example offers the same screen on Legend List, FlashList and
React Native's FlatList. That app is the React Native side of this
benchmark, at a pinned commit, with the versions its own lockfiles pin:
React Native 0.81.5 with the New Architecture, Expo 54, Legend List 3.6.0,
FlashList 2.3.2, Reanimated 4.3.0, release builds with Hermes.
`react_native/setup.sh` clones and builds it; nothing of theirs is copied
here or edited. Legend List stands for React Native in the results, as
the fastest of the three lists; the harness builds and runs the
FlashList and FlatList apps the same way, for anyone who wants their
numbers, and the scroll-to tables show them too. The additions are files
of ours (`react_native/advanced/`) that the script places beside theirs: a route for each screen the
benchmark opens, which shows the example's own screen under a bar title
naming the framework and the list ("Cards (RN - Legend List)", as the
other apps' titles end in "(DN)", "(Kotlin)" and "(Swift)"), so a
recording says what it shows; and the Cards screen below, three routes
and the component they share.

The Cards screen, in every app, is the example's Cards screen in the
benchmark's **advanced mode**, and the benchmark measures only that. The
example's Cards screen is Legend List's own showcase, built around what it
does well; the advanced mode keeps the same cards and adds what a real
feed does and what its issue tracker says is hard for it, three things at
once:

- **work in every card's render**: the example's own `PERF_TEST` block
  (`cardsRenderItem.tsx`, "EXPENSIVE COMPUTATIONS": a prime check, a
  Fibonacci number computed the slow way, string and array work), copied
  unchanged and done wherever each app builds a card (the React Native
  render, the Dart `build`, the Kotlin bind, the Swift configure), with
  the two results the example shows on a line under the footer, so no app
  can skip it. A real card formats dates, prices and text in its render;
  in React Native that runs on the JavaScript thread, which also renders
  every item the list brings in;
- **a horizontal list of ten images inside every card**, a list inside a
  recycled list (issues 325 and 327: blank or wrongly rendered inner lists
  under outer recycling; 528: horizontal lists and changing item sizes);
- **text of very different lengths**: one sentence to forty, from two
  lines to more than a screen, spread so a short card sits beside a long
  one (card n takes entry (n × 7) mod 13 of 1, 2, 3, 4, 6, 8, 10, 12, 16,
  20, 24, 32 and 40 sentences). A list cannot guess a card's height from
  its neighbours', so the estimate a row is given before it is measured is
  wrong more often (534 and 545: gaps and collapsed rows while sizes
  settle; 529: scroll targets drifting as rows above measure in).

The images come from the same service as the avatars, seventy distinct
ones, so each app's image cache holds them after the warm-up run. The
mode is the same in all four apps, built the same way: a nested horizontal
list of each framework's own kind (Legend List, FlashList or FlatList
inside itself; a `FastList` in a `FastList`; a `UICollectionView` in a
`UITableView` cell; a `RecyclerView` in a `RecyclerView`).

The same two screens are written three more times:

- in DartNative (`dartnative/`), the way a DartNative developer writes a
  list: a `FastList` of the cards;
- in Swift on UIKit (`native/ios/`), "Swift (UIKit)" in the results and
  "Cards (Swift)" in its title bar: a `UITableView`;
- in Kotlin on Android views (`native/android/`): a `RecyclerView`.

All four generate the same 1,000 cards the same way, draw them with the
same sizes, colours, radii and borders, and carry the same two
interactions. The places where a port had to differ are listed in each
app's README; none of them changes how much work a card costs.

## The Chat screen

A chat is where a list most often meets animation: stickers, animated
emoji, reactions. Legend List's example app has a chat screen
(`ChatExample.tsx`): a thread of messages of mixed sizes, from one-word
replies to long paragraphs and tall image attachments, opened at its
newest message. The benchmark's Chat screen is that thread, 1,000
messages made by the example's own generator (`buildChatMessages`), with
its bubbles, attachment cards and colours, and two kinds of message
added: after every fourth message a photo, shaped like a bubble (its
corners, no padding), 240 points wide at one of five aspect ratios and
loaded over the network by each app's own image view; after every third,
a sticker, a looping Lottie animation shown bare on the sender's side,
160 points square, as messaging apps show stickers. One thing is drawn
differently from the example: a message with an attachment card takes
the bubble's whole width and the card fills it, as a link preview does in
a messaging app, where the example draws the card 220 points wide
whatever the bubble's width, short of a long message's text. The 24
stickers are six from each of four packs of the DartNative
playground's sticker keyboard (512 × 512, 60 frames a second, two to four
seconds long), and every app plays the same files, in the same order,
which comes from a small generator with a fixed seed rather than a cycle:
a list recycles its views in turn, and a file that came back at a fixed
distance to the view still holding it would be shown without a build,
which no real chat offers. The sticker libraries:

- React Native: `lottie-react-native` 7.3.8, the newest release in the
  range Expo 54 lists for it, which plays through lottie-android 6.7.1 and
  lottie-ios 4.6.0. It is the one package `setup.sh` adds to the example's
  dependencies.
- DartNative: the `dartnative_lottie` plugin 1.3.2, which plays through
  the same lottie-android 6.7.1 and lottie-ios 4.6, on their own engines.
  The plugin has a faster way to show stickers, its frames renderer
  (`renderCache: RenderCache.raster`): it draws every frame of a sticker
  once, off the main thread, keeps the frames compressed and plays them
  as bitmaps, which is how a sticker keyboard is drawn. The benchmark
  does not use it, so that every app plays the same files through the
  same libraries and the numbers compare the lists, not the renderers.
- Kotlin: lottie-android 6.7.1's `LottieAnimationView`. Swift: lottie-ios
  4.6.0's `LottieAnimationView`, built for the rows the table names as
  coming next (`prefetchRowsAt`) and asked to build its animations there,
  so the Swift app has its stickers ready before the row shows; lottie-ios
  otherwise builds them in the frame that first shows the row.

The thread opens at its newest message, at the bottom, each list in its
own documented way: Legend List with the example's own chat settings
(`getChatListProps`: aligned to and opened at the end, `recycleItems`,
its size estimate), FlashList with `initialScrollIndex` and
`maintainVisibleContentPosition` starting from the bottom, FlatList
`inverted`, DartNative a reversed `FastList` (as the playground's chats
are), Kotlin a `RecyclerView` laid out from the end, and UIKit a
`UITableView` turned upside down. Legend List and FlashList are told which
rows are stickers (`getItemType`), as their guides advise for rows of
different kinds; the Kotlin adapter has the same two view types. The
example's composer and jump-to-latest button are left out: the screen is
there to scroll. The other apps read the messages from
`assets/chat.json`, which `tool/extract_chat.sh` writes with the
example's own generator, so every app shows the same thread.

The run scrolls up through the history, with the Cards screens' gesture
reversed (`harness/android/autoscroll_up.sh`).

## What is measured

Scrolling has two failure modes, and a fair benchmark has to catch both.
A framework that builds its content on the UI thread (DartNative, UIKit,
Android views) can drop frames when a card takes too long to build; a
framework that builds its content on another thread (React Native's lists)
keeps the frame rate up but can show empty space where a card has not
arrived yet. So the benchmark measures both the frames and the blank space,
with the platform's own tools:

- **Frames, on Android:** `dumpsys gfxinfo` after each launch. The results
  compare the median frame time, p50: how long a typical frame took,
  counted from the refresh it was meant for. `dumpsys meminfo` gives the
  memory (PSS): three more launches, not timed, read it once a second through
  the scroll and once more after it, the highest reading the run's peak
  and the last its rest. The app computes its own total for each reading,
  and its Java runtime collects its garbage first (Android's tool does
  that to count live objects), which is why those launches are not timed, and
  why the numbers are the memory an app holds rather than the garbage it
  has not collected yet; Dart's and JavaScript's heaps collect on their own
  schedule and are read as they are. The harness reads the memory at the
  end of a timed run too. `gfxinfo` also gives the times of
  the slowest frames (the 90th, 95th and 99th percentiles) and the share
  of frames it counts as late; the harness prints them for every run
  (`harness/android/table.py --all`), and the results do not compare
  them, for the reasons below.
- **Blank space, on Android:** the blank rows of the Scroll button's long
  scrolls, from a screen recording of each app ("Scrolling to a far
  item"). The harness can also count blank space in a screen recording of
  an autoscroll run, frame by frame (`harness/blank_area.py`: the share
  of the list area showing the list's own background colour, `#445566`,
  which no card, avatar or text uses), but inside the autoscroll every
  app reads at the count's noise level, so the results do not show it. A
  recorded run is never a timed run, since the recorder itself uses the
  device.
- **Blank space, on iOS:** the driver that flings the list counts it
  itself in a run of its own (`harness/ios/blank.sh`, `BENCH_BLANK=1`):
  every frame inside the flings, the share of the list's visible height
  that shows no content. The screen is read in horizontal bands of 4
  points. A band is covered when a drawn view crosses it anywhere across
  the width, a drawn view being one with layer contents, a label with
  text, an image view with an image, a Lottie view with a drawn layer
  under it, or an opaque background other than the list's own on a view
  narrower than the list, a card or a bubble (a view as wide as the list
  with an opaque background is a row's canvas, an empty cell for
  instance, not content). So a chat's own
  empty space beside a bubble is covered by the bubble, and an empty
  stretch taller than a row gap (24 points; the gaps are 12) is missing
  content: a row not drawn yet, or a sticker whose animation has not
  been built, since such a sticker draws nothing. The frames with the
  header box on screen are left out, as in the Android recording. Every
  framework ends in the same UIKit view tree, with the same Lottie view
  for a sticker, so the count reads the same for all three; it needs no
  row views, which React Native's renderer flattens away. The walk costs
  the main thread about a millisecond a frame, so a blank run is never a
  timed run. The driver also writes the count as a time, the share
  weighted by each frame's time on screen, in milliseconds per second of
  scrolling, for reading next to hitch time.
- **Frames, on iOS:** an Instruments trace of a 25-fling run
  (`harness/ios/trace.sh`: the os_signpost, Hitches, Display, Time
  Profiler and Activity Monitor instruments; three launches of each app,
  and the results show the middle one, since the hitch time moves from
  one launch to the next), read inside the flings by `trace_summary.py`:
  the hitches (a frame that reached the screen later
  than its deadline, counted by the Hitches instrument when the frame
  reaches the screen, by the same rule for every app) and their time, the
  longest of them, and how many were four frames late or more; the
  frames the app showed a second; the typical frame time, the median of
  the Hitches instrument's own reading of each frame's update (the time
  the app took to prepare that frame); the panel's refresh rate vsync by vsync
  (which is what explains a frame rate below 120), the app's CPU time on
  its main thread and on all threads, and its memory footprint at rest
  ten seconds after the last fling, as the app's own census measures it
  (`BENCH_MEMORY`: the footprint, the dirty memory by the kind of
  allocation and the sizes its regions come in, the footprint once the
  malloc pages that are dirty but free are given back, as they are under
  memory pressure, the malloc heap by class, by block size and by how
  full its regions are, the window's largest layers, and the runtime's
  own account of its heap where the app writes one: the DartNative app
  writes its Dart heap's counters once a second), and at its peak during
  the flings, the highest footprint the Activity Monitor instrument
  sampled before the census. The census is how a memory difference
  between two apps is read: which kind of memory holds it, and what
  objects. Ten seconds and
  not three: the image buffers of rows a list let go stay in the system's
  surface pool for about eight seconds after the app stops asking for new
  ones, and count in its footprint until then (measured on a screen of
  image rails: 121 MiB three seconds after the last fling, 100 ten seconds
  after, with no work of the app's in between). The DartNative and Swift
  apps also have an Empty screen, a bar and a line of text with nothing
  to scroll; its census (the driver takes it once it has looked for a
  list for ten seconds and found none) is what the app costs before any
  list, the part of every other screen's number that is the runtime's and
  not the list's.

### Why Android's slowest frames and late count are not compared

Both are real measurements, but between these frameworks they measure
different things:

- **The late count sees freezes and misses lag.** A frame that is not
  ready in time shows up in one of two ways, depending on how the app
  hands its frames to the screen:
  - **A freeze.** DartNative and Kotlin show each frame at the next
    refresh. When one is late, the screen keeps the previous picture for
    one more refresh.
  - **Lag.** React Native prepares its frames a refresh ahead, so its
    picture is always a refresh behind the finger. A slow frame uses up
    that head start instead of freezing the screen: nothing repeats, but
    the content lags behind the finger.

  Android's late count is built to count freezes only. For an app that
  works ahead, it allows a frame one more refresh before calling it late,
  because only then would the screen freeze. That rule is right, and it
  is not a bias against DartNative. But across these apps it counts every
  slow frame in DartNative and Kotlin, since each one freezes the screen,
  and in React Native only the frames too slow even for its head start;
  the lag the others cause is never recorded. The typical frame time is
  counted from the refresh a frame was meant for, so it does include
  React Native's lag: it is the number compared.
- **On this phone the slowest frames follow the processor cores.** The
  system moves a thread with little to do onto the Snapdragon 778G's four
  small, slow cores. DartNative and Kotlin finish a typical frame early,
  so their threads ran on the small cores about half the time; React
  Native's JavaScript thread, busy through the whole scroll, kept the big
  cores awake for all of its threads. DartNative's slowest frames, traced,
  were the ones its threads ran on the small cores, where the same work
  takes about three times as long. The platform's own list, in the Kotlin
  app, often has the slowest 99th percentile and the most late frames of
  all.

### The iPhone's typical frame time

As on Android, the iPhone results compare the typical frame time: the
median of every frame the app prepared inside the flings, as the Hitches
instrument times the app's work on each one. It is the measure of
smoothness, and the same one on both phones.

- **It is the app's part of the frame.** iOS draws the frame in a system
  process outside the app, so the iPhone's numbers are compared with each
  other, not with Android's.
- **It is small**, about half a millisecond on Cards, because most frames
  of a fling only move the list. The Time Profiler agrees: 5.6 s of
  main-thread work in 63 s of flings for the Swift app, against 6.0 s of
  frame readings.
- **It doesn't include work done on other threads**, in any app. React
  Native does the most there, running its JavaScript: on the iPhone, up
  to 10 times DartNative's and 13 times the Swift app's, as the Time
  Profiler measures it; on the Android phone, outside the main thread
  and the thread that draws, up to 14 times DartNative's and 17 times
  the Kotlin app's, from each thread's processor time in one scroll of
  each app (`harness/android/threads.sh`).

The detailed tables also show the hitches, Apple's count of frames that
reached the screen late. They show where the work landed, not how much
there was ("Why a native list can show more hitches than React Native",
below).

## How the list is scrolled

The same way for every app:

- **Android:** Legend List's own `example/autoscroll.sh`, unchanged (a
  loop of `adb shell input swipe` gestures), for 20 seconds per launch,
  after a 5-second settle from a cold start, three launches of each app.
  Each batch starts with one warm-up launch that is not recorded, so the
  images are in each app's disk cache; every measured launch then starts
  from a stopped app. The Cards screen is also scrolled back **up** for
  another 20 seconds in the same launch
  (`DIRECTION=both`), with the same gesture reversed
  (`harness/android/autoscroll_up.sh`, their script with the two points
  swapped): scrolling up through rows a list has only estimated is where
  its estimates show (issue 511 is a crash on a fast scroll up on Android,
  408 a scroll glitch there).
- **Pressing the apps' own buttons:** the Scroll button is pressed
  through the accessibility tree, by its name, in every app alike.
- **iOS:** the app flings its own list. Each app is built with the same
  small driver (`harness/ios/autoscroll/BenchAutoScroll.m`, a pod in the
  DartNative and React Native apps, a source in the Swift one), idle
  unless the app is launched with `BENCH_AUTOSCROLL` in its environment,
  as `trace.sh` launches it. Eight seconds after launch it finds the
  screen's list (the largest scroll view with content taller than
  itself) and makes 25 flings, one every 2.5 seconds: 0.1 s of travel at
  4,000 points a second, the finger, then UIKit's own deceleration from
  that speed (the velocity decaying by `UIScrollView.DecelerationRate
  .normal` a millisecond), the content moving by the same curve in every
  app, from wherever it is when the next fling starts. The driver moves
  the content by each frame's share of that travel, as a finger does,
  never to an offset counted from the fling's start: a list that shifts
  its own offset while it scrolls, to hold the viewport still as a row it
  built takes its measured height in place of an estimate, keeps that
  shift, where an offset set from the start would add the whole travel
  to it again. The driver writes how far the flings went, in points and
  in rows, next to their times (`Documents/bench_flings.txt`). The list's
  delegate hears what UIKit tells it for a finger (will begin dragging,
  will end dragging with the velocity, did end dragging, will begin and
  did end decelerating), so a list that waits for those events behaves as
  under a finger; the display link that moves the content asks for 120 Hz
  while the content is fast and 60 Hz once it is slow, as UIKit's own
  scrolling does on this panel. Each fling is an `os_signpost` interval
  the trace is read inside of.

  The flings come from inside the app because a UI test's swipes do not
  come alone. Before and after each gesture XCTest reads the whole
  accessibility tree of the app in front, and UIKit answers that for a
  `UITableView` by creating a cell for every row: in the Swift app, a
  thousand cards the user never scrolled to, kept in the table's reuse
  pool, 370 MB of memory and every cell already built before the swipes
  it is meant to be built during. The DartNative app and Legend List
  build no cards for it, so a UI test would measure the Swift app alone
  warmed up and heavy. An app that flings itself has no observer in it.

## Scrolling to a far item

Every list offers a way to bring an item to the top: `scrollToIndex` in
Legend List, FlashList and FlatList, `scrollToItem` on a `FastList`'s
controller, a smooth scroller on a `RecyclerView`, `scrollToRow` on a
`UITableView`. It is easy when the list knows the height of every row
between where it is and where it goes; it is hard when it does not,
because the target's place is a guess until those rows are measured, and a
list that keeps its guess lands short or long, or corrects its aim on the
way and makes the content jump. Legend List's issue tracker has several of
these (529: scroll targets drifting as rows above measure in). An animated
scroll is the harder form: the list passes every item on the way and has
to build each one as it goes by, fast, or show the row empty.

The scroll-to test (`harness/android/scroll_to.py`,
`harness/ios/scroll_to.sh`) makes it as hard as it gets, on both phones
and on two screens: the Cards screen, where card heights vary most, and
the Chat screen. Each app's bar has one button, Scroll, which goes to the
next target of a sequence that is the same in every app, animated
(`scrollToIndex` with animation, `scrollToItem` on a `FastList`'s
controller, a smooth scroller on a `RecyclerView`, `scrollToRow` animated
on a `UITableView`), each target asked to rest with its top at the top of
the list. Every scroll goes away from where the list opens, into items it
has never measured: two scrolls are short and three are long.

Every item between where a scroll starts and where it lands is passed. On
the Chat screen a photo and a sticker are items too, which is why the item
counts are higher than the message counts.

**Chat** (opens at message 999, the newest, and scrolls up the history):

| Scroll | Messages passed | Items passed |
| --- | ---: | ---: |
| 1. to message 996 | 3 | 5 |
| 2. to message 600 | 396 | 627 |
| 3. to message 598 | 2 | 3 |
| 4. to message 300 | 298 | 472 |
| 5. to message 0 | 300 | 475 |

**Cards** (opens at card 0 and scrolls down the list; every item is a card):

| Scroll | Items passed |
| --- | ---: |
| 1. to card 1 | 1 |
| 2. to card 400 | 399 |
| 3. to card 402 | 2 |
| 4. to card 700 | 298 |
| 5. to card 950 | 250 |

So each screen has two short scrolls, 1 to 5 items, and three long ones,
250 to 627 items.

The first scroll lands among items every list has measured, so it shows
where a target's top sits when the target is at the top. The short one in
the middle, a few items on from a landing, is the everyday case. The long
ones are the hard case: the target's place is a guess until the items on
the way are measured, as when a chat goes to a quoted message or a search
result far back. After each scroll the target's top should sit where the
first one's did; the difference is how far the list landed from where it
was asked to, in pixels on Android and points on the iPhone. A target not
on screen at all is a miss.

What the list shows on the way is the other half of the test, and it is
not a number: a screen recording of each app's Scroll button
(the videos in `RESULTS.md`), taken by hand on the same phone, shows whether
the rows passed are drawn or left blank while the list moves. The
results report it as "blank rows in a long scroll", none or yes with how
much, with the recordings as the evidence.

On Android the finger then drags back towards where the list opened,
through items the list may not have drawn, in slow drags that end with the
finger held still, so no list flings: every text inside the list should
move by the length of the drag, the same as a drag among measured items. A
drag that moves the content by more or less is content that jumped. The
test reads every position from the accessibility tree, which every app
fills with its own text views, and waits for the screen to settle after
each step.

A card is found by its title, "Item #400"; a card that stops so low that
its title is below the screen is placed from its author line ("Alex
Thompson 400"), the line above the title, as far above it as on the first
card. A message is found by its time, which no other message has (the
thread's clock runs past 24 hours), and its top is read from its sender's
name, the first line of its bubble. On the iPhone the positions come from
the accessibility tree XCTest reads, in points.

The test also notes how long each landing took to come to rest. Most of
that time is the test itself reading the screen, which takes longer the
more elements an app's accessibility tree holds, so the times compare an
app's far landings with its own short ones, never one app with another.

## Why two screens

The Cards screen is Legend List's own showcase, where it does well; the
Chat screen, from the same example app so nothing is written against it,
is one its issue tracker names as hard. Both get the same treatment: the
example's screen, a DartNative port, the native twins, the same
scrolling and the same meters.

## Builds and devices

Release builds everywhere: `dn run --release`, `./gradlew assembleRelease`,
`expo run:ios --configuration Release`, `xcodebuild -configuration
Release`. Every iPhone app was built with the same Xcode, 26.3, and its
iOS 26.2 SDK. On Android every app ran compiled with its own profile, the
mode a store install leaves it in (`speed-profile` in `adb shell dumpsys
package dexopt`): React Native's and AndroidX's libraries ship theirs,
and DartNative's Android binding ships one too. A build installed with
`adb install` gets there after its first launch (each batch's warm-up run
is one). The React Native and Kotlin builds were in that mode when checked
after their runs; the DartNative builds were launched once after install,
then compiled with `adb shell cmd package compile -m speed-profile -f
<package>` before theirs. The phones are an iPhone 16 Pro (ProMotion, 120 Hz) and the
Android phone named in `RESULTS.md`. An Android emulator's numbers are
not reported: its GPU is a translation of the host's, and its frames
slow down with anything else the host is doing.

## Things that could mislead, and how the benchmark handles them

- **How each app is written.** Every contender is written the way a good
  developer writes it on that stack: not tuned to the benchmark, not
  careless. The React Native app is Legend List's own example, by the
  library's authors, with recycling and their draw distance. The
  DartNative app is a `FastList` with the same window in points and
  recycling, nothing else, on the same framework every DartNative app
  uses: it has no setting or code path for this benchmark. The UIKit and
  Android apps prepare their rows ahead of the scroll the way the platforms provide for it (prefetching,
  heights measured ahead, cells laid out by frames) and draw their text
  the way the platforms draw it, in the frame the row appears. The code
  is in the repository to be read and argued with.
- **Why a native list can show more hitches than React Native.** A
  native list builds a row inside the frame the row appears in, text
  layout and rasterisation included, so a tall card can cost one late
  frame; React Native builds the row on another thread and shows the
  cell empty until the row arrives, so it drops fewer frames and shows
  blank space instead. Both are real costs the user sees, which is why
  the results carry both numbers side by side, on both phones. One
  without the other misleads either way.
- **Recycling and the window.** Legend List's example sets `recycleItems`,
  so a card's views are reused as it scrolls out, and keeps items built
  within its draw distance of the screen, 250 points. DartNative's
  `FastList` keeps built rows by default; the DartNative app sets the same
  window in points (`cacheExtent: 250`) and `recycleItems` to reuse the
  rows the window lets go. The window is in points and not in rows so
  that every app holds the same amount of content whatever a row holds.
- **The display's refresh rate on iPhone.** A ProMotion panel runs at the
  rate the running animations and display links ask for. A `UITableView`
  on its own gets the full 120 Hz while a fling is fast and falls to 60 Hz
  as it slows; the React Native example stays at 120 Hz because
  Reanimated's `requestAnimationFrame` display link fires through the
  scroll with a 120 Hz request. A lower frame rate with zero hitches is
  therefore the panel's choice, not dropped frames. DartNative asks
  for the full rate while one of its lists is moving, as Flutter's engine
  and Reanimated do; the UIKit app is left as UIKit behaves.
- **Text height on Android.** The three apps' cards are within a few dp
  of each other (a DartNative card is about 1.5 dp shorter than a Kotlin
  one and 3.5 dp shorter than a React Native one, from how each spells a
  20 sp line height), so a swipe scrolls the same content to within 1 %.
- **No UI test around the flings.** A UI test's accessibility snapshots
  between swipes make a `UITableView` create a cell for every row, which
  would warm the Swift app's cells before the measured swipes and put a
  thousand of them in its memory; the apps fling themselves instead ("How
  the list is scrolled").
- **Nothing from the frameworks' own counters.** No framework's own FPS
  monitor, profiler flag or performance overlay was used; every number
  comes from the operating system.
